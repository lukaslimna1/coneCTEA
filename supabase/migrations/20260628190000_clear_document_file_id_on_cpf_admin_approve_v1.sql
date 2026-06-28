-- =========================================================================
-- ConeCTEA — Ajuste na RPC de Aprovação para Limpeza Imediata de Documento
-- 
-- MIGRATION: 20260628190000_clear_document_file_id_on_cpf_admin_approve_v1.sql
-- OBJETIVO: Corrigir a RPC de aprovação para, após enfileirar o descarte do
--           documento no GC Drive, limpar o document_file_id da tabela de
--           revisão e alterar o state para 'discarded'. Os CPFs em claro
--           não são alterados para sobreviverem ao final do ciclo.
-- =========================================================================

CREATE OR REPLACE FUNCTION public.conectea_admin_approve_cpf_change_request_v1(
  p_request_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
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
      'error_code', 'unauthorized'
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

  -- 2. Buscar a solicitação (apenas campos operacionais não sensíveis)
  SELECT id, type, status 
  INTO v_request
  FROM public.account_change_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND OR v_request.type <> 'cpf'::public.account_change_type THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'not_found'
    );
  END IF;

  IF v_request.status <> 'under_review'::public.account_change_status THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status'
    );
  END IF;

  -- Fixar now()
  v_now := now();

  -- 3. Calcular prazo de 10 dias úteis para o titular responder
  -- conectea_account_change_holder_deadline_v1 usa a data do servidor e fuso de SP
  v_holder_deadline_exclusive_at := public.conectea_account_change_holder_deadline_v1(v_now);

  -- 4. Capturar document_file_id da tabela de review antes da limpeza
  SELECT document_file_id INTO v_document_file_id
  FROM private.account_change_review_data
  WHERE request_id = p_request_id;

  -- 5. Enfileirar descarte do Drive ANTES da mudança de status e limpar da tabela
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
      'request_approved'
    );

    UPDATE private.account_change_review_data
    SET
      document_file_id = NULL,
      document_state = 'discarded'
    WHERE request_id = p_request_id;
  END IF;

  -- 6. Atualizar o protocolo
  UPDATE public.account_change_requests
  SET 
    status = 'waiting_holder_confirmation'::public.account_change_status,
    admin_id = v_uid,
    holder_deadline_started_at = v_now,
    holder_deadline_exclusive_at = v_holder_deadline_exclusive_at,
    status_changed_at = v_now,
    updated_at = v_now,
    resolution_reason = NULL -- garante que reseta caso venha preenchido (constraints)
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'status', 'waiting_holder_confirmation',
    'holder_deadline_started_at', v_now,
    'holder_deadline_exclusive_at', v_holder_deadline_exclusive_at
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error_code', 'internal_error'
  );
END;
$$;

COMMENT ON FUNCTION public.conectea_admin_approve_cpf_change_request_v1(uuid)
  IS 'RPC segura para administradores (master/dev) aprovarem a troca de CPF, enviando-a para a etapa de confirmação do titular com prazo, enfileirando o descarte do documento no Drive e expurgando imediatamente a referência dele.';

-- Mínimo privilégio
REVOKE ALL ON FUNCTION public.conectea_admin_approve_cpf_change_request_v1(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_admin_approve_cpf_change_request_v1(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_approve_cpf_change_request_v1(uuid) TO service_role;
