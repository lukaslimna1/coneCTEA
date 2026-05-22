-- =========================================================================
-- ConeCTEA — Hardening de Grants de Segurança do Banco de Dados
-- 
-- MIGRATION: 20260522000000_harden_public_grants.sql
-- OBJETIVO: Implementar o modelo de privilégios mínimos no nível de banco.
--           Revogar acessos amplos automáticos padrões concedidos a 'anon'
--           e 'authenticated', garantindo que o PostgREST (Data API)
--           só acesse o que for estritamente necessário.
--
-- STATUS: Apenas criação local de migration de segurança.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. REVOGAÇÃO DE PRIVILÉGIOS AMPLOS PADRÕES E IMPLÍCITOS
-- ─────────────────────────────────────────────────────────────────────────

-- Garante que futuras tabelas criadas no schema public não herdem concessões padrão
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM public, anon, authenticated;

-- Revoga todos os privilégios acumulados anteriores das tabelas principais
REVOKE ALL ON TABLE public.profiles FROM public, anon, authenticated;
REVOKE ALL ON TABLE public.members FROM public, anon, authenticated;
REVOKE ALL ON TABLE public.digital_cards FROM public, anon, authenticated;
REVOKE ALL ON TABLE public.card_requests FROM public, anon, authenticated;
REVOKE ALL ON TABLE public.notifications FROM public, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. RESTRIÇÃO COMPLETA DE ACESSO PARA VISITANTES (anon)
-- ─────────────────────────────────────────────────────────────────────────
-- O aplicativo ConeCTEA não publica dados abertos de suas 5 tabelas.
-- Portanto, a role 'anon' não possui nenhum privilégio (SELECT, INSERT,
-- UPDATE, DELETE) sobre perfis, dependentes, carteirinhas, solicitações
-- e notificações.

-- ─────────────────────────────────────────────────────────────────────────
-- 3. CONCESSÃO DE GRANTS RESTRITOS PARA USUÁRIOS LOGADOS (authenticated)
-- ─────────────────────────────────────────────────────────────────────────

-- Tabela: profiles
-- CRUD do App: SELECT (getUserProfile), INSERT/UPDATE (criar/atualizar cadastro)
-- Deleção física (DELETE) e limpeza em massa (TRUNCATE) são estritamente proibidos.
GRANT SELECT, INSERT, UPDATE ON TABLE public.profiles TO authenticated;

-- Tabela: members
-- CRUD do App: SELECT (getMembers), INSERT/UPDATE (criar/sincronizar dependente)
-- Deleção física (DELETE) e limpeza em massa (TRUNCATE) são estritamente proibidos.
GRANT SELECT, INSERT, UPDATE ON TABLE public.members TO authenticated;

-- Tabela: digital_cards
-- CRUD do App: SELECT (ver carteirinha), INSERT/UPDATE (criar/reativar carteirinha)
-- Deleção física (DELETE) e limpeza em massa (TRUNCATE) são estritamente proibidos.
GRANT SELECT, INSERT, UPDATE ON TABLE public.digital_cards TO authenticated;

-- Tabela: card_requests
-- CRUD do App: SELECT (painel/solicitações), INSERT/UPDATE (criar/analisar/sincronizar)
-- Deleção física (DELETE) e limpeza em massa (TRUNCATE) são estritamente proibidos.
GRANT SELECT, INSERT, UPDATE ON TABLE public.card_requests TO authenticated;

-- Tabela: notifications
-- CRUD do App: SELECT (ver inbox), INSERT (notificar admin), UPDATE (lida), DELETE (limpar inbox)
-- Apenas esta tabela possui privilégio de exclusão legítima pelo cliente.
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.notifications TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 4. AJUSTE DE PRIVILÉGIOS DE EXECUÇÃO DA FUNÇÃO public.is_admin()
-- ─────────────────────────────────────────────────────────────────────────
-- A auditoria identificou que a função auxiliar is_admin() mantinha
-- o privilégio de execução de forma aberta para PUBLIC e anon.
-- Restringimos o privilégio de execução estritamente a usuários autenticados.

REVOKE EXECUTE ON FUNCTION public.is_admin() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 5. OBSERVAÇÕES DE SEGURANÇA E PRESERVAÇÃO DE OUTROS PRODUTOS
-- ─────────────────────────────────────────────────────────────────────────
-- 1. Os privilégios das roles administrativas internas ('service_role', 'postgres'
--    e 'supabase_admin') permanecem totalmente preservados ('ALL PRIVILEGES'), 
--    sendo afetadas apenas as roles que expõem tráfego externo para a Data API.
-- 2. Todas as demais funções e RPCs ('conectea_digital_card_validity_window',
--    'conectea_admin_deadline', 'get_admin_notification_targets', etc.)
--    permanecem intocadas, já que possuem suas restrições devidamente versionadas.
-- 3. A camada de Row Level Security (RLS) e políticas persistem sem alteração,
--    agindo de forma complementar e em sinergia com os novos Grants restritos.
