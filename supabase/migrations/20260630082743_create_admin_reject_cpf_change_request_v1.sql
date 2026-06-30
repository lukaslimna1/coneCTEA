-- ==============================================================================
-- MIGRATION: 20260630082743_create_admin_reject_cpf_change_request_v1.sql
-- PURPOSE: Create RPC for Admin "Rejeitar" action on CPF changes
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.conectea_admin_reject_cpf_change_request_v1(
  p_request_id uuid,
  p_admin_reason public.account_change_admin_reason,
  p_admin_feedback text
)
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

  IF p_request_id IS NULL
     OR p_admin_reason IS NULL
     OR p_admin_feedback IS NULL
     OR trim(p_admin_feedback) = '' THEN
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

  -- 4. Capturar document_file_id antes de limpar
  SELECT document_file_id INTO v_document_file_id
  FROM private.account_change_review_data
  WHERE request_id = p_request_id;

  -- 5. Enfileirar descarte do Drive e limpar tabela review_data
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
      'request_rejected'
    );

    UPDATE private.account_change_review_data
    SET
      document_file_id = NULL,
      document_state = 'discarded'
    WHERE request_id = p_request_id;
  END IF;

  -- 6. Atualizar a solicitação
  UPDATE public.account_change_requests
  SET
    status = 'rejected_by_admin'::public.account_change_status,
    admin_id = v_uid,
    admin_reason = p_admin_reason,
    admin_feedback = trim(p_admin_feedback),
    public_admin_feedback = 'Sua solicitação foi rejeitada pela equipe administrativa.',
    admin_deadline_started_at = NULL,
    admin_deadline_exclusive_at = NULL,
    holder_deadline_started_at = NULL,
    holder_deadline_exclusive_at = NULL,
    status_changed_at = v_now,
    closed_at = v_now,
    updated_at = v_now
  WHERE id = p_request_id;

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

-- ------------------------------------------------------------------------------
-- Grants de Segurança
-- ------------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.conectea_admin_reject_cpf_change_request_v1(uuid, public.account_change_admin_reason, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_admin_reject_cpf_change_request_v1(uuid, public.account_change_admin_reason, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_reject_cpf_change_request_v1(uuid, public.account_change_admin_reason, text) TO service_role;
