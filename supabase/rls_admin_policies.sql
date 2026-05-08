-- ============================================================
-- ConeCTEA — Políticas RLS para Administradores
-- 
-- COMO APLICAR:
--   1. Acesse: https://supabase.com/dashboard/project/SEU_PROJECT_ID/sql/new
--   2. Cole TODO este arquivo no editor SQL
--   3. Clique em "Run"
--
-- Este script é IDEMPOTENTE — pode ser rodado mais de uma vez
-- sem causar erros (usa DROP IF EXISTS + CREATE)
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- FUNÇÃO HELPER: verifica se o usuário atual é admin
-- Usada em todas as policies abaixo
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role IN ('admin', 'admin_master', 'admin_dev')
  );
$$;


-- ╔══════════════════════════════════════════════════════════╗
-- ║  TABELA: card_requests                                   ║
-- ╚══════════════════════════════════════════════════════════╝

-- Usuários veem apenas as próprias solicitações
DROP POLICY IF EXISTS "Users can view own card requests" ON public.card_requests;
CREATE POLICY "Users can view own card requests"
  ON public.card_requests
  FOR SELECT
  USING (auth.uid() = user_id);

-- Admins veem TODAS as solicitações
DROP POLICY IF EXISTS "Admins can view all card requests" ON public.card_requests;
CREATE POLICY "Admins can view all card requests"
  ON public.card_requests
  FOR SELECT
  USING (public.is_admin());

-- Usuários criam suas próprias solicitações
DROP POLICY IF EXISTS "Users can insert own card requests" ON public.card_requests;
CREATE POLICY "Users can insert own card requests"
  ON public.card_requests
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Usuários atualizam apenas as próprias solicitações
DROP POLICY IF EXISTS "Users can update own card requests" ON public.card_requests;
CREATE POLICY "Users can update own card requests"
  ON public.card_requests
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Admins atualizam QUALQUER solicitação (aprovar, reprovar, etc.)
DROP POLICY IF EXISTS "Admins can update all card requests" ON public.card_requests;
CREATE POLICY "Admins can update all card requests"
  ON public.card_requests
  FOR UPDATE
  USING (public.is_admin());


-- ╔══════════════════════════════════════════════════════════╗
-- ║  TABELA: members                                         ║
-- ╚══════════════════════════════════════════════════════════╝

-- Usuários veem apenas os próprios membros
DROP POLICY IF EXISTS "Users can view own members" ON public.members;
CREATE POLICY "Users can view own members"
  ON public.members
  FOR SELECT
  USING (auth.uid() = user_id);

-- Admins veem TODOS os membros
DROP POLICY IF EXISTS "Admins can view all members" ON public.members;
CREATE POLICY "Admins can view all members"
  ON public.members
  FOR SELECT
  USING (public.is_admin());

-- Admins atualizam qualquer membro (sincronizar status)
DROP POLICY IF EXISTS "Admins can update all members" ON public.members;
CREATE POLICY "Admins can update all members"
  ON public.members
  FOR UPDATE
  USING (public.is_admin());


-- ╔══════════════════════════════════════════════════════════╗
-- ║  TABELA: digital_cards                                   ║
-- ╚══════════════════════════════════════════════════════════╝

-- Usuários veem apenas as próprias carteirinhas
DROP POLICY IF EXISTS "Users can view own digital cards" ON public.digital_cards;
CREATE POLICY "Users can view own digital cards"
  ON public.digital_cards
  FOR SELECT
  USING (auth.uid() = user_id);

-- Admins veem TODAS as carteirinhas
DROP POLICY IF EXISTS "Admins can view all digital cards" ON public.digital_cards;
CREATE POLICY "Admins can view all digital cards"
  ON public.digital_cards
  FOR SELECT
  USING (public.is_admin());

-- Admins atualizam/criam qualquer carteirinha
DROP POLICY IF EXISTS "Admins can upsert all digital cards" ON public.digital_cards;
CREATE POLICY "Admins can upsert all digital cards"
  ON public.digital_cards
  FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());


-- ╔══════════════════════════════════════════════════════════╗
-- ║  TABELA: profiles                                        ║
-- ╚══════════════════════════════════════════════════════════╝

-- Cada usuário vê e edita o próprio perfil
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Admins veem TODOS os perfis (para a aba de Usuários do painel)
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
CREATE POLICY "Admins can view all profiles"
  ON public.profiles
  FOR SELECT
  USING (public.is_admin());

-- Admins atualizam qualquer perfil (ex: mudar cargo)
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;
CREATE POLICY "Admins can update all profiles"
  ON public.profiles
  FOR UPDATE
  USING (public.is_admin());


-- ╔══════════════════════════════════════════════════════════╗
-- ║  TABELA: notifications                                   ║
-- ╚══════════════════════════════════════════════════════════╝

-- Usuários veem apenas as próprias notificações
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications"
  ON public.notifications
  FOR SELECT
  USING (auth.uid() = user_id);

-- Admins criam notificações para qualquer usuário
DROP POLICY IF EXISTS "Admins can insert notifications" ON public.notifications;
CREATE POLICY "Admins can insert notifications"
  ON public.notifications
  FOR INSERT
  WITH CHECK (public.is_admin());

-- Usuários marcam as próprias notificações como lidas
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
  ON public.notifications
  FOR UPDATE
  USING (auth.uid() = user_id);


-- ─────────────────────────────────────────────────────────────
-- VERIFICAÇÃO FINAL
-- Após rodar, este SELECT deve retornar todas as policies
-- ─────────────────────────────────────────────────────────────
SELECT
  schemaname,
  tablename,
  policyname,
  cmd AS operation
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('card_requests', 'members', 'digital_cards', 'profiles', 'notifications')
ORDER BY tablename, cmd;
