-- ConeCTEA — Migration: Add Member Social Name
-- MIGRATION: 20260530000001_add_member_social_name.sql
--
-- Regras de Negócio:
-- 1. Nome em members deve continuar sendo o nome completo/civil para conferência administrativa e documentos.
-- 2. social_name em members será opcional.
-- 3. Se social_name existir, a carteirinha futuramente deve exibir o nome social.
-- 4. Se social_name estiver vazio/null, a carteirinha exibe name.
--
-- Restrições:
-- - Coluna nullable/opcional.
-- - Não altera dados existentes.
-- - Não cria índice.
-- - Não cria trigger.
-- - Não altera RLS/GRANTs/policies.

-- ─────────────────────────────────────────────────────────────────────────
-- 1. ADIÇÃO DA COLUNA OPCIONAL 'social_name'
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.members ADD COLUMN IF NOT EXISTS social_name text DEFAULT NULL;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. ADIÇÃO DE COMENTÁRIO EXPLICATIVO
-- ─────────────────────────────────────────────────────────────────────────
COMMENT ON COLUMN public.members.social_name IS 'Nome social opcional do beneficiário/dependente. Pode ser usado para exibição acolhedora na carteirinha quando preenchido. Não substitui o nome completo/civil usado para conferência administrativa.';
