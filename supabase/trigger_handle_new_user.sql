-- ============================================================
-- Trigger: handle_new_user
-- Criado quando um usuário se registra no Supabase Auth.
-- Lê todos os campos do user_metadata e salva na tabela profiles.
-- CPF é obrigatório; campos opcionais salvam '' em vez de NULL.
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    name,
    email,
    cpf,
    phone,
    role,
    is_active,
    date_of_birth,
    city,
    state,
    institution,
    gender,
    race,
    social_name,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    COALESCE(NEW.email, ''),
    -- CPF: obrigatório — fica vazio se não vier, mas o app valida antes
    COALESCE(NEW.raw_user_meta_data->>'cpf', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    'user', -- Role fixo como 'user' por segurança (ignora metadados do cliente)
    true,
    COALESCE(NEW.raw_user_meta_data->>'date_of_birth', ''),
    COALESCE(NEW.raw_user_meta_data->>'city', ''),
    COALESCE(NEW.raw_user_meta_data->>'state', ''),
    -- Campos opcionais: salvam '' em vez de NULL
    COALESCE(NEW.raw_user_meta_data->>'institution', ''),
    COALESCE(NEW.raw_user_meta_data->>'gender', ''),
    COALESCE(NEW.raw_user_meta_data->>'race', ''),
    COALESCE(NEW.raw_user_meta_data->>'social_name', ''),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Garantir que o trigger está ativo
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
