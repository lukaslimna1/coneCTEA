-- Migration: has_unread_notifications_rpc
-- Verifica se o usuário logado possui notificações não lidas de forma otimizada (sem baixar lista).

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
ON public.notifications (user_id, is_read)
WHERE is_read = false;

CREATE OR REPLACE FUNCTION public.has_unread_notifications()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.notifications
    WHERE user_id = auth.uid()
      AND is_read = false
    LIMIT 1
  );
$$;

-- Remove permissão do public/anon por segurança
REVOKE EXECUTE ON FUNCTION public.has_unread_notifications() FROM public;
REVOKE EXECUTE ON FUNCTION public.has_unread_notifications() FROM anon;

-- Concede acesso apenas a usuários autenticados
GRANT EXECUTE ON FUNCTION public.has_unread_notifications() TO authenticated;
