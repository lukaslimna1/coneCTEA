-- =========================================================================
-- ConeCTEA — Wrapper Pública Restrita para RPC Interna de CPF
--
-- MIGRATION: 20260623192000_create_public_cpf_change_request_rpc_wrapper_v1.sql
-- OBJETIVO:
--   - Criar a função wrapper pública public.conectea_create_cpf_change_request_v1.
--   - Permitir que a Edge Function chame a RPC através do schema 'public', 
--     que é o padrão exposto do PostgREST/API local e remoto, eliminando a
--     necessidade de expor o schema 'private' na API.
--
-- PRIVACIDADE E SEGURANÇA:
--   - A função é SECURITY DEFINER e restrita estritamente a service_role.
--   - Grants para PUBLIC, anon e authenticated são revogados por completo.
--   - O search_path é blindado contra hijack: pg_catalog, public, private, pg_temp.
--   - A função simplesmente repassa os parâmetros para a RPC privada correspondente,
--     não contendo lógica de processamento de dados e preservando a integridade.
-- =========================================================================

CREATE OR REPLACE FUNCTION public.conectea_create_cpf_change_request_v1(
  p_user_id uuid,
  p_new_cpf_clear text,
  p_new_cpf_hmac text,
  p_justification text,
  p_ciphertext text,
  p_nonce text,
  p_auth_tag text,
  p_algorithm text,
  p_key_version integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $$
BEGIN
  RETURN private.conectea_create_cpf_change_request_v1(
    p_user_id => p_user_id,
    p_new_cpf_clear => p_new_cpf_clear,
    p_new_cpf_hmac => p_new_cpf_hmac,
    p_justification => p_justification,
    p_ciphertext => p_ciphertext,
    p_nonce => p_nonce,
    p_auth_tag => p_auth_tag,
    p_algorithm => p_algorithm,
    p_key_version => p_key_version
  );
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- SEGURANÇA: CONTROLE DE GRANTS (PRIVILÉGIOS MÍNIMOS)
-- ─────────────────────────────────────────────────────────────────────────

-- Revogação total de privilégios públicos padrão
REVOKE ALL ON FUNCTION public.conectea_create_cpf_change_request_v1(
  uuid, text, text, text, text, text, text, text, integer
) FROM PUBLIC, anon, authenticated;

-- Concessão de execução exclusiva para o service_role
GRANT EXECUTE ON FUNCTION public.conectea_create_cpf_change_request_v1(
  uuid, text, text, text, text, text, text, text, integer
) TO service_role;

-- ─────────────────────────────────────────────────────────────────────────
-- COMENTÁRIOS DE DOCUMENTAÇÃO E SEGURANÇA
-- ─────────────────────────────────────────────────────────────────────────

COMMENT ON FUNCTION public.conectea_create_cpf_change_request_v1 IS
  'Wrapper pública restrita a service_role que intermedia e repassa os parâmetros para a RPC privada private.conectea_create_cpf_change_request_v1, evitando exposição do schema private no PostgREST.';
