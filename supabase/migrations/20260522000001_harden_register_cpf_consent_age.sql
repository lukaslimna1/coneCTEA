-- =========================================================================
-- ConeCTEA — Migration: Cadastro Seguro, CPF Único, Consentimentos e Maioridade
-- 
-- MIGRATION: 20260522000001_harden_register_cpf_consent_age.sql
-- OBJETIVO: 
--   1. Adicionar constraints físicas de unicidade e formato de dígitos para o CPF em profiles.
--   2. Criar colunas para armazenamento jurídico de evidências de consentimento LGPD e idade.
--   3. Atualizar a trigger handle_new_user() para normalizar/validar o CPF, impor bloqueio
--      estrito de idade para menores de 18 anos e persistir as assinaturas digitais de consentimento.
--
-- STATUS: Criação de migration local para revisão. Não aplicada remotamente.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. ADICIONAR COLUNAS DE EVIDÊNCIA DE CONSENTIMENTO LGPD EM public.profiles
-- ─────────────────────────────────────────────────────────────────────────

ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS consent_terms_version text,
  ADD COLUMN IF NOT EXISTS consent_privacy_version text,
  ADD COLUMN IF NOT EXISTS consent_terms_accepted_at timestamptz,
  ADD COLUMN IF NOT EXISTS consent_privacy_accepted_at timestamptz,
  ADD COLUMN IF NOT EXISTS consent_personal_data_accepted_at timestamptz,
  ADD COLUMN IF NOT EXISTS consent_health_data_accepted_at timestamptz,
  ADD COLUMN IF NOT EXISTS consent_legal_age_accepted_at timestamptz,
  ADD COLUMN IF NOT EXISTS legal_age_declared boolean, -- Sem DEFAULT false para não afetar negativamente os registros legados
  ADD COLUMN IF NOT EXISTS consent_source text;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. ADICIONAR CONSTRAINTS FÍSICAS DE SEGURANÇA PARA O CPF
-- ─────────────────────────────────────────────────────────────────────────

-- Garante que o CPF contenha apenas 11 dígitos numéricos
ALTER TABLE public.profiles 
  DROP CONSTRAINT IF EXISTS profiles_cpf_digits_check;

ALTER TABLE public.profiles 
  ADD CONSTRAINT profiles_cpf_digits_check 
  CHECK (cpf ~ '^[0-9]{11}$');

-- Garante que o CPF seja único em toda a tabela de perfis
ALTER TABLE public.profiles 
  DROP CONSTRAINT IF EXISTS profiles_cpf_unique;

ALTER TABLE public.profiles 
  ADD CONSTRAINT profiles_cpf_unique 
  UNIQUE (cpf);

-- ─────────────────────────────────────────────────────────────────────────
-- 3. REVOLUCIONAR A FUNÇÃO TRIGGER DE CRIAÇÃO DE NOVOS USUÁRIOS
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  cpf_clean text;
  birth_str text;
  birth_date date;
  age_years int;
  current_date_sp date;
BEGIN
  -- 1. CAPTURA E NORMALIZAÇÃO DE DADOS BÁSICOS
  cpf_clean := COALESCE(NEW.raw_user_meta_data->>'cpf', '');
  cpf_clean := regexp_replace(cpf_clean, '[^0-9]', '', 'g'); -- Correção na assinatura de regexp_replace (remocao de nao-numericos)
  
  birth_str := COALESCE(NEW.raw_user_meta_data->>'date_of_birth', '');

  -- 2. VERIFICAÇÃO DE DADOS OBRIGATÓRIOS DO CADASTRO
  IF cpf_clean = '' THEN
    RAISE EXCEPTION 'O CPF é obrigatório para a criação da conta.';
  END IF;

  IF birth_str = '' THEN
    RAISE EXCEPTION 'A data de nascimento é obrigatória para a criação da conta.';
  END IF;

  -- 3. VALIDAR FORMATO FÍSICO DO CPF
  IF length(cpf_clean) != 11 THEN
    RAISE EXCEPTION 'O CPF deve conter exatamente 11 dígitos numéricos.';
  END IF;

  -- 4. VALIDAR UNICIDADE DE CPF EM NÍVEL DE APLICATIVO (Mensagem Controlada)
  IF EXISTS (SELECT 1 FROM public.profiles WHERE cpf = cpf_clean) THEN
    RAISE EXCEPTION 'Este CPF já está cadastrado em outra conta. Se você esqueceu seus dados, utilize a Recuperação de E-mail.';
  END IF;

  -- 5. VALIDAR FORMATO E INTEGRIDADE DA DATA DE NASCIMENTO (DD/MM/AAAA)
  -- Validação rígida por expressão regular do formato físico
  IF birth_str !~ '^\d{2}/\d{2}/\d{4}$' THEN
    RAISE EXCEPTION 'Data de nascimento inválida. Use o formato DD/MM/AAAA.';
  END IF;

  -- Conversão em data Postgres
  BEGIN
    birth_date := to_date(birth_str, 'DD/MM/YYYY');
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Data de nascimento inválida. Use o formato DD/MM/AAAA.';
  END;

  -- Validação rígida round-trip para evitar datas inexistentes (ex: 30/02/2020 que vira 01/03/2020)
  IF to_char(birth_date, 'DD/MM/YYYY') != birth_str THEN
    RAISE EXCEPTION 'Data de nascimento inválida. Use o formato DD/MM/AAAA.';
  END IF;

  -- 6. VALIDAR REGRA DE MAIORIDADE MÍNIMA (18 ANOS)
  current_date_sp := (timezone('America/Sao_Paulo'::text, now()))::date;
  age_years := extract(year from age(current_date_sp, birth_date));

  IF age_years < 18 THEN
    RAISE EXCEPTION 'O cadastro próprio é permitido apenas para maiores de 18 anos. Caso seja menor de idade, peça para seu responsável legal realizar o cadastro.';
  END IF;

  -- 7. VALIDAR CONSENTIMENTOS OBRIGATÓRIOS LGPD
  IF COALESCE(NEW.raw_user_meta_data->>'consent_terms_accepted', 'false')::boolean = false THEN
    RAISE EXCEPTION 'Você precisa ler e aceitar os Termos de Uso para continuar.';
  END IF;

  IF COALESCE(NEW.raw_user_meta_data->>'consent_privacy_accepted', 'false')::boolean = false THEN
    RAISE EXCEPTION 'Você precisa aceitar a Política de Privacidade para continuar.';
  END IF;

  IF COALESCE(NEW.raw_user_meta_data->>'consent_personal_data_accepted', 'false')::boolean = false THEN
    RAISE EXCEPTION 'Você precisa autorizar o tratamento de seus dados pessoais comuns para continuar.';
  END IF;

  IF COALESCE(NEW.raw_user_meta_data->>'consent_health_data_accepted', 'false')::boolean = false THEN
    RAISE EXCEPTION 'Você precisa autorizar o tratamento de seus dados de saúde e laudos médicos para continuar.';
  END IF;

  IF COALESCE(NEW.raw_user_meta_data->>'legal_age_declared', 'false')::boolean = false THEN
    RAISE EXCEPTION 'Você precisa declarar que possui 18 anos ou mais e assume responsabilidade pelo cadastro.';
  END IF;

  -- 8. EFETUAR A INSERÇÃO ATÔMICA DO NOVO PERFIL
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
    updated_at,
    
    -- Colunas jurídicas de evidência LGPD
    consent_terms_version,
    consent_privacy_version,
    consent_terms_accepted_at,
    consent_privacy_accepted_at,
    consent_personal_data_accepted_at,
    consent_health_data_accepted_at,
    consent_legal_age_accepted_at,
    legal_age_declared,
    consent_source
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    COALESCE(NEW.email, ''),
    cpf_clean,
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    'user', -- Role restrita padrão por segurança
    true,
    birth_str,
    COALESCE(NEW.raw_user_meta_data->>'city', ''),
    COALESCE(NEW.raw_user_meta_data->>'state', ''),
    COALESCE(NEW.raw_user_meta_data->>'institution', ''),
    COALESCE(NEW.raw_user_meta_data->>'gender', ''),
    COALESCE(NEW.raw_user_meta_data->>'race', ''),
    COALESCE(NEW.raw_user_meta_data->>'social_name', ''),
    now(),
    now(),
    
    -- Persistência de assinaturas de consentimento com fallbacks seguros e NULLIF
    COALESCE(NULLIF(NEW.raw_user_meta_data->>'consent_terms_version', ''), '1.0'),
    COALESCE(NULLIF(NEW.raw_user_meta_data->>'consent_privacy_version', ''), '1.0'),
    now(),
    now(),
    now(),
    now(),
    now(),
    true,
    COALESCE(NULLIF(NEW.raw_user_meta_data->>'consent_source', ''), 'register')
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$function$;
