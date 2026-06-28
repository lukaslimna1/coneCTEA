-- =========================================================================
-- ConeCTEA — Liberação Automática de Reservas HMAC de CPF (V1)
--
-- MIGRATION: 20260628114000_release_cpf_hmac_reservations_on_final_status_v1.sql
-- OBJETIVO:
--   - Liberar de forma automática reservas HMAC de CPF quando uma solicitação é finalizada.
--   - Ajustar a RPC conectea_cancel_cpf_change_request_v1 para suportar cancelamento legado (v1).
--   - Executar cleanup seguro retroativo de reservas presas em solicitações fechadas.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. FUNÇÃO TRIGGER PRIVADA NO SCHEMA PRIVATE
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION private.conectea_release_cpf_reservation_on_final_status_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $$
BEGIN
  -- A. Ignorar se não for alteração de status
  IF OLD.status IS NOT DISTINCT FROM NEW.status THEN
    RETURN NEW;
  END IF;

  -- B. Ignorar se não for solicitação de tipo CPF
  IF NEW.type <> 'cpf'::public.account_change_type THEN
    RETURN NEW;
  END IF;

  -- C. Liberar a reserva privada do CPF se a solicitação for finalizada
  IF NEW.status IN (
    'completed'::public.account_change_status,
    'rejected_by_admin'::public.account_change_status,
    'cancelled_by_holder'::public.account_change_status,
    'expired'::public.account_change_status
  ) THEN
    UPDATE private.account_change_cpf_reservations
    SET reservation_state = 'released',
        released_at = COALESCE(released_at, transaction_timestamp()),
        updated_at = transaction_timestamp()
    WHERE request_id = NEW.id
      AND reservation_state = 'attached';
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION private.conectea_release_cpf_reservation_on_final_status_v1() IS
  'Função trigger privada para liberar automaticamente reservas HMAC de CPF quando uma solicitação é finalizada.';

-- ─────────────────────────────────────────────────────────────────────────
-- 2. CRIAÇÃO DO TRIGGER NA TABELA PÚBLICA DE SOLICITAÇÕES
-- ─────────────────────────────────────────────────────────────────────────

DROP TRIGGER IF EXISTS tr_account_change_requests_release_cpf_reservation_v1
  ON public.account_change_requests;

CREATE TRIGGER tr_account_change_requests_release_cpf_reservation_v1
  AFTER UPDATE OF status ON public.account_change_requests
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION private.conectea_release_cpf_reservation_on_final_status_v1();

-- ─────────────────────────────────────────────────────────────────────────
-- 3. AJUSTE NA RPC DE CANCELAMENTO PARA EVITAR FALHA EM LEGADO
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

  -- Atualizar e liberar a reserva privada do CPF (idempotente/opcional)
  UPDATE private.account_change_cpf_reservations
  SET reservation_state = 'released',
      released_at = COALESCE(released_at, v_now),
      updated_at = v_now
  WHERE request_id = p_request_id
    AND user_id = p_user_id
    AND request_type = 'cpf'::public.account_change_type
    AND reservation_state = 'attached';

  -- NOTA: A falha rígida de "reserva não encontrada" (IF NOT FOUND THEN RAISE EXCEPTION)
  -- foi removida para permitir que solicitações v1 legadas (sem reserva ativa) sejam
  -- canceladas normalmente.

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
-- 4. CLEANUP RETROATIVO SEGURO DE RESERVAS PRESAS
-- ─────────────────────────────────────────────────────────────────────────

UPDATE private.account_change_cpf_reservations r
SET reservation_state = 'released',
    released_at = COALESCE(r.released_at, cr.updated_at, transaction_timestamp()),
    updated_at = transaction_timestamp()
FROM public.account_change_requests cr
WHERE r.request_id = cr.id
  AND r.reservation_state = 'attached'
  AND cr.type = 'cpf'::public.account_change_type
  AND cr.status IN (
    'completed'::public.account_change_status,
    'rejected_by_admin'::public.account_change_status,
    'cancelled_by_holder'::public.account_change_status,
    'expired'::public.account_change_status
  );
