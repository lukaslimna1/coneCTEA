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

-- 4. Criar Política de Segurança (RLS) para proteção de cargos
-- Somente ADM Master e ADM DEV podem alterar o campo 'role' de outros usuários

-- Primeiro, habilitamos RLS se não estiver habilitado
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Política: Usuários podem ler todos os perfis (necessário para a lista de admins)
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Profiles are viewable by everyone" 
ON public.profiles FOR SELECT 
USING (true);

-- Política: Usuários podem atualizar seus próprios dados (exceto o cargo)
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" 
ON public.profiles FOR UPDATE 
USING (auth.uid() = id)
WITH CHECK (
  -- Se o usuário comum tentar mudar o role dele mesmo, a transação falha
  -- (A menos que ele já seja um Master/Dev)
  ((SELECT role FROM public.profiles WHERE id = auth.uid()) IN ('admin_master', 'admin_dev'))
  OR 
  (role = (SELECT role FROM public.profiles WHERE id = auth.uid()))
);

-- Política: ADM Master e DEV podem atualizar qualquer perfil
DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles;
CREATE POLICY "Admins can update any profile" 
ON public.profiles FOR UPDATE 
USING (
  ((SELECT role FROM public.profiles WHERE id = auth.uid()) IN ('admin_master', 'admin_dev'))
);
