-- Permite que qualquer usuário autenticado veja os IDs dos administradores
-- (Isso é necessário para que o app saiba para quem enviar a notificação)
DROP POLICY IF EXISTS "Users can view admin profiles" ON public.profiles;
CREATE POLICY "Users can view admin profiles"
  ON public.profiles
  FOR SELECT
  USING (role = 'admin');

-- Permite que usuários comuns criem notificações, DESDE QUE o destinatário seja um admin
DROP POLICY IF EXISTS "Users can insert notifications to admins" ON public.notifications;
CREATE POLICY "Users can insert notifications to admins"
  ON public.notifications
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles WHERE id = user_id AND role = 'admin'
    )
  );

-- ADICIONANDO O CAMPO PARA DATAS DE EXPIRAÇÃO (Prazos)
ALTER TABLE card_requests ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE;
