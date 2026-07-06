-- =========================================================================
-- ConeCTEA — Ações Administrativas para Revisão de CPF de Dependente
--
-- MIGRATION: 20260706222500_create_admin_dependent_cpf_review_actions_v1.sql
-- OBJETIVO:
--   - Criar a RPC administrativa direta para solicitar correção do CPF.
--   - Criar as RPCs de prepare, commit e rollback para a Edge Function de substituição de documento (descarte imediato).
--   - Garantir segurança definer, grants restritos e conformidade com LGPD.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. RPC: Revisar CPF (Request Dependent CPF Correction)
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_admin_request_dependent_cpf_correction_v1(p_request_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_temp'
AS $function$
DECLARE
  v_uid uuid;
  v_role text;
  v_request record;
  v_now timestamptz;
  v_holder_deadline_exclusive_at timestamptz;
  v_exists boolean;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'unauthenticated'
    );
  END IF;

  -- 1. Validar privilégios admin
  SELECT role INTO v_role
  FROM public.profiles
  WHERE id = v_uid;

  IF v_role NOT IN ('admin_master', 'admin_dev') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'forbidden'
    );
  END IF;

  IF p_request_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  -- 2. Buscar e travar a solicitação
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

  v_now := now();

  -- 3. Validar se está expirada
  IF v_request.expires_at IS NOT NULL AND v_now >= v_request.expires_at THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'expired'
    );
  END IF;

  -- 4. Validar status
  IF v_request.status <> 'under_review' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status'
    );
  END IF;

  -- 5. Validar existência de dados de revisão
  SELECT EXISTS (
    SELECT 1 
    FROM private.dependent_cpf_change_review_data 
    WHERE request_id = p_request_id
  ) INTO v_exists;

  IF NOT v_exists THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  -- 6. Calcular novo prazo limite de resposta do titular
  v_holder_deadline_exclusive_at := public.conectea_account_change_holder_deadline_v1(v_now);

  -- 7. Atualizar a solicitação pública de dependente
  UPDATE public.dependent_cpf_change_requests
  SET 
    status = 'waiting_cpf_correction',
    admin_feedback = 'CPF informado precisa ser corrigido para continuar a análise da alteração.',
    expires_at = v_holder_deadline_exclusive_at,
    updated_at = v_now
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'status', 'waiting_cpf_correction'
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error_code', 'internal_error'
  );
END;
$function$;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. RPC: Reenviar Documento - Prepare (Prepare Dependent Document Replacement)
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_admin_prepare_dependent_cpf_document_replacement_v1(
  p_request_id uuid,
  p_admin_user_id uuid
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
BEGIN
  -- 1. Validar privilégios admin
  IF p_admin_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'unauthenticated'
    );
  END IF;

  SELECT role INTO v_role
  FROM public.profiles
  WHERE id = p_admin_user_id;

  IF v_role NOT IN ('admin_master', 'admin_dev') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'forbidden'
    );
  END IF;

  IF p_request_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  -- 2. Buscar e travar a solicitação pública (trava de linha)
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

  v_now := now();

  -- 3. Validar se está expirada
  IF v_request.expires_at IS NOT NULL AND v_now >= v_request.expires_at THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'expired'
    );
  END IF;

  -- 4. Validar status
  IF v_request.status <> 'under_review' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status'
    );
  END IF;

  -- 5. Buscar e travar dados de revisão privados
  SELECT request_id, document_file_id, document_state
  INTO v_review
  FROM private.dependent_cpf_change_review_data
  WHERE request_id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  -- 6. Validar estado do documento e presença do fileId
  IF v_review.document_state <> 'available' OR v_review.document_file_id IS NULL OR v_review.document_file_id = '' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'missing_document'
    );
  END IF;

  -- 7. Criar trava operacional mudando o status para 'applying'
  UPDATE public.dependent_cpf_change_requests
  SET 
    status = 'applying',
    updated_at = v_now
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'status', 'applying',
    'document_file_id', v_review.document_file_id
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error_code', 'internal_error'
  );
END;
$function$;

-- ─────────────────────────────────────────────────────────────────────────
-- 3. RPC: Reenviar Documento - Rollback (Rollback Dependent Document Replacement)
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_admin_rollback_dependent_cpf_document_replacement_v1(
  p_request_id uuid,
  p_admin_user_id uuid,
  p_error_code text DEFAULT NULL
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_temp'
AS $function$
DECLARE
  v_role text;
  v_request record;
  v_now timestamptz;
BEGIN
  -- 1. Validar privilégios admin
  IF p_admin_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'unauthenticated'
    );
  END IF;

  SELECT role INTO v_role
  FROM public.profiles
  WHERE id = p_admin_user_id;

  IF v_role NOT IN ('admin_master', 'admin_dev') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'forbidden'
    );
  END IF;

  IF p_request_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  -- 2. Buscar e travar a solicitação pública
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

  -- 3. Validar se está na trava operacional ('applying')
  IF v_request.status <> 'applying' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status'
    );
  END IF;

  v_now := now();

  -- 4. Reverter a trava operacional, voltando para 'under_review'
  UPDATE public.dependent_cpf_change_requests
  SET 
    status = 'under_review',
    updated_at = v_now
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'status', 'under_review'
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error_code', 'internal_error'
  );
END;
$function$;

-- ─────────────────────────────────────────────────────────────────────────
-- 4. RPC: Reenviar Documento - Commit (Commit Dependent Document Replacement)
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_admin_commit_dependent_cpf_document_replacement_v1(
  p_request_id uuid,
  p_admin_user_id uuid,
  p_document_file_id text
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
  v_holder_deadline_exclusive_at timestamptz;
BEGIN
  -- 1. Validar privilégios admin
  IF p_admin_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'unauthenticated'
    );
  END IF;

  SELECT role INTO v_role
  FROM public.profiles
  WHERE id = p_admin_user_id;

  IF v_role NOT IN ('admin_master', 'admin_dev') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'forbidden'
    );
  END IF;

  IF p_request_id IS NULL OR p_document_file_id IS NULL OR p_document_file_id = '' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  -- 2. Buscar e travar a solicitação pública
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

  v_now := now();

  -- Tratamento de Idempotência: caso a solicitação já tenha sido transicionada para waiting_document_replacement
  IF v_request.status = 'waiting_document_replacement' THEN
    -- Buscar e travar dados de revisão privados para validação detalhada
    SELECT request_id, document_file_id, document_state, clear_reason
    INTO v_review
    FROM private.dependent_cpf_change_review_data
    WHERE request_id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RETURN jsonb_build_object(
        'success', false,
        'error_code', 'invalid_request'
      );
    END IF;

    -- Validar se o estado privado é condizente com um descarte concluído com sucesso
    IF v_review.document_file_id IS NULL
      AND v_review.document_state = 'discarded'
      AND v_review.clear_reason = 'document_replacement_requested' THEN
      RETURN jsonb_build_object(
        'success', true,
        'request_id', p_request_id,
        'status', 'waiting_document_replacement'
      );
    ELSE
      -- Estado privado incoerente para um descarte concluído
      RETURN jsonb_build_object(
        'success', false,
        'error_code', 'invalid_request'
      );
    END IF;
  END IF;

  -- 3. Validar status (deve estar em 'applying' para o fluxo normal)
  IF v_request.status <> 'applying' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status'
    );
  END IF;

  -- 4. Buscar e travar dados de revisão privados
  SELECT request_id, document_file_id, document_state
  INTO v_review
  FROM private.dependent_cpf_change_review_data
  WHERE request_id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  -- 5. Garantir correspondência do document_file_id para evitar corrida/descarte errado
  IF v_review.document_state <> 'available' OR v_review.document_file_id IS DISTINCT FROM p_document_file_id THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  -- 6. Calcular novo prazo limite de resposta do titular
  v_holder_deadline_exclusive_at := public.conectea_account_change_holder_deadline_v1(v_now);

  -- 7. Atualizar dados de revisão privados (limpando o arquivo e registrando o descarte feito pelo GAS/Edge)
  UPDATE private.dependent_cpf_change_review_data
  SET
    document_file_id = NULL,
    document_state = 'discarded',
    cleared_at = v_now,
    clear_reason = 'document_replacement_requested'
  WHERE request_id = p_request_id;

  -- 8. Atualizar a solicitação pública de dependente
  UPDATE public.dependent_cpf_change_requests
  SET 
    status = 'waiting_document_replacement',
    admin_feedback = 'Documento precisa ser reenviado para continuar a análise da alteração de CPF.',
    expires_at = v_holder_deadline_exclusive_at,
    updated_at = v_now
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'status', 'waiting_document_replacement'
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error_code', 'internal_error'
  );
END;
$function$;

-- ─────────────────────────────────────────────────────────────────────────
-- 5. Grants de Segurança
-- ─────────────────────────────────────────────────────────────────────────
REVOKE ALL ON FUNCTION public.conectea_admin_request_dependent_cpf_correction_v1(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_admin_request_dependent_cpf_correction_v1(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.conectea_admin_prepare_dependent_cpf_document_replacement_v1(uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_prepare_dependent_cpf_document_replacement_v1(uuid, uuid) TO service_role;

REVOKE ALL ON FUNCTION public.conectea_admin_rollback_dependent_cpf_document_replacement_v1(uuid, uuid, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_rollback_dependent_cpf_document_replacement_v1(uuid, uuid, text) TO service_role;

REVOKE ALL ON FUNCTION public.conectea_admin_commit_dependent_cpf_document_replacement_v1(uuid, uuid, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_commit_dependent_cpf_document_replacement_v1(uuid, uuid, text) TO service_role;

-- ─────────────────────────────────────────────────────────────────────────
-- 6. Comentários Administrativos
-- ─────────────────────────────────────────────────────────────────────────
COMMENT ON FUNCTION public.conectea_admin_request_dependent_cpf_correction_v1(uuid) IS
  'Solicita correção do CPF informado pelo usuário titular para o dependente (status waiting_cpf_correction). Chamado de forma direta.';

COMMENT ON FUNCTION public.conectea_admin_prepare_dependent_cpf_document_replacement_v1(uuid, uuid) IS
  'Etapa 1/3 de banco para Reenviar Documento: valida a solicitação, define status operacional applying e retorna o document_file_id.';

COMMENT ON FUNCTION public.conectea_admin_rollback_dependent_cpf_document_replacement_v1(uuid, uuid, text) IS
  'Etapa de desfazimento/rollback para Reenviar Documento: reverte status de applying para under_review se o descarte do GAS falhar.';

COMMENT ON FUNCTION public.conectea_admin_commit_dependent_cpf_document_replacement_v1(uuid, uuid, text) IS
  'Etapa 2/3 de banco para Reenviar Documento: atualiza status para waiting_document_replacement e limpa ID após descarte imediato confirmado pelo GAS.';
