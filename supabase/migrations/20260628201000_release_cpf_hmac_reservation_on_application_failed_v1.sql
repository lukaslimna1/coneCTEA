-- =========================================================================
-- ConeCTEA — Ajuste de Liberação de Reservas HMAC de CPF
--
-- MIGRATION: 20260628201000_release_cpf_hmac_reservation_on_application_failed_v1.sql
-- OBJETIVO:
--   - Corrigir a função privada conectea_release_cpf_reservation_on_final_status_v1
--     para que reservas de CPF também sejam liberadas quando a solicitação
--     entrar em falha de aplicação (application_failed).
--   - Executar cleanup retroativo seguro de reservas presas neste status.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. RECRIAÇÃO DA FUNÇÃO TRIGGER PRIVADA
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
    'expired'::public.account_change_status,
    'application_failed'::public.account_change_status
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
  'Função trigger privada para liberar automaticamente reservas HMAC de CPF quando uma solicitação é finalizada (incluindo falhas de aplicação).';

-- ─────────────────────────────────────────────────────────────────────────
-- 2. CLEANUP RETROATIVO SEGURO DE RESERVAS PRESAS EM APPLICATION_FAILED
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
    'expired'::public.account_change_status,
    'application_failed'::public.account_change_status
  );
