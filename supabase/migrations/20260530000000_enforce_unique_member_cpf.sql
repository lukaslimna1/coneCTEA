-- ConeCTEA — Migration: Enforce Unique Member CPF and Secure RPC Validator
-- MIGRATION: 20260530000000_enforce_unique_member_cpf.sql
-- 
-- Regras de Negócio Importantes:
-- 1. CPF de profiles identifica a conta do app.
-- 2. CPF de members identifica o beneficiário/carteirinha.
-- 3. É permitido profiles.cpf ser igual a members.cpf quando o titular solicita carteirinha para si mesmo.
-- 4. É proibido que o mesmo CPF apareça em dois ou mais registros distintos da tabela members (unicidade global de dependente).
-- 
-- Estratégia Técnica:
-- - Validação defensiva inicial: impede a aplicação da migration se houver dados inconsistentes duplicados,
--   usando como critério o CPF normalizado não vazio (NULLIF e regexp_replace).
-- - Índice de Unicidade Físico Parcial baseado em CPF normalizado (sem máscara):
--   Isso assegura integridade física no banco independentemente de a UI salvar com ou sem máscara,
--   sem alterar os CPFs mascarados já salvos em members.cpf, preservando a exibição visual da UI.
--   A cláusula WHERE filtra CPFs normalizados não vazios usando NULLIF.
-- - Função remota RPC segura com SECURITY DEFINER para checagem global via app ignorando o RLS de SELECT,
--   realizando validação física estrita de formato de 11 dígitos, sem expor dados privados de terceiros (LGPD).

-- ==========================================
-- 1. VALIDAÇÃO DEFENSIVA PRÉVIA (SEGURANÇA)
-- ==========================================
DO $$
DECLARE
  v_duplicate_count integer;
BEGIN
  SELECT COUNT(*)
  INTO v_duplicate_count
  FROM (
    SELECT NULLIF(regexp_replace(cpf, '[^0-9]', '', 'g'), '')
    FROM public.members
    WHERE NULLIF(regexp_replace(cpf, '[^0-9]', '', 'g'), '') IS NOT NULL
    GROUP BY NULLIF(regexp_replace(cpf, '[^0-9]', '', 'g'), '')
    HAVING COUNT(*) > 1
  ) AS duplicates;

  IF v_duplicate_count > 0 THEN
    RAISE EXCEPTION 'A migration foi abortada. Foram encontradas duplicidades de CPF normalizado na tabela public.members. É obrigatório executar o saneamento de dados antes de aplicar esta migration.';
  END IF;
END;
$$;

-- ==========================================
-- 2. CRIAÇÃO DO ÍNDICE DE UNICIDADE GLOBAL
-- ==========================================
-- Cria um índice de unicidade global baseado na normalização (remoção de caracteres não numéricos)
-- O índice é parcial para ignorar registros nulos ou vazios no CPF normalizado
CREATE UNIQUE INDEX IF NOT EXISTS members_cpf_normalized_unique_idx 
ON public.members (regexp_replace(cpf, '[^0-9]', '', 'g'))
WHERE NULLIF(regexp_replace(cpf, '[^0-9]', '', 'g'), '') IS NOT NULL;

COMMENT ON INDEX public.members_cpf_normalized_unique_idx IS 'Garante que o mesmo CPF de beneficiário não possa ser registrado em contas ou registros distintos.';

-- ==========================================
-- 3. FUNÇÃO RPC SEGURA PARA A TELA DE SOLICITAÇÃO (SECURITY DEFINER)
-- ==========================================
-- Permite que usuários comuns façam a validação global de existência de CPF de dependente
-- sem ferir o RLS (estrangeiro) e sem expor dados privados confidenciais (conforme a LGPD).
CREATE OR REPLACE FUNCTION public.is_member_cpf_registered(
  p_cpf text,
  p_member_id uuid DEFAULT NULL
)
RETURNS boolean AS $$
DECLARE
  v_clean_cpf text;
  v_exists boolean;
BEGIN
  -- 1. Higieniza o CPF recebido removendo quaisquer caracteres não numéricos
  v_clean_cpf := regexp_replace(p_cpf, '[^0-9]', '', 'g');
  
  -- 2. Retorna falso se o CPF informado for nulo, vazio ou não possuir tamanho padrão de 11 dígitos
  IF v_clean_cpf IS NULL OR v_clean_cpf = '' OR length(v_clean_cpf) != 11 THEN
    RETURN false;
  END IF;
  
  -- 3. Faz a consulta de existência ignorando o próprio membro (para fluxos de edição do mesmo dependente)
  IF p_member_id IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1 
      FROM public.members 
      WHERE regexp_replace(cpf, '[^0-9]', '', 'g') = v_clean_cpf 
        AND id != p_member_id
    ) INTO v_exists;
  ELSE
    SELECT EXISTS (
      SELECT 1 
      FROM public.members 
      WHERE regexp_replace(cpf, '[^0-9]', '', 'g') = v_clean_cpf
    ) INTO v_exists;
  END IF;
  
  RETURN v_exists;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

COMMENT ON FUNCTION public.is_member_cpf_registered(text, uuid) IS 'Verifica de forma global se um CPF de beneficiário já está cadastrado, sem expor dados pessoais (LGPD).';

-- ==========================================
-- 4. CONFIGURAÇÃO DE PRIVILÉGIOS (GRANTS E REVOKES)
-- ==========================================
-- Por segurança (Security Definer), removemos acesso de roles não autenticadas (anônimas e públicas)
-- e concedemos execução exclusivamente para usuários autenticados (TO authenticated).
REVOKE ALL ON FUNCTION public.is_member_cpf_registered(text, uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.is_member_cpf_registered(text, uuid) TO authenticated;
