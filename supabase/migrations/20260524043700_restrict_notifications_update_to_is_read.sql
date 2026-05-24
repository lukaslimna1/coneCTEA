-- Remove permissão ampla de update para clientes autenticados/anônimos
REVOKE UPDATE ON public.notifications FROM authenticated;
REVOKE UPDATE ON public.notifications FROM anon;

-- Permite que usuários autenticados atualizem apenas o campo de leitura
GRANT UPDATE (is_read) ON public.notifications TO authenticated;
