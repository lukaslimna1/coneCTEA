-- =========================================================================
-- ConeCTEA — Ajuste de Constraint de Coerência do Review Data de CPF de Dependente
--
-- MIGRATION: 20260706235000_fix_dependent_cpf_review_data_clear_reason_constraint_v1.sql
-- OBJETIVO:
--   - Ajustar a constraint chk_dep_cpf_review_coherence na tabela
--     private.dependent_cpf_change_review_data para viabilizar o reenvio de
--     documentos.
--   - Permitir o descarte de documento com clear_reason = 'document_replacement_requested'
--     sem forçar a limpeza dos CPFs claros (old_cpf_clear e new_cpf_clear)
--     necessários à continuidade da revisão pelo admin.
--   - Manter a regra restritiva de limpeza total para outros motivos de descarte.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. Modificação da Constraint na Tabela de Review Data
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE private.dependent_cpf_change_review_data
  DROP CONSTRAINT IF EXISTS chk_dep_cpf_review_coherence;

ALTER TABLE private.dependent_cpf_change_review_data
  ADD CONSTRAINT chk_dep_cpf_review_coherence CHECK (
    cleared_at IS NULL
    OR (
      clear_reason = 'document_replacement_requested'
      AND document_file_id IS NULL
    )
    OR (
      clear_reason IS DISTINCT FROM 'document_replacement_requested'
      AND old_cpf_clear IS NULL
      AND new_cpf_clear IS NULL
      AND document_file_id IS NULL
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- 2. Comentários da Tabela para Registrar a Nova Lógica da Constraint
-- ─────────────────────────────────────────────────────────────────────────
COMMENT ON COLUMN private.dependent_cpf_change_review_data.clear_reason
  IS 'Motivo de descarte do arquivo de identificação. Caso seja document_replacement_requested, preserva os CPFs cadastrados.';
