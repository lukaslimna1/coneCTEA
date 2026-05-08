-- ============================================================
-- ConeCTEA — Habilitar Supabase Realtime
--
-- COMO APLICAR:
--   1. https://supabase.com/dashboard/project/SEU_PROJECT/sql/new
--   2. Cole e execute TODO este script
--
-- O que faz:
--   - Adiciona as tabelas à publicação do Realtime
--   - Define REPLICA IDENTITY FULL para que eventos UPDATE
--     incluam os dados anteriores E novos (necessário para
--     que o Flutter receba as atualizações corretamente)
-- ============================================================


-- ─────────────────────────────────────────────────────────────
-- 1. REPLICA IDENTITY FULL
--    Sem isso, eventos de UPDATE não enviam dados suficientes
--    e o StreamBuilder do Flutter não detecta mudanças
-- ─────────────────────────────────────────────────────────────

ALTER TABLE public.card_requests  REPLICA IDENTITY FULL;
ALTER TABLE public.members        REPLICA IDENTITY FULL;
ALTER TABLE public.digital_cards  REPLICA IDENTITY FULL;
ALTER TABLE public.notifications  REPLICA IDENTITY FULL;
ALTER TABLE public.profiles       REPLICA IDENTITY FULL;


-- ─────────────────────────────────────────────────────────────
-- 2. ADICIONAR TABELAS À PUBLICAÇÃO DO REALTIME
--    Supabase usa a publicação "supabase_realtime" para
--    transmitir mudanças via WebSocket para os clientes
-- ─────────────────────────────────────────────────────────────

ALTER PUBLICATION supabase_realtime ADD TABLE public.card_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.members;
ALTER PUBLICATION supabase_realtime ADD TABLE public.digital_cards;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;


-- ─────────────────────────────────────────────────────────────
-- VERIFICAÇÃO: tabelas na publicação
-- ─────────────────────────────────────────────────────────────
SELECT
  pt.schemaname,
  pt.tablename
FROM pg_publication_tables pt
WHERE pt.pubname = 'supabase_realtime'
  AND pt.schemaname = 'public'
ORDER BY pt.tablename;
