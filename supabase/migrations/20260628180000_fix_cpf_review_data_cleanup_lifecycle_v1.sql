-- =========================================================================
-- ConeCTEA — Ajuste de Expurgo de Review Data de CPF
--
-- MIGRATION: 20260628180000_fix_cpf_review_data_cleanup_lifecycle_v1.sql
-- OBJETIVO:
--   - Corrigir a função trigger tr_account_change_requests_clear_cpf_review_data_v1
--     para realizar o cleanup total dos dados sensíveis (old_cpf, new_cpf) apenas
--     em status finais do ciclo de vida, preservando os CPFs durante a 
--     fase de waiting_holder_confirmation e applying.
-- =========================================================================

CREATE OR REPLACE FUNCTION private.conectea_clear_cpf_review_data_on_status_change_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $$
DECLARE
  v_reason text;
BEGIN
  -- A. Ignorar se não for alteração de status
  IF OLD.status IS NOT DISTINCT FROM NEW.status THEN
    RETURN NEW;
  END IF;

  -- B. Ignorar se não for solicitação de tipo CPF
  IF NEW.type <> 'cpf'::public.account_change_type THEN
    RETURN NEW;
  END IF;

  -- C. Interceptar mudança de status APENAS para estados finais (ciclo de vida encerrado)
  IF NEW.status IN (
    'application_failed'::public.account_change_status,
    'completed'::public.account_change_status,
    'rejected_by_admin'::public.account_change_status,
    'cancelled_by_holder'::public.account_change_status,
    'expired'::public.account_change_status
  ) THEN
    
    -- Mapeamento seguro e anônimo de clear_reason para auditoria LGPD
    CASE NEW.status
      WHEN 'completed'::public.account_change_status THEN
        v_reason := 'status_completed';
      WHEN 'rejected_by_admin'::public.account_change_status THEN
        v_reason := 'status_rejected';
      WHEN 'cancelled_by_holder'::public.account_change_status THEN
        v_reason := 'status_cancelled';
      WHEN 'expired'::public.account_change_status THEN
        v_reason := 'status_expired';
      WHEN 'application_failed'::public.account_change_status THEN
        v_reason := 'status_application_failed';
      ELSE
        v_reason := 'status_changed_to_final';
    END CASE;

    -- Executar o expurgo físico chamando a função transacional de limpeza existente
    PERFORM private.conectea_clear_account_change_review_data_v1(NEW.id, v_reason);
  END IF;

  RETURN NEW;
END;
$$;
