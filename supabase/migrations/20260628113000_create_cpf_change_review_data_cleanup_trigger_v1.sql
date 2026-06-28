-- =========================================================================
-- ConeCTEA — Trigger para Expurgo Automático de Review Data de CPF
--
-- MIGRATION: 20260628113000_create_cpf_change_review_data_cleanup_trigger_v1.sql
-- OBJETIVO:
--   - Criar o gatilho automático tr_account_change_requests_clear_cpf_review_data_v1
--     para limpar em definitivo dados sensíveis (PII) de CPF em formato claro
--     assim que a solicitação de alteração sair dos status analisáveis.
--
-- PRIVACIDADE E SEGURANÇA:
--   - A função trigger é SECURITY DEFINER e reside no schema privado.
--   - O search_path é blindado contra hijacking: pg_catalog, public, private, pg_temp.
--   - O trigger é executado em AFTER UPDATE de status de solicitações do tipo CPF.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. FUNÇÃO TRIGGER PRIVADA NO SCHEMA PRIVATE
-- ─────────────────────────────────────────────────────────────────────────

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

  -- C. Interceptar mudança de status para estados não-analisáveis (fechados ou avançados)
  IF NEW.status IN (
    'waiting_holder_confirmation'::public.account_change_status,
    'applying'::public.account_change_status,
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
      WHEN 'waiting_holder_confirmation'::public.account_change_status THEN
        v_reason := 'status_waiting_holder_confirmation';
      WHEN 'applying'::public.account_change_status THEN
        v_reason := 'status_applying';
      WHEN 'application_failed'::public.account_change_status THEN
        v_reason := 'status_application_failed';
      ELSE
        v_reason := 'status_changed';
    END CASE;

    -- Executar o expurgo físico chamando a função transacional de limpeza existente
    PERFORM private.conectea_clear_account_change_review_data_v1(NEW.id, v_reason);
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION private.conectea_clear_cpf_review_data_on_status_change_v1() IS
  'Função trigger privada executada de forma transacional para expurgar dados sensíveis de CPF da tabela de review quando a solicitação muda de status.';

-- ─────────────────────────────────────────────────────────────────────────
-- 2. CRIAÇÃO DO TRIGGER NA TABELA PÚBLICA DE SOLICITAÇÕES
-- ─────────────────────────────────────────────────────────────────────────

DROP TRIGGER IF EXISTS tr_account_change_requests_clear_cpf_review_data_v1 
  ON public.account_change_requests;

CREATE TRIGGER tr_account_change_requests_clear_cpf_review_data_v1
  AFTER UPDATE OF status ON public.account_change_requests
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION private.conectea_clear_cpf_review_data_on_status_change_v1();
