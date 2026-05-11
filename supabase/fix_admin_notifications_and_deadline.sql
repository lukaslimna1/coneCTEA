-- ADICIONANDO O CAMPO PARA DATAS DE EXPIRAÇÃO (Prazos)
-- Nota: As políticas de acesso a perfis administrativos e notificações
-- foram movidas para o arquivo 'rls_admin_policies.sql' para centralização.
ALTER TABLE card_requests ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE;
