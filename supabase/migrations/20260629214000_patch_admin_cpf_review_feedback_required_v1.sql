-- ==============================================================================
-- MIGRATION: 20260629214000_patch_admin_cpf_review_feedback_required_v1.sql
-- PURPOSE: Fix chk_conectea_change_admin_decision constraint violations by
--          adding mandatory feedback fields (admin_reason, admin_feedback, 
--          and public_admin_feedback) to the CPF admin review RPCs.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. RPC: Revisar Documento (Request Document Replacement)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.conectea_admin_request_cpf_document_replacement_v1(p_request_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_temp'
AS $function$
DECLARE
  v_uid uuid;
  v_role text;
  v_request record;
  v_holder_deadline_exclusive_at timestamptz;
  v_now timestamptz;
  v_document_file_id text;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'unauthenticated'
    );
  END IF;

  -- 1. Validar admin_master/admin_dev
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

  -- 2. Buscar e bloquear a solicitação
  SELECT id, type, status 
  INTO v_request
  FROM public.account_change_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND OR v_request.type <> 'cpf'::public.account_change_type THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_type'
    );
  END IF;

  IF v_request.status <> 'under_review'::public.account_change_status THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status'
    );
  END IF;

  -- Fixar data/hora
  v_now := now();

  -- 3. Calcular prazo do titular
  v_holder_deadline_exclusive_at := public.conectea_account_change_holder_deadline_v1(v_now);

  -- 4. Capturar document_file_id antes de limpar
  SELECT document_file_id INTO v_document_file_id
  FROM private.account_change_review_data
  WHERE request_id = p_request_id;

  -- 5. Enfileirar descarte e limpar apenas o documento
  IF v_document_file_id IS NOT NULL AND v_document_file_id <> '' THEN
    INSERT INTO private.gc_drive_files_to_delete (
      file_id,
      source_table,
      source_id,
      reason
    ) VALUES (
      v_document_file_id,
      'account_change_requests',
      p_request_id,
      'document_replaced'
    );

    UPDATE private.account_change_review_data
    SET
      document_file_id = NULL,
      document_state = 'discarded'
    WHERE request_id = p_request_id;
  END IF;

  -- 6. Atualizar a solicitação com os feedbacks obrigatórios para a constraint chk_conectea_change_admin_decision
  UPDATE public.account_change_requests
  SET 
    status = 'waiting_document_replacement'::public.account_change_status,
    admin_id = v_uid,
    admin_reason = 'unreadable_document'::public.account_change_admin_reason,
    admin_feedback = 'Documento precisa ser reenviado para continuar a análise da alteração de CPF.',
    public_admin_feedback = 'Precisamos que você envie novamente o documento para continuar a análise da sua solicitação.',
    admin_deadline_started_at = NULL,
    admin_deadline_exclusive_at = NULL,
    holder_deadline_started_at = v_now,
    holder_deadline_exclusive_at = v_holder_deadline_exclusive_at,
    status_changed_at = v_now,
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

-- ------------------------------------------------------------------------------
-- 2. RPC: Revisar CPF (Request CPF Correction)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.conectea_admin_request_cpf_correction_v1(p_request_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_temp'
AS $function$
DECLARE
  v_uid uuid;
  v_role text;
  v_request record;
  v_holder_deadline_exclusive_at timestamptz;
  v_now timestamptz;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'unauthenticated'
    );
  END IF;

  -- 1. Validar admin_master/admin_dev
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

  -- 2. Buscar e bloquear a solicitação
  SELECT id, type, status 
  INTO v_request
  FROM public.account_change_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND OR v_request.type <> 'cpf'::public.account_change_type THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_type'
    );
  END IF;

  IF v_request.status <> 'under_review'::public.account_change_status THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status'
    );
  END IF;

  -- Fixar data/hora
  v_now := now();

  -- 3. Calcular prazo do titular
  v_holder_deadline_exclusive_at := public.conectea_account_change_holder_deadline_v1(v_now);

  -- NOTA DE SEGURANÇA (HMAC e Dados de Revisão):
  -- A. A reserva de HMAC atual é mantida ('attached'). Ela será substituída pela nova reserva
  --    quando a correção for efetivamente enviada pelo usuário. Evita corrida.
  -- B. A tabela private.account_change_review_data permanece INTACTA. O documento e CPFs 
  --    continuarão preservados para a próxima análise.

  -- 4. Atualizar a solicitação com os feedbacks obrigatórios para a constraint chk_conectea_change_admin_decision
  UPDATE public.account_change_requests
  SET 
    status = 'waiting_cpf_correction'::public.account_change_status,
    admin_id = v_uid,
    admin_reason = 'cpf_mismatch'::public.account_change_admin_reason,
    admin_feedback = 'CPF informado precisa ser corrigido para continuar a análise da alteração.',
    public_admin_feedback = 'Precisamos que você informe o CPF corrigido para continuar a análise da sua solicitação.',
    admin_deadline_started_at = NULL,
    admin_deadline_exclusive_at = NULL,
    holder_deadline_started_at = v_now,
    holder_deadline_exclusive_at = v_holder_deadline_exclusive_at,
    status_changed_at = v_now,
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

-- ------------------------------------------------------------------------------
-- 3. Grants de Segurança
-- ------------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.conectea_admin_request_cpf_document_replacement_v1(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_admin_request_cpf_document_replacement_v1(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.conectea_admin_request_cpf_correction_v1(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_admin_request_cpf_correction_v1(uuid) TO authenticated;
