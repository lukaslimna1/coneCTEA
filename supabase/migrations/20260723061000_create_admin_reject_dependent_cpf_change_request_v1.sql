-- =========================================================================
-- ConeCTEA — Ações Administrativas para Recusa de CPF de Dependente (H7-B-R3)
--
-- MIGRATION: 20260723061000_create_admin_reject_dependent_cpf_change_request_v1.sql
-- OBJETIVO:
--   - Criar as RPCs transacionais de Prepare, Commit e Rollback para a recusa
--     administrativa de solicitações de alteração de CPF de dependente.
--   - Aplicar validações estritas e NULL-safe em todas as comparações PL/pgSQL.
--   - Validar coerência de p_document_action contra o estado real de review_data antes de qualquer mutation.
--   - Executar todas as validações prévias ANTES de iniciar qualquer operação de UPDATE.
--   - Garantir atomicidade com RAISE EXCEPTION em caso de falha de ROW_COUNT pós-mutation.
--   - Garantir liberação de reserva HMAC e descarte documental transacional via GAS/Drive e LGPD.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. RPC: Prepare Recusa Administrativa (Fase 1)
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_admin_prepare_dependent_cpf_rejection_v1(
  p_request_id uuid,
  p_admin_user_id uuid,
  p_admin_feedback text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private', 'pg_temp'
AS $function$
DECLARE
  v_role text;
  v_request record;
  v_review record;
  v_now timestamptz;
  v_document_action text;
  v_file_id text := NULL;
  v_feedback_clean text;
BEGIN
  -- 1. Validação de parâmetros
  IF p_request_id IS NULL OR p_admin_user_id IS NULL OR p_admin_feedback IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_parameters'
    );
  END IF;

  v_feedback_clean := trim(p_admin_feedback);
  IF length(v_feedback_clean) < 1 OR length(v_feedback_clean) > 500 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_parameters'
    );
  END IF;

  -- 2. Validar privilégios admin (admin_master/admin_dev) de forma NULL-safe
  SELECT role INTO v_role
  FROM public.profiles
  WHERE id = p_admin_user_id;

  IF v_role IS NULL OR v_role NOT IN ('admin_master', 'admin_dev') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'forbidden'
    );
  END IF;

  -- 3. Buscar e travar solicitação pública
  SELECT id, status, expires_at
  INTO v_request
  FROM public.dependent_cpf_change_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'not_found'
    );
  END IF;

  -- Tratamento de idempotência se já estiver em status final rejected_by_admin
  IF v_request.status = 'rejected_by_admin' THEN
    RETURN jsonb_build_object(
      'success', true,
      'request_id', p_request_id,
      'status', 'rejected_by_admin',
      'document_action', 'already_rejected'
    );
  END IF;

  -- Validar status permitido para recusa de forma NULL-safe (apenas solicitações em análise)
  IF v_request.status IS DISTINCT FROM 'under_review' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status'
    );
  END IF;

  v_now := transaction_timestamp();

  -- Validar expiração do prazo (se vencida, bloqueia a recusa administrativa e delega para expiração H5)
  IF v_request.expires_at IS NOT NULL AND v_now >= v_request.expires_at THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'expired'
    );
  END IF;

  -- 4. Buscar e travar dados de revisão privados
  SELECT request_id, document_file_id, document_state, cleared_at
  INTO v_review
  FROM private.dependent_cpf_change_review_data
  WHERE request_id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'missing_review_data'
    );
  END IF;

  -- 5. Avaliar necessidade de descarte no Drive
  IF v_review.document_state = 'available'
     AND v_review.document_file_id IS NOT NULL
     AND btrim(v_review.document_file_id) <> ''
     AND v_review.cleared_at IS NULL THEN

    v_document_action := 'discard_required';
    v_file_id := v_review.document_file_id;

  ELSIF v_review.document_state = 'discarded'
        AND (v_review.document_file_id IS NULL OR btrim(v_review.document_file_id) = '') THEN

    v_document_action := 'no_document';
    v_file_id := NULL;

  ELSE

    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_document_state'
    );

  END IF;

  -- 6. Aplicar trava transacional 'applying'
  UPDATE public.dependent_cpf_change_requests
  SET
    status = 'applying',
    updated_at = v_now
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'previous_status', v_request.status,
    'status', 'applying',
    'document_action', v_document_action,
    'document_file_id', v_file_id
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error_code', 'internal_error'
  );
END;
$function$;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. RPC: Commit Recusa Administrativa (Fase 2)
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_admin_commit_dependent_cpf_rejection_v1(
  p_request_id uuid,
  p_previous_status text,
  p_admin_feedback text,
  p_document_action text DEFAULT 'discarded'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private', 'pg_temp'
AS $function$
DECLARE
  v_request record;
  v_review record;
  v_reservation record;
  v_now timestamptz;
  v_feedback_clean text;
  v_rows_updated integer;
BEGIN
  -- A. Validação de parâmetros de entrada
  IF p_request_id IS NULL OR p_admin_feedback IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_parameters'
    );
  END IF;

  IF p_document_action IS NULL OR p_document_action NOT IN ('discarded', 'no_document') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_parameters'
    );
  END IF;

  v_feedback_clean := trim(p_admin_feedback);
  IF length(v_feedback_clean) < 1 OR length(v_feedback_clean) > 500 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_parameters'
    );
  END IF;

  IF p_previous_status IS NULL OR p_previous_status IS DISTINCT FROM 'under_review' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_parameters'
    );
  END IF;

  -- B. Buscar e travar solicitação pública
  SELECT id, status
  INTO v_request
  FROM public.dependent_cpf_change_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'not_found'
    );
  END IF;

  -- Idempotência se já estiver em status final rejected_by_admin
  IF v_request.status = 'rejected_by_admin' THEN
    RETURN jsonb_build_object(
      'success', true,
      'request_id', p_request_id,
      'status', 'rejected_by_admin'
    );
  END IF;

  -- Validar se a solicitação está na trava transacional ('applying')
  IF v_request.status IS DISTINCT FROM 'applying' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status'
    );
  END IF;

  -- C. Buscar e travar dados de revisão privados completos para validação de coerência
  SELECT request_id, document_file_id, document_state, cleared_at
  INTO v_review
  FROM private.dependent_cpf_change_review_data
  WHERE request_id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'missing_review_data'
    );
  END IF;

  -- D. Validar coerência de p_document_action contra o estado documental de review_data antes de qualquer mutation
  IF p_document_action = 'discarded' THEN
    IF v_review.document_state IS DISTINCT FROM 'available'
       OR v_review.document_file_id IS NULL
       OR btrim(v_review.document_file_id) = ''
       OR v_review.cleared_at IS NOT NULL THEN

      RETURN jsonb_build_object(
        'success', false,
        'error_code', 'invalid_document_action'
      );
    END IF;
  ELSIF p_document_action = 'no_document' THEN
    IF v_review.document_state IS DISTINCT FROM 'discarded'
       OR (v_review.document_file_id IS NOT NULL AND btrim(v_review.document_file_id) <> '') THEN

      RETURN jsonb_build_object(
        'success', false,
        'error_code', 'invalid_document_action'
      );
    END IF;
  END IF;

  -- E. Buscar e travar reserva de CPF por HMAC
  SELECT id, reservation_state, released_at
  INTO v_reservation
  FROM private.dependent_cpf_change_reservations
  WHERE request_id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'missing_reservation'
    );
  END IF;

  IF v_reservation.reservation_state IS DISTINCT FROM 'attached' OR v_reservation.released_at IS NOT NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'reservation_unavailable'
    );
  END IF;

  -- F. TODAS AS VALIDAÇÕES CONCLUÍDAS. Executar mutations de forma atômica com checagem de ROW_COUNT via RAISE EXCEPTION
  v_now := transaction_timestamp();

  -- 1. Liberar reserva HMAC vinculada
  UPDATE private.dependent_cpf_change_reservations
  SET
    reservation_state = 'released',
    released_at = v_now,
    updated_at = v_now
  WHERE request_id = p_request_id
    AND reservation_state = 'attached';

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated <> 1 THEN
    RAISE EXCEPTION 'dependent_cpf_rejection_reservation_update_failed';
  END IF;

  -- 2. Atualizar revisão privada zerando PII e definindo clear_reason = 'request_rejected'
  UPDATE private.dependent_cpf_change_review_data
  SET
    document_file_id = NULL,
    document_state = 'discarded',
    cleared_at = v_now,
    clear_reason = 'request_rejected',
    old_cpf_clear = NULL,
    new_cpf_clear = NULL,
    updated_at = v_now
  WHERE request_id = p_request_id;

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated <> 1 THEN
    RAISE EXCEPTION 'dependent_cpf_rejection_review_update_failed';
  END IF;

  -- 3. Atualizar solicitação pública para status final 'rejected_by_admin'
  UPDATE public.dependent_cpf_change_requests
  SET
    status = 'rejected_by_admin',
    admin_feedback = v_feedback_clean,
    updated_at = v_now
  WHERE id = p_request_id
    AND status = 'applying';

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated <> 1 THEN
    RAISE EXCEPTION 'dependent_cpf_rejection_request_update_failed';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'status', 'rejected_by_admin'
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error_code', 'internal_error'
  );
END;
$function$;

-- ─────────────────────────────────────────────────────────────────────────
-- 3. RPC: Rollback Recusa Administrativa (Fase 3 - Em Caso de Falha de Descarte)
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_admin_rollback_dependent_cpf_rejection_v1(
  p_request_id uuid,
  p_previous_status text,
  p_error_code text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private', 'pg_temp'
AS $function$
DECLARE
  v_request record;
  v_now timestamptz;
BEGIN
  IF p_request_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  -- Validar p_previous_status de forma NULL-safe
  IF p_previous_status IS NULL OR p_previous_status IS DISTINCT FROM 'under_review' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_parameters'
    );
  END IF;

  -- Buscar e travar solicitação pública
  SELECT id, status
  INTO v_request
  FROM public.dependent_cpf_change_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'not_found'
    );
  END IF;

  -- Reverter para p_previous_status (coluna text) somente se estiver na trava transitória 'applying'
  IF v_request.status IS NOT DISTINCT FROM 'applying' THEN
    v_now := transaction_timestamp();

    UPDATE public.dependent_cpf_change_requests
    SET
      status = p_previous_status,
      updated_at = v_now
    WHERE id = p_request_id;

    RETURN jsonb_build_object(
      'success', true,
      'request_id', p_request_id,
      'status', p_previous_status
    );
  ELSE
    RETURN jsonb_build_object(
      'success', true,
      'request_id', p_request_id,
      'status', v_request.status
    );
  END IF;

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error_code', 'internal_error'
  );
END;
$function$;

-- ─────────────────────────────────────────────────────────────────────────
-- 4. Permissões e Privilégios de Segurança
-- ─────────────────────────────────────────────────────────────────────────
REVOKE ALL ON FUNCTION public.conectea_admin_prepare_dependent_cpf_rejection_v1(uuid, uuid, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_prepare_dependent_cpf_rejection_v1(uuid, uuid, text) TO service_role;

REVOKE ALL ON FUNCTION public.conectea_admin_commit_dependent_cpf_rejection_v1(uuid, text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_commit_dependent_cpf_rejection_v1(uuid, text, text, text) TO service_role;

REVOKE ALL ON FUNCTION public.conectea_admin_rollback_dependent_cpf_rejection_v1(uuid, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_rollback_dependent_cpf_rejection_v1(uuid, text, text) TO service_role;

-- Comentários descritivos e contrato para a futura Edge Function H7-C
COMMENT ON FUNCTION public.conectea_admin_prepare_dependent_cpf_rejection_v1(uuid, uuid, text) IS
  'Fase 1 da transação de recusa administrativa de CPF de dependente. Valida prazos de forma NULL-safe, trava a solicitação em applying e verifica necessidade de descarte no Drive (retornando discard_required, no_document ou already_rejected).';

COMMENT ON FUNCTION public.conectea_admin_commit_dependent_cpf_rejection_v1(uuid, text, text, text) IS
  'Fase 2 da transação de recusa administrativa. Valida estado documental e trava reserva HMAC de forma atômica antes das mutations, aceita apenas p_document_action em (discarded, no_document), finaliza status em rejected_by_admin e limpa dados sensíveis com clear_reason = request_rejected.';

COMMENT ON FUNCTION public.conectea_admin_rollback_dependent_cpf_rejection_v1(uuid, text, text) IS
  'Fase 3 da transação de recusa administrativa (Rollback em caso de falha no descarte GAS/Drive). Reverte o status da solicitação de applying para o status anterior sem alterar reservas ou review_data.';
