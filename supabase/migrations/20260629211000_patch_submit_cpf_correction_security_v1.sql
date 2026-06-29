-- supabase/migrations/20260629211000_patch_submit_cpf_correction_security_v1.sql
-- Objetivo: Restringir a RPC public.conectea_submit_cpf_correction_v1 para que ela 
-- não receba HMAC vindo diretamente de clientes vulneráveis (authenticated/anon).
-- A execução agora é estritamente concedida à service_role (Edge Function).

REVOKE ALL ON FUNCTION public.conectea_submit_cpf_correction_v1(uuid, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.conectea_submit_cpf_correction_v1(uuid, text, text) FROM anon;
REVOKE ALL ON FUNCTION public.conectea_submit_cpf_correction_v1(uuid, text, text) FROM authenticated;

-- Permite execução pela service role para a Edge Function acessar a RPC
GRANT EXECUTE ON FUNCTION public.conectea_submit_cpf_correction_v1(uuid, text, text) TO service_role;

COMMENT ON FUNCTION public.conectea_submit_cpf_correction_v1(uuid, text, text) IS 'Uso interno via Edge Function. Recebe HMAC seguro para atualização de CPF.';
