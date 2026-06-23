-- =========================================================================
-- ConeCTEA — Adição de Status waiting_cpf_correction ao Enum public.account_change_status
--
-- MIGRATION: 20260623180040_20260623180000_add_waiting_cpf_correction_status_v1.sql
-- OBJETIVO:
--   - Adicionar o valor 'waiting_cpf_correction' ao tipo ENUM public.account_change_status.
--
-- JUSTIFICATIVA E DESENHO TÉCNICO:
--   - Isolamento de Enum: A adição do valor é feita de forma isolada nesta migration, sem recriar
--     o tipo ENUM por completo e sem associá-lo a novos índices ou constraints no mesmo arquivo.
--   - Prevenção de Erro Transacional: No PostgreSQL/Supabase, a instrução ALTER TYPE ... ADD VALUE
--     não pode ser utilizada em conjunto com a criação de novos índices ou modificação de tabelas
--     que consumam o novo valor de enum dentro do mesmo bloco de transação.
--   - Divisão Lógica: A Migration 2B subsequente cuidará exclusivamente da atualização do índice
--     ativo account_change_requests_active_idx, eliminando qualquer risco transacional.
-- =========================================================================

-- Adiciona o valor 'waiting_cpf_correction' ao enum existente
ALTER TYPE public.account_change_status ADD VALUE IF NOT EXISTS 'waiting_cpf_correction';
