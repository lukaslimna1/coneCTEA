-- =========================================================================
-- ConeCTEA — Backend de Apoio ao Cancelamento de Solicitação de CPF
--
-- MIGRATION: 20260624013100_create_cancel_cpf_change_request_backend_v1.sql
-- OBJETIVO:
--   - Criar as RPCs internas e wrappers públicos restritos de apoio à Edge
--     Function de cancelamento de solicitação de CPF.
--   - Garantir liberação atômica da reserva de CPF e agendamento seguro de
--     exclusão do arquivo do Drive correspondente.
--
-- PRIVACIDADE E SEGURANÇA:
--   - Funções públicas restritas por default a service_role (não acessíveis a authenticated/anon).
--   - Execução transacional blindada contra concorrência por SELECT FOR UPDATE.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. RPC DE LEITURA DO PAYLOAD SEGURO
-- ─────────────────────────────────────────────────────────────────────────

-- Função privada de busca de payload seguro
CREATE OR REPLACE FUNCTION private.conectea_get_cpf_change_cancel_payload_v1(
  p_user_id uuid,
  p_request_id uuid
)
RETURNS TABLE (
  ciphertext text,
  nonce text,
  auth_tag text,
  algorithm text,
  key_version integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $$
BEGIN
  -- Validar inputs
  IF p_user_id IS NULL OR p_request_id IS NULL THEN
    RAISE EXCEPTION 'Parâmetros de usuário e solicitação são obrigatórios.'
      USING ERRCODE = '22004'; -- null_value_not_allowed
  END IF;

  -- Buscar se a solicitação pertence ao usuário, for de tipo CPF e estiver em status cancelável
  RETURN QUERY
  SELECT
    sp.ciphertext,
    sp.nonce,
    sp.auth_tag,
    sp.algorithm,
    sp.key_version
  FROM public.account_change_requests cr
  JOIN private.account_change_secure_payloads sp ON sp.request_id = cr.id
  WHERE cr.id = p_request_id
    AND cr.user_id = p_user_id
    AND cr.type = 'cpf'::public.account_change_type
    AND cr.status IN (
      'under_review'::public.account_change_status,
      'waiting_document_replacement'::public.account_change_status,
      'waiting_cpf_correction'::public.account_change_status,
      'waiting_holder_confirmation'::public.account_change_status
    );
END;
$$;

-- Wrapper público restrito para a leitura do payload
CREATE OR REPLACE FUNCTION public.conectea_get_cpf_change_cancel_payload_v1(
  p_user_id uuid,
  p_request_id uuid
)
RETURNS TABLE (
  ciphertext text,
  nonce text,
  auth_tag text,
  algorithm text,
  key_version integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM private.conectea_get_cpf_change_cancel_payload_v1(p_user_id, p_request_id);
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. RPC TRANSACIONAL DE CANCELAMENTO
-- ─────────────────────────────────────────────────────────────────────────

-- Função privada transacional de cancelamento
CREATE OR REPLACE FUNCTION private.conectea_cancel_cpf_change_request_v1(
  p_user_id uuid,
  p_request_id uuid,
  p_file_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $$
DECLARE
  v_now timestamptz;
  v_status public.account_change_status;
  v_resolution_reason public.account_change_resolution_reason;
BEGIN
  -- Validar inputs obrigatórios
  IF p_user_id IS NULL OR p_request_id IS NULL OR p_file_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'missing_parameters');
  END IF;

  -- Validar formato do file_id do Google Drive com a regex padrão do banco
  IF p_file_id !~ '^[a-zA-Z0-9_-]{10,256}$' THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_file_id_format');
  END IF;

  v_now := transaction_timestamp();

  -- Selecionar e bloquear a solicitação para evitar condições de corrida (FOR UPDATE)
  SELECT status INTO v_status
  FROM public.account_change_requests
  WHERE id = p_request_id
    AND user_id = p_user_id
    AND type = 'cpf'::public.account_change_type
  FOR UPDATE;

  -- Validar se a solicitação existe
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'not_found');
  END IF;

  -- Validar se o status é passível de cancelamento ativo pelo titular
  IF v_status NOT IN (
    'under_review'::public.account_change_status,
    'waiting_document_replacement'::public.account_change_status,
    'waiting_cpf_correction'::public.account_change_status,
    'waiting_holder_confirmation'::public.account_change_status
  ) THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_status');
  END IF;

  -- Mapear resolution_reason baseada no status operacional de origem
  CASE v_status
    WHEN 'under_review'::public.account_change_status THEN
      v_resolution_reason := 'cancelled_during_review'::public.account_change_resolution_reason;
    WHEN 'waiting_cpf_correction'::public.account_change_status THEN
      v_resolution_reason := 'cancelled_during_review'::public.account_change_resolution_reason;
    WHEN 'waiting_document_replacement'::public.account_change_status THEN
      v_resolution_reason := 'cancelled_while_waiting_document'::public.account_change_resolution_reason;
    WHEN 'waiting_holder_confirmation'::public.account_change_status THEN
      v_resolution_reason := 'declined_final_confirmation'::public.account_change_resolution_reason;
  END CASE;

  -- Atualizar a solicitação de alteração de conta pública
  UPDATE public.account_change_requests
  SET status = 'cancelled_by_holder'::public.account_change_status,
      resolution_reason = v_resolution_reason,
      closed_at = v_now,
      status_changed_at = v_now,
      updated_at = v_now,
      admin_deadline_started_at = NULL,
      admin_deadline_exclusive_at = NULL,
      holder_deadline_started_at = NULL,
      holder_deadline_exclusive_at = NULL
  WHERE id = p_request_id;

  -- Atualizar e liberar a reserva privada do CPF
  UPDATE private.account_change_cpf_reservations
  SET reservation_state = 'released',
      released_at = v_now,
      updated_at = v_now
  WHERE request_id = p_request_id
    AND user_id = p_user_id
    AND request_type = 'cpf'::public.account_change_type
    AND reservation_state = 'attached';

  -- Garantir que a reserva de CPF ativa foi liberada (impede deixar solicitações canceladas com CPF preso)
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reserva de CPF ativa não encontrada para esta solicitação.'
      USING ERRCODE = 'P0002'; -- no_data_found
  END IF;

  -- Enfileirar o arquivo do Google Drive para remoção assíncrona segura (LGPD)
  INSERT INTO private.gc_drive_files_to_delete (
    file_id,
    source_table,
    source_id,
    reason
  ) VALUES (
    p_file_id,
    'account_change_requests',
    p_request_id,
    'request_cancelled'
  );

  RETURN jsonb_build_object('success', true);

EXCEPTION
  WHEN OTHERS THEN
    -- Retornar erro genérico e seguro em caso de qualquer exceção para rollback transacional
    RETURN jsonb_build_object('success', false, 'error_code', 'unavailable');
END;
$$;

-- Wrapper público transacional restrito para cancelamento
CREATE OR REPLACE FUNCTION public.conectea_cancel_cpf_change_request_v1(
  p_user_id uuid,
  p_request_id uuid,
  p_file_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $$
BEGIN
  RETURN private.conectea_cancel_cpf_change_request_v1(p_user_id, p_request_id, p_file_id);
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 3. POLÍTICA DE PRIVILÉGIOS E SEGURANÇA (GRANTS)
-- ─────────────────────────────────────────────────────────────────────────

-- Bloquear todas as execuções públicas para as funções expostas em public e private
REVOKE ALL ON FUNCTION public.conectea_get_cpf_change_cancel_payload_v1(uuid, uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.conectea_cancel_cpf_change_request_v1(uuid, uuid, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.conectea_get_cpf_change_cancel_payload_v1(uuid, uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.conectea_cancel_cpf_change_request_v1(uuid, uuid, text) FROM PUBLIC, anon, authenticated;

-- Conceder execução exclusiva para o service_role
GRANT EXECUTE ON FUNCTION public.conectea_get_cpf_change_cancel_payload_v1(uuid, uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.conectea_cancel_cpf_change_request_v1(uuid, uuid, text) TO service_role;
GRANT EXECUTE ON FUNCTION private.conectea_get_cpf_change_cancel_payload_v1(uuid, uuid) TO service_role;
GRANT EXECUTE ON FUNCTION private.conectea_cancel_cpf_change_request_v1(uuid, uuid, text) TO service_role;
