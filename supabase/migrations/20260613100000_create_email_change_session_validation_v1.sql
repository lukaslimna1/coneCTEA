-- =========================================================================
-- ConeCTEA — Validação Server-Side da Sessão Ativa
--
-- MIGRATION: 20260613100000_create_email_change_session_validation_v1.sql
-- OBJETIVO:
--   1. Criar função privada para verificar se a sessão do Supabase Auth pertence
--      ao usuário informado e se continua ativa (não vencida).
--   2. Criar wrapper RPC no schema público exposto apenas para a service_role.
--   3. Garantir segurança rígida (SECURITY DEFINER, search_path e revogações).
--
-- STATUS: Criação local da migration para validação. Não aplicada neste turno.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. FUNÇÃO PRIVADA DE VALIDAÇÃO DE SESSÃO
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION private.conectea_is_active_auth_session_v1(
  p_user_id uuid,
  p_session_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_active boolean;
BEGIN
  -- Regra: parâmetros nulos retornam false imediatamente
  IF p_user_id IS NULL OR p_session_id IS NULL THEN
    RETURN false;
  END IF;

  -- Consulta estritamente na tabela auth.sessions (schema-qualified)
  -- Verifica se a sessão existe, pertence ao usuário informado e não expirou
  SELECT EXISTS (
    SELECT 1 
    FROM auth.sessions
    WHERE id = p_session_id
      AND user_id = p_user_id
      AND (not_after IS NULL OR not_after > transaction_timestamp())
  ) INTO v_active;

  RETURN v_active;
END;
$$;

-- Comentário documental da função privada
COMMENT ON FUNCTION private.conectea_is_active_auth_session_v1(uuid, uuid) IS
  'Funçao privada com privilegios controlados que executa a consulta em auth.sessions para validar se a sessao pertence ao usuario informado e se esta ativa e nao vencida. Somente o wrapper RPC em public podera chama-la. PUBLIC, anon, authenticated e service_role nao possuem privilegios de execuçao diretos.';

-- Revoga todos os privilégios da função privada
REVOKE ALL ON FUNCTION private.conectea_is_active_auth_session_v1(uuid, uuid) FROM PUBLIC, anon, authenticated, service_role;


-- ─────────────────────────────────────────────────────────────────────────
-- 2. WRAPPER RPC PÚBLICO (EXCLUSIVO SERVICE_ROLE)
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_validate_active_session_v1(
  p_user_id uuid,
  p_session_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_is_active boolean;
BEGIN
  -- Apenas chama a função privada para evitar vazamentos de informações
  v_is_active := private.conectea_is_active_auth_session_v1(p_user_id, p_session_id);

  -- Retorna resultado estruturado em JSON
  RETURN json_build_object('active', v_is_active);
END;
$$;

-- Comentário documental da RPC pública
COMMENT ON FUNCTION public.conectea_validate_active_session_v1(uuid, uuid) IS
  'RPC publica para ser consumida exclusivamente pela service_role (usada pela Edge Function com supabaseAdmin). Recebe o user_id e o session_id extraidos da claim oficial do JWT do Supabase Auth. O JWT completo nunca entra nesta RPC, cabendo a Edge Function valida-lo previamente. Retorna apenas um objeto JSON {"active": boolean}, sem expor qualquer detalhe adicional de auth.sessions ou indicar o motivo da invalidade. O resultado false deve disparar uma resposta generica de erro para o usuario final. A service_role nao recebe permissao de SELECT na tabela auth.sessions diretamente. Execuçao proibida para PUBLIC, anon e authenticated. O refresh de tokens preserva o mesmo session_id, mas logouts ou revogaçoes invalidam a sessao.';

-- Revoga privilégios para perfis normais e públicos
REVOKE ALL ON FUNCTION public.conectea_validate_active_session_v1(uuid, uuid) FROM PUBLIC, anon, authenticated;

-- Concede privilégio de execução EXCLUSIVAMENTE para a service_role
GRANT EXECUTE ON FUNCTION public.conectea_validate_active_session_v1(uuid, uuid) TO service_role;
