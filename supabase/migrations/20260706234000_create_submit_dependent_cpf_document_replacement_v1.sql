-- =========================================================================
-- ConeCTEA — Submissão de Novo Documento de CPF de Dependente pelo Titular
--
-- MIGRATION: 20260706234000_create_submit_dependent_cpf_document_replacement_v1.sql
-- OBJETIVO:
--   - Criar a RPC pública que permite ao usuário titular autenticado reenviar
--     um novo documento de CPF para o dependente quando a solicitação estiver
--     no status 'waiting_document_replacement'.
--   - Atualizar a tabela de review data com o novo fileId e reverter o status
--     operacional da solicitação de volta para 'under_review'.
--   - Manter a integridade física das tabelas e a segurança da informação (LGPD).
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. RPC: Reenviar Documento de Dependente (Submit Dependent CPF Document Replacement)
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_submit_dependent_cpf_document_replacement_v1(
  p_request_id uuid,
  p_document_file_id text
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_temp'
AS $$
DECLARE
  v_uid uuid;
  v_request record;
  v_review record;
  v_now timestamptz;
  v_doc_file_id text;
  v_admin_deadline timestamptz;
BEGIN
  -- 1. Validar autenticação
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'unauthenticated'
    );
  END IF;

  -- 2. Validar parâmetros de entrada básicos
  IF p_request_id IS NULL OR p_document_file_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  -- Validar e formatar p_document_file_id
  v_doc_file_id := trim(p_document_file_id);
  IF v_doc_file_id = '' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_file_id'
    );
  END IF;

  -- Validar contra URLs do Drive e caracteres especiais para evitar exploits/dados inválidos
  -- Regex padrão de ID do Drive: ^[A-Za-z0-9_-]{10,256}$
  IF length(v_doc_file_id) < 10 OR length(v_doc_file_id) > 256 OR v_doc_file_id !~ '^[A-Za-z0-9_-]+$' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_file_id'
    );
  END IF;

  -- 3. Buscar e travar a solicitação pública com FOR UPDATE
  SELECT id, user_id, status, expires_at 
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

  -- Validar titularidade da solicitação
  IF v_request.user_id <> v_uid THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'forbidden'
    );
  END IF;

  -- Validar status exigido
  IF v_request.status <> 'waiting_document_replacement' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status'
    );
  END IF;

  v_now := now();

  -- 4. Validar expiração do prazo do titular (se aplicável)
  IF v_request.expires_at IS NOT NULL AND v_now >= v_request.expires_at THEN
    -- Transiciona para expirado in-place
    UPDATE public.dependent_cpf_change_requests
    SET 
      status = 'expired',
      updated_at = v_now
    WHERE id = p_request_id;

    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'expired',
      'status', 'expired'
    );
  END IF;

  -- 5. Buscar e travar os dados de revisão privados com FOR UPDATE
  SELECT request_id, document_file_id, document_state, cleared_at, clear_reason
  INTO v_review
  FROM private.dependent_cpf_change_review_data
  WHERE request_id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'not_found'
    );
  END IF;

  -- Validar explicitamente todo o estado privado do documento descartado na H1
  IF v_review.document_file_id IS NOT NULL 
     OR v_review.document_state <> 'discarded' 
     OR v_review.cleared_at IS NULL 
     OR v_review.clear_reason <> 'document_replacement_requested' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_document_state'
    );
  END IF;

  -- 6. Calcular novo prazo limite de resposta do admin
  v_admin_deadline := public.conectea_account_change_admin_deadline_v1(v_now);

  -- 7. Atualizar dados de revisão privados (associando o novo arquivo e limpando campos de descarte para satisfazer a constraint chk_dep_cpf_review_coherence)
  UPDATE private.dependent_cpf_change_review_data
  SET
    document_file_id = v_doc_file_id,
    document_state = 'available',
    cleared_at = NULL,
    clear_reason = NULL,
    updated_at = v_now
  WHERE request_id = p_request_id;

  -- 8. Atualizar a solicitação pública de dependente
  UPDATE public.dependent_cpf_change_requests
  SET 
    status = 'under_review',
    admin_feedback = NULL,
    expires_at = v_admin_deadline,
    updated_at = v_now
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'status', 'under_review',
    'message', 'Documento reenviado para análise.'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'internal_error'
    );
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. Comentários da Função
-- ─────────────────────────────────────────────────────────────────────────
COMMENT ON FUNCTION public.conectea_submit_dependent_cpf_document_replacement_v1(uuid, text)
  IS 'Utilizada pelo usuário titular autenticado para reenviar documento de CPF de dependente após solicitação de substituição da administração.';

-- ─────────────────────────────────────────────────────────────────────────
-- 3. Grants de Segurança Restritos
-- ─────────────────────────────────────────────────────────────────────────
REVOKE ALL ON FUNCTION public.conectea_submit_dependent_cpf_document_replacement_v1(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_submit_dependent_cpf_document_replacement_v1(uuid, text) TO authenticated;
