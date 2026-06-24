-- =========================================================================
-- ConeCTEA — Correção da Regex PostgreSQL do file_id no Cancelamento CPF
--
-- MIGRATION: 20260624071308_fix_gc_drive_file_id_postgres_regex_v1.sql
-- OBJETIVO:
--   - Corrigir o erro "invalid regular expression: invalid repetition count(s)"
--     provocado pela regex '^[a-zA-Z0-9_-]{10,256}$' no PostgreSQL.
--   - Separar a validação em tamanho (BETWEEN 10 AND 256) e caracteres (A-Za-z0-9_-).
--   - Aplicar a correção na constraint de gc_drive_files_to_delete and na função
--     private.conectea_cancel_cpf_change_request_v1.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. CORREÇÃO DA CONSTRAINT NA TABELA private.gc_drive_files_to_delete
-- ─────────────────────────────────────────────────────────────────────────

ALTER TABLE private.gc_drive_files_to_delete 
  DROP CONSTRAINT IF EXISTS chk_gc_drive_file_id;

ALTER TABLE private.gc_drive_files_to_delete 
  ADD CONSTRAINT chk_gc_drive_file_id CHECK (
    length(file_id) BETWEEN 10 AND 256
    AND file_id ~ '^[A-Za-z0-9_-]+$'
  );

-- ─────────────────────────────────────────────────────────────────────────
-- 2. CORREÇÃO DA VALIDAÇÃO NA FUNÇÃO PRIVADA
-- ─────────────────────────────────────────────────────────────────────────

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

  -- Validar formato do file_id do Google Drive de forma segura (sem causar erro de repetição no Postgres)
  IF length(p_file_id) < 10
     OR length(p_file_id) > 256
     OR p_file_id !~ '^[A-Za-z0-9_-]+$'
  THEN
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

-- ─────────────────────────────────────────────────────────────────────────
-- 3. POLÍTICA DE PRIVILÉGIOS E SEGURANÇA (GRANTS)
-- ─────────────────────────────────────────────────────────────────────────

-- Bloquear todas as execuções públicas para a função privada recriada
REVOKE ALL ON FUNCTION private.conectea_cancel_cpf_change_request_v1(uuid, uuid, text) FROM PUBLIC, anon, authenticated;

-- Conceder execução exclusiva para o service_role
GRANT EXECUTE ON FUNCTION private.conectea_cancel_cpf_change_request_v1(uuid, uuid, text) TO service_role;
