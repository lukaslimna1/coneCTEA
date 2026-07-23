-- =========================================================================
-- ConeCTEA — RPCs SQL de Expiração Segura de CPF de Dependente
--
-- MIGRATION: 20260723024000_create_dependent_cpf_expiration_rpcs_v1.sql
-- OBJETIVO:
--   1. Criar public.conectea_system_list_due_dependent_cpf_expiration_v1()
--      para consultar solicitações vencidas por prazo sem expor PII ou metadados desnecessários.
--   2. Criar public.conectea_system_prepare_dependent_cpf_expiration_v1()
--      para validar regras, aplicar trava e extrair document_file_id com validação rígida de coerência documental.
--   3. Criar public.conectea_system_commit_dependent_cpf_expiration_v1()
--      para consolidar expiração, expurgar PII limpo/arquivo e liberar reserva HMAC.
--   4. Criar public.conectea_system_rollback_dependent_cpf_expiration_v1()
--      para reverter trava de 'applying' caso o descarte seguro falhe.
--   5. Restringir execução exclusivamente para service_role.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. RPC: Listar Solicitações Vencidas Candidatas à Expiração
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_system_list_due_dependent_cpf_expiration_v1(
  p_limit integer DEFAULT 20
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private', 'pg_temp'
AS $function$
DECLARE
  v_limit integer;
  v_items_json jsonb;
BEGIN
  v_limit := COALESCE(p_limit, 20);
  IF v_limit < 1 THEN
    v_limit := 20;
  ELSIF v_limit > 100 THEN
    v_limit := 100;
  END IF;

  SELECT COALESCE(jsonb_agg(t), '[]'::jsonb) INTO v_items_json
  FROM (
    SELECT
      cr.id AS request_id,
      cr.status,
      EXISTS (
        SELECT 1 
        FROM private.dependent_cpf_change_review_data rd 
        WHERE rd.request_id = cr.id
          AND rd.document_state = 'available'
          AND rd.document_file_id IS NOT NULL
          AND btrim(rd.document_file_id) <> ''
          AND rd.cleared_at IS NULL
      ) AS has_document
    FROM public.dependent_cpf_change_requests cr
    WHERE cr.status IN ('under_review', 'waiting_cpf_correction', 'waiting_document_replacement')
      AND cr.expires_at IS NOT NULL
      AND now() >= cr.expires_at
    ORDER BY cr.expires_at ASC, cr.id ASC
    LIMIT v_limit
  ) t;

  RETURN jsonb_build_object(
    'items', v_items_json,
    'count', jsonb_array_length(v_items_json),
    'server_now', now()
  );
END;
$function$;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. RPC: Prepare Expiração (Fase 1)
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_system_prepare_dependent_cpf_expiration_v1(
  p_request_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private', 'pg_temp'
AS $function$
DECLARE
  v_request record;
  v_review record;
  v_now timestamptz;
  v_document_action text;
  v_file_id text := NULL;
BEGIN
  IF p_request_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  -- A. Buscar e travar solicitação pública
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

  -- B. Tratamento de idempotência se já estiver expirada
  IF v_request.status = 'expired' THEN
    RETURN jsonb_build_object(
      'success', true,
      'request_id', p_request_id,
      'status', 'expired',
      'document_action', 'already_expired'
    );
  END IF;

  -- C. Validar status permitido
  IF v_request.status NOT IN ('under_review', 'waiting_cpf_correction', 'waiting_document_replacement') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status'
    );
  END IF;

  v_now := now();

  -- D. Validar expiração por tempo via now()
  IF v_request.expires_at IS NULL OR v_now < v_request.expires_at THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'not_expired'
    );
  END IF;

  -- E. Buscar e travar dados de revisão privados
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

  -- F. Avaliar necessidade de descarte no Drive com validação rígida de coerência documental
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

  -- G. Aplicar trava transacional 'applying'
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
-- 3. RPC: Commit Expiração (Fase 2 - Pós Descarte ou sem Documento)
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_system_commit_dependent_cpf_expiration_v1(
  p_request_id uuid,
  p_previous_status text,
  p_document_action text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private', 'pg_temp'
AS $function$
DECLARE
  v_request record;
  v_review record;
  v_now timestamptz;
BEGIN
  IF p_request_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  IF p_previous_status NOT IN ('under_review', 'waiting_cpf_correction', 'waiting_document_replacement')
     OR p_document_action NOT IN ('discard_required', 'no_document') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_parameters'
    );
  END IF;

  -- A. Buscar e travar solicitação pública
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

  -- B. Tratamento de idempotência se já estiver em status final expired
  IF v_request.status = 'expired' THEN
    RETURN jsonb_build_object(
      'success', true,
      'request_id', p_request_id,
      'status', 'expired'
    );
  END IF;

  -- C. Validar se a solicitação está na trava de aplicação ('applying')
  IF v_request.status <> 'applying' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status'
    );
  END IF;

  v_now := now();

  -- D. Buscar e travar dados de revisão privados
  SELECT request_id
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

  -- E. Atualizar revisão privada em total conformidade com a constraint chk_dep_cpf_review_coherence
  UPDATE private.dependent_cpf_change_review_data
  SET
    document_file_id = NULL,
    document_state = 'discarded',
    cleared_at = v_now,
    clear_reason = 'request_expired',
    old_cpf_clear = NULL,
    new_cpf_clear = NULL,
    updated_at = v_now
  WHERE request_id = p_request_id;

  -- F. Liberar reserva HMAC se vinculada e ativa (definindo reservation_state = 'released' e released_at = v_now)
  UPDATE private.dependent_cpf_change_reservations
  SET
    reservation_state = 'released',
    released_at = v_now,
    updated_at = v_now
  WHERE request_id = p_request_id
    AND reservation_state = 'attached';

  -- G. Atualizar solicitação pública para status final 'expired'
  UPDATE public.dependent_cpf_change_requests
  SET
    status = 'expired',
    updated_at = v_now
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'status', 'expired'
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error_code', 'internal_error'
  );
END;
$function$;

-- ─────────────────────────────────────────────────────────────────────────
-- 4. RPC: Rollback Expiração (Em Caso de Falha de Descarte no GAS)
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_system_rollback_dependent_cpf_expiration_v1(
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

  IF p_previous_status NOT IN ('under_review', 'waiting_cpf_correction', 'waiting_document_replacement') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_parameters'
    );
  END IF;

  -- A. Buscar e travar solicitação pública
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

  -- B. Validar se a solicitação está em 'applying'
  IF v_request.status <> 'applying' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status'
    );
  END IF;

  v_now := now();

  -- C. Reverter status público para o estado prévio sem alterar dados sensíveis
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

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error_code', 'internal_error'
  );
END;
$function$;

-- ─────────────────────────────────────────────────────────────────────────
-- 5. Privilégios Mínimos e Grants de Segurança (Execução Exclusiva service_role)
-- ─────────────────────────────────────────────────────────────────────────
REVOKE ALL ON FUNCTION public.conectea_system_list_due_dependent_cpf_expiration_v1(integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_system_list_due_dependent_cpf_expiration_v1(integer) TO service_role;

REVOKE ALL ON FUNCTION public.conectea_system_prepare_dependent_cpf_expiration_v1(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_system_prepare_dependent_cpf_expiration_v1(uuid) TO service_role;

REVOKE ALL ON FUNCTION public.conectea_system_commit_dependent_cpf_expiration_v1(uuid, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_system_commit_dependent_cpf_expiration_v1(uuid, text, text) TO service_role;

REVOKE ALL ON FUNCTION public.conectea_system_rollback_dependent_cpf_expiration_v1(uuid, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_system_rollback_dependent_cpf_expiration_v1(uuid, text, text) TO service_role;

-- ─────────────────────────────────────────────────────────────────────────
-- 6. Comentários Descritivos nas Funções
-- ─────────────────────────────────────────────────────────────────────────
COMMENT ON FUNCTION public.conectea_system_list_due_dependent_cpf_expiration_v1(integer) IS
  'Lista solicitações de CPF de dependente com expires_at vencido para expiração automatizada backend.';

COMMENT ON FUNCTION public.conectea_system_prepare_dependent_cpf_expiration_v1(uuid) IS
  'Etapa 1/3 de expiração: aplica trava applying e extrai document_file_id se houver descarte pendente.';

COMMENT ON FUNCTION public.conectea_system_commit_dependent_cpf_expiration_v1(uuid, text, text) IS
  'Etapa 2/3 de expiração: consolida status expired, expurga PII/fileId e libera reserva HMAC.';

COMMENT ON FUNCTION public.conectea_system_rollback_dependent_cpf_expiration_v1(uuid, text, text) IS
  'Desfazimento de trava applying revertendo para status prévio caso descarte no Drive falhe.';
