-- =========================================================================
-- ConeCTEA — Atualização do Índice Ativo account_change_requests_active_idx
--
-- MIGRATION: 20260623180043_20260623181000_update_account_change_active_idx_for_waiting_cpf_correction_v1.sql
-- OBJETIVO:
--   - Ajustar o índice único parcial public.account_change_requests_active_idx
--     para incluir o novo status 'waiting_cpf_correction' no filtro.
--
-- JUSTIFICATIVA E DESENHO TÉCNICO:
--   - Prevenção de Concorrência: A inclusão do status no filtro garante que um usuário
--     não consiga iniciar um novo ciclo de alteração (e-mail ou CPF) enquanto houver
--     uma solicitação do mesmo tipo travada aguardando correção de CPF pelo titular.
--   - Isolamento Transacional: Esta migration ocorre em arquivo separado por timestamp
--     subsequente à Migration 2A (que cria o status enum), eliminando o erro do PostgreSQL
--     de consumir novos valores de enum no mesmo bloco transacional de sua criação.
--   - Manutenção de Unicidade: O índice permanece restrito às colunas (user_id, type)
--     com escopo de filtro restrito aos status de ciclos de vida não-finais (ativos).
-- =========================================================================

-- Dropar o índice ativo existente
DROP INDEX IF EXISTS public.account_change_requests_active_idx;

-- Recriar o índice único parcial cobrindo o novo status waiting_cpf_correction
CREATE UNIQUE INDEX account_change_requests_active_idx
  ON public.account_change_requests (user_id, type)
  WHERE status IN (
    'under_review',
    'waiting_document_replacement',
    'waiting_cpf_correction',
    'waiting_holder_confirmation',
    'applying',
    'application_failed'
  );
