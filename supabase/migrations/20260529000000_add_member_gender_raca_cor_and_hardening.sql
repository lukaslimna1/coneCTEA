-- =========================================================================
-- ConeCTEA — Persistência Cadastral e Hardening da Tabela Members
-- 
-- MIGRATION: 20260529000000_add_member_gender_raca_cor_and_hardening.sql
-- OBJETIVO: 
--   1. Adicionar colunas opcionais 'gender' e 'raca_cor' na tabela public.members.
--   2. Criar trigger de segurança para impedir que usuários comuns alterem
--      ou forcem campos administrativos como 'status', 'user_id', 'id' e 'created_at'.
--
-- STATUS: Criação de migration local revisada. Não aplicar no banco remoto.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. ADIÇÃO DE COLUNAS OPCIONAIS COMPLEMENTARES
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.members ADD COLUMN IF NOT EXISTS gender text DEFAULT NULL;
ALTER TABLE public.members ADD COLUMN IF NOT EXISTS raca_cor text DEFAULT NULL;

COMMENT ON COLUMN public.members.gender IS 'Gênero estatístico de preenchimento opcional do dependente.';
COMMENT ON COLUMN public.members.raca_cor IS 'Raça ou Cor estatística de preenchimento opcional (padrão IBGE).';

-- ─────────────────────────────────────────────────────────────────────────
-- 2. FUNÇÃO DE PROTEÇÃO DE CAMPOS ADMINISTRATIVOS (REVISADA)
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.protect_member_admin_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Utiliza programação defensiva robusta com COALESCE para evitar falhas ou retornos nulos
  IF (COALESCE(public.is_admin(), false) IS NOT TRUE) THEN
    
    -- LÓGICA DE INSERÇÃO (INSERT): Bloqueia injeção de status arbitrário via API
    IF (TG_OP = 'INSERT') THEN
      -- Força o status inicial oficial do fluxo de análise de carteirinhas
      NEW.status = 'waiting_approval';
      
      -- Garante a amarração correta do dono do registro
      NEW.user_id = auth.uid();
      
    -- LÓGICA DE ATUALIZAÇÃO (UPDATE): Bloqueia alteração de campos críticos de auditoria
    ELSIF (TG_OP = 'UPDATE') THEN
      -- Impede modificações no status administrativo do membro via cliente
      NEW.status = OLD.status;
      
      -- Impede a transferência de dono do registro
      NEW.user_id = OLD.user_id;

      -- Protege integridade de campos chave e de auditoria temporal original
      NEW.id = OLD.id;
      NEW.created_at = OLD.created_at;
    END IF;

  END IF;
  
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.protect_member_admin_fields() IS 'Impede que usuários comuns adulterem status, user_id, id ou created_at em inserções ou atualizações.';

-- ─────────────────────────────────────────────────────────────────────────
-- 3. TRIGGER DE SEGURANÇA (REVISADA PARA INSERT E UPDATE)
-- ─────────────────────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS tr_protect_member_admin_fields ON public.members;
CREATE TRIGGER tr_protect_member_admin_fields
  BEFORE INSERT OR UPDATE ON public.members
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_member_admin_fields();
