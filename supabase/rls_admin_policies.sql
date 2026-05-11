-- ============================================================
-- ConeCTEA — Políticas RLS e Funções de Segurança
-- 
-- STATUS: Fase 10 (Preparação de Hardening)
-- IMPORTANTE: Este script está preparado localmente.
-- NÃO deve ser aplicado no Supabase real antes das Fases 10B e 10C.
-- A policy temporária de admin profiles ainda expõe dados pessoais de admins.
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- LIMPEZA DE POLICIES LEGADAS
-- Garante que permissões antigas sejam removidas antes de aplicar as novas.
-- ─────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all digital cards" ON public.digital_cards;
DROP POLICY IF EXISTS "Admins can upsert all digital cards" ON public.digital_cards;
DROP POLICY IF EXISTS "Digital cards are viewable by admins" ON public.digital_cards;
DROP POLICY IF EXISTS "Digital cards are manageable by admins" ON public.digital_cards;
DROP POLICY IF EXISTS "Notifications are viewable by owner" ON public.notifications;
DROP POLICY IF EXISTS "Admins can view all card requests" ON public.card_requests;
DROP POLICY IF EXISTS "Users can view own card requests" ON public.card_requests;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.card_requests;
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON public.card_requests;
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON public.card_requests;

-- ─────────────────────────────────────────────────────────────
-- FUNÇÃO HELPER: verifica se o usuário atual é admin
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role IN ('admin', 'admin_master', 'admin_dev')
  );
$$;

-- ─────────────────────────────────────────────────────────────
-- RPC: get_admin_notification_targets()
-- Objetivo: Retornar IDs de admins de forma segura para notificações,
-- sem expor colunas sensíveis (CPF, telefone, e-mail).
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_admin_notification_targets()
RETURNS TABLE (admin_id uuid)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM public.profiles
  WHERE role IN ('admin', 'admin_master', 'admin_dev');
$$;

-- Garantir que apenas usuários autenticados chamem a função
REVOKE ALL ON FUNCTION public.get_admin_notification_targets() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_admin_notification_targets() FROM anon;
GRANT EXECUTE ON FUNCTION public.get_admin_notification_targets() TO authenticated;


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

-- Usuários criam suas próprias solicitações (com status inicial padrão)
DROP POLICY IF EXISTS "Users can insert own card requests" ON public.card_requests;
CREATE POLICY "Users can insert own card requests"
  ON public.card_requests
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND status IN ('waiting_approval', 'under_review')
  );

-- Usuários atualizam apenas as próprias solicitações e apenas em estados de correção/envio
DROP POLICY IF EXISTS "Users can update own card requests" ON public.card_requests;
CREATE POLICY "Users can update own card requests"
  ON public.card_requests
  FOR UPDATE
  USING (
    auth.uid() = user_id
    AND status IN ('draft', 'waiting_docs', 'reviewing_data')
  )
  WITH CHECK (
    auth.uid() = user_id
    AND status IN ('waiting_approval', 'under_review', 'waiting_docs', 'reviewing_data')
  );

-- Admins atualizam QUALQUER solicitação (aprovar, reprovar, etc.)
DROP POLICY IF EXISTS "Admins can update all card requests" ON public.card_requests;
CREATE POLICY "Admins can update all card requests"
  ON public.card_requests
  FOR UPDATE
  USING (public.is_admin());


-- ─────────────────────────────────────────────────────────────
-- TRIGGER: Proteção de campos administrativos em card_requests
-- Impede que usuários comuns alterem notas, vencimento, protocolo, etc.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.protect_card_request_admin_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Se o usuário não for admin, ele não pode mudar campos administrativos
  IF (NOT public.is_admin()) THEN
    NEW.admin_notes = OLD.admin_notes;
    NEW.expires_at = OLD.expires_at;
    NEW.protocol = OLD.protocol;
    NEW.user_id = OLD.user_id; -- Impede troca de dono
    NEW.member_id = OLD.member_id; -- Impede troca de membro vinculado
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_protect_card_request_admin_fields ON public.card_requests;
CREATE TRIGGER tr_protect_card_request_admin_fields
  BEFORE UPDATE ON public.card_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_card_request_admin_fields();


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

-- Usuários atualizam apenas os próprios membros
DROP POLICY IF EXISTS "Users can update own members" ON public.members;
CREATE POLICY "Users can update own members"
  ON public.members
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

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

-- Admins gerenciam (ALL) TODAS as carteirinhas
DROP POLICY IF EXISTS "Admins can manage all digital cards" ON public.digital_cards;
CREATE POLICY "Admins can manage all digital cards"
  ON public.digital_cards
  FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());


-- ─────────────────────────────────────────────────────────────
-- TRIGGER DE PROTEÇÃO: impede que usuários comuns mudem seu role
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.protect_user_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Se o usuário não for admin_master ou admin_dev, ele não pode mudar o campo 'role'
  IF (
    NOT EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role IN ('admin_master', 'admin_dev')
    )
  ) THEN
    -- Se tentou mudar o role, mantém o antigo
    NEW.role = OLD.role;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_protect_user_role ON public.profiles;
CREATE TRIGGER tr_protect_user_role
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_user_role();


-- ╔══════════════════════════════════════════════════════════╗
-- ║  TABELA: profiles                                        ║
-- ╚══════════════════════════════════════════════════════════╝

-- Cada usuário vê o próprio perfil
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- [TEMPORÁRIO] Usuários veem perfis de administradores
-- ATENÇÃO: Esta policy expõe LINHAS COMPLETAS dos perfis administrativos.
-- Existe apenas para compatibilidade temporária com o Dart atual (DatabaseService).
-- NÃO deve ser considerada uma solução final.
-- DEVE ser removida assim que o DatabaseService usar get_admin_notification_targets().
DROP POLICY IF EXISTS "Users can view admin profiles" ON public.profiles;
CREATE POLICY "Users can view admin profiles"
  ON public.profiles
  FOR SELECT
  USING (role IN ('admin', 'admin_master', 'admin_dev'));

-- Admins veem TODOS os perfis
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
CREATE POLICY "Admins can view all profiles"
  ON public.profiles
  FOR SELECT
  USING (public.is_admin());

-- Usuários atualizam o próprio perfil (o trigger protege o campo role)
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Admins Master/Dev atualizam qualquer perfil (incluindo cargo)
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;
CREATE POLICY "Admins can update all profiles"
  ON public.profiles
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role IN ('admin_master', 'admin_dev')
    )
  );


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

-- Usuários comuns podem criar notificações APENAS se o destinatário for um admin
DROP POLICY IF EXISTS "Users can insert notifications to admins" ON public.notifications;
CREATE POLICY "Users can insert notifications to admins"
  ON public.notifications
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = user_id
      AND role IN ('admin', 'admin_master', 'admin_dev')
    )
  );

-- Usuários marcam as próprias notificações como lidas
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
  ON public.notifications
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- ─────────────────────────────────────────────────────────────
-- VERIFICAÇÃO FINAL
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
