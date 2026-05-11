-- Script para atualizar o sistema de Roles (Cargos) no Supabase
-- Versão 3.0.0

-- 1. Garantir que a coluna role aceite os novos valores (se houver check constraint, removemos)
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

-- 2. Adicionar uma nova constraint de validação para os cargos permitidos
ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check 
CHECK (role IN ('user', 'admin', 'admin_master', 'admin_dev'));

-- 3. Definir o usuário criador como ADM DEV automaticamente (baseado no e-mail)
-- Nota: Isso garante que o Lucas tenha acesso total mesmo que o banco seja resetado
UPDATE public.profiles 
SET role = 'admin_dev' 
WHERE email = 'lucasmslima1@gmail.com';

-- 4. Habilitar RLS (Row Level Security)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Nota: As políticas específicas de SELECT/UPDATE para a tabela profiles
-- foram movidas para o arquivo 'rls_admin_policies.sql' para centralização
-- e maior segurança, evitando conflitos de permissões.
