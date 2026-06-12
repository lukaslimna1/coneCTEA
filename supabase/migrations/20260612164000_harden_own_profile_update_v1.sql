-- =========================================================================
-- ConeCTEA — Migration: Hardening da RPC e do Trigger de Perfil (Microfrente 1)
-- 
-- MIGRATION: 20260612164000_harden_own_profile_update_v1.sql
-- OBJETIVO: 
--   1. Endurecer a trigger BEFORE UPDATE em profiles para usar verificação 
--      deny-by-default (allowlist estrita comparando NEW e OLD via JSONB).
--   2. Bloquear explicitamente qualquer tentativa direta de alterar updated_at.
--   3. Validar a raiz do payload da RPC, rejeitando formatos não-objeto.
--   4. Validar os tipos de dados do payload, aceitando apenas string e null.
--   5. Reconfigurar os privilégios da RPC.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. SUBSTITUIR FUNÇÃO DE PROTEÇÃO BEFORE UPDATE DE public.profiles
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_protect_profile_update_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_authorized_admin boolean := false;
  v_phone_digits text;
  v_birth_date date;
  v_age int;
  v_current_date date;
BEGIN
  -- Identifica se o usuário é administrador autorizado (admin_master ou admin_dev)
  IF auth.role() = 'authenticated' AND auth.uid() IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1 
      FROM public.profiles 
      WHERE id = auth.uid() 
        AND role IN ('admin_master', 'admin_dev')
    ) INTO v_is_authorized_admin;
  END IF;

  -- Regras exclusivas para usuários comuns autenticados (não administradores master/dev)
  IF auth.role() = 'authenticated' AND NOT v_is_authorized_admin THEN
    
    -- A. Verificação deny-by-default (Allowlist real comparando NEW e OLD via JSONB)
    -- Impede qualquer alteração em colunas fora da allowlist estrita dos nove campos comuns.
    -- Isso também bloqueia tentativas do cliente de alterar updated_at.
    IF EXISTS (
      SELECT 1 
      FROM jsonb_each(to_jsonb(NEW)) AS n(key, val)
      LEFT JOIN jsonb_each(to_jsonb(OLD)) AS o(key, val) ON n.key = o.key
      WHERE n.val IS DISTINCT FROM o.val
        AND n.key NOT IN ('name', 'social_name', 'date_of_birth', 'phone', 'state', 'city', 'gender', 'race', 'institution')
    ) THEN
      RAISE EXCEPTION 'Acesso negado: tentativa de alterar campo não autorizado do perfil.';
    END IF;

    -- B. Normalização e trim de campos comuns de texto
    NEW.name := btrim(NEW.name);
    
    IF NEW.social_name IS NOT NULL THEN
      NEW.social_name := btrim(NEW.social_name);
      IF NEW.social_name = '' THEN
        NEW.social_name := NULL;
      END IF;
    END IF;

    IF NEW.gender IS NOT NULL THEN
      NEW.gender := btrim(NEW.gender);
      IF NEW.gender = '' THEN
        NEW.gender := NULL;
      END IF;
    END IF;

    IF NEW.race IS NOT NULL THEN
      NEW.race := btrim(NEW.race);
      IF NEW.race = '' THEN
        NEW.race := NULL;
      END IF;
    END IF;

    IF NEW.institution IS NOT NULL THEN
      NEW.institution := btrim(NEW.institution);
      IF NEW.institution = '' THEN
        NEW.institution := NULL;
      END IF;
    END IF;

    IF NEW.state IS NOT NULL THEN
      NEW.state := btrim(NEW.state);
    END IF;

    IF NEW.city IS NOT NULL THEN
      NEW.city := btrim(NEW.city);
    END IF;

    -- C. Validações físicas dos campos comuns
    -- Name (Nome Completo)
    IF NEW.name IS NULL OR NEW.name = '' THEN
      RAISE EXCEPTION 'O nome completo é obrigatório.';
    END IF;
    IF length(NEW.name) < 3 THEN
      RAISE EXCEPTION 'O nome completo deve conter no mínimo 3 caracteres.';
    END IF;
    IF length(NEW.name) > 100 THEN
      RAISE EXCEPTION 'O nome completo deve conter no máximo 100 caracteres.';
    END IF;

    -- State (Estado)
    IF NEW.state IS NULL OR NEW.state = '' THEN
      RAISE EXCEPTION 'O estado é obrigatório.';
    END IF;
    IF length(NEW.state) < 2 THEN
      RAISE EXCEPTION 'O estado deve conter no mínimo 2 caracteres.';
    END IF;
    IF length(NEW.state) > 50 THEN
      RAISE EXCEPTION 'O estado deve conter no máximo 50 caracteres.';
    END IF;

    -- City (Cidade)
    IF NEW.city IS NULL OR NEW.city = '' THEN
      RAISE EXCEPTION 'A cidade é obrigatória.';
    END IF;
    IF length(NEW.city) < 2 THEN
      RAISE EXCEPTION 'A cidade deve conter no mínimo 2 caracteres.';
    END IF;
    IF length(NEW.city) > 100 THEN
      RAISE EXCEPTION 'A cidade deve conter no máximo 100 caracteres.';
    END IF;

    -- Limites dos campos opcionais
    IF NEW.social_name IS NOT NULL AND length(NEW.social_name) > 100 THEN
      RAISE EXCEPTION 'O nome social deve conter no máximo 100 caracteres.';
    END IF;
    IF NEW.gender IS NOT NULL AND length(NEW.gender) > 50 THEN
      RAISE EXCEPTION 'O gênero deve conter no máximo 50 caracteres.';
    END IF;
    IF NEW.race IS NOT NULL AND length(NEW.race) > 50 THEN
      RAISE EXCEPTION 'A raça/cor deve conter no máximo 50 caracteres.';
    END IF;
    IF NEW.institution IS NOT NULL AND length(NEW.institution) > 100 THEN
      RAISE EXCEPTION 'A instituição deve conter no máximo 100 caracteres.';
    END IF;

    -- Telefone (Normalização e Formatação)
    IF NEW.phone IS NULL OR btrim(NEW.phone) = '' THEN
      RAISE EXCEPTION 'O telefone é obrigatório.';
    END IF;
    
    v_phone_digits := regexp_replace(NEW.phone, '[^0-9]', '', 'g');
    IF length(v_phone_digits) = 11 THEN
      NEW.phone := '(' || substr(v_phone_digits, 1, 2) || ') ' || substr(v_phone_digits, 3, 5) || '-' || substr(v_phone_digits, 8, 4);
    ELSIF length(v_phone_digits) = 10 THEN
      NEW.phone := '(' || substr(v_phone_digits, 1, 2) || ') ' || substr(v_phone_digits, 3, 4) || '-' || substr(v_phone_digits, 7, 4);
    ELSE
      RAISE EXCEPTION 'Telefone inválido. O telefone deve conter DDD e de 8 a 9 dígitos.';
    END IF;

    -- Data de Nascimento (Formato DD/MM/AAAA e Maioridade de 18 anos)
    IF NEW.date_of_birth IS NULL OR btrim(NEW.date_of_birth) = '' THEN
      RAISE EXCEPTION 'A data de nascimento é obrigatória.';
    END IF;
    IF NEW.date_of_birth !~ '^\d{2}/\d{2}/\d{4}$' THEN
      RAISE EXCEPTION 'Data de nascimento inválida. Use o formato DD/MM/AAAA.';
    END IF;

    BEGIN
      v_birth_date := to_date(NEW.date_of_birth, 'DD/MM/YYYY');
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Data de nascimento inválida. Use o formato DD/MM/AAAA.';
    END;

    IF to_char(v_birth_date, 'DD/MM/YYYY') != NEW.date_of_birth THEN
      RAISE EXCEPTION 'Data de nascimento inválida. Use o formato DD/MM/AAAA.';
    END IF;

    v_current_date := timezone('America/Sao_Paulo', now())::date;
    v_age := extract(year from age(v_current_date, v_birth_date));
    IF v_age < 18 THEN
      RAISE EXCEPTION 'O cadastro próprio é permitido apenas para maiores de 18 anos.';
    END IF;

  END IF;

  -- Sempre define updated_at no servidor, rejeitando qualquer valor enviado pelo cliente
  NEW.updated_at := now();

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.conectea_protect_profile_update_v1() IS 'Valida e restringe a edição do perfil de usuários comuns autenticados com base em uma allowlist real e verificação deny-by-default.';


-- ─────────────────────────────────────────────────────────────────────────
-- 2. SUBSTITUIR RPC public.conectea_update_own_profile_v1
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_update_own_profile_v1(p_changes jsonb)
RETURNS TABLE (
  out_name text,
  out_social_name text,
  out_date_of_birth text,
  out_phone text,
  out_state text,
  out_city text,
  out_gender text,
  out_race text,
  out_institution text,
  out_updated_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_row_count int;
BEGIN
  -- 1. Validar usuário autenticado
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Acesso negado: usuário não autenticado.';
  END IF;

  -- 2. Validar payload não nulo
  IF p_changes IS NULL THEN
    RAISE EXCEPTION 'Erro: payload de alterações ausente.';
  END IF;

  -- 3. Validar tipo físico do payload (deve ser exatamente um objeto json)
  IF jsonb_typeof(p_changes) <> 'object' THEN
    RAISE EXCEPTION 'Payload de alterações inválido.';
  END IF;

  -- 4. Validar objeto vazio
  IF p_changes = '{}'::jsonb THEN
    RAISE EXCEPTION 'Erro: nenhuma alteração enviada.';
  END IF;

  -- 5. Validar se todas as chaves pertencem à allowlist
  IF EXISTS (
    SELECT 1 
    FROM jsonb_object_keys(p_changes) AS k 
    WHERE k NOT IN ('name', 'social_name', 'date_of_birth', 'phone', 'state', 'city', 'gender', 'race', 'institution')
  ) THEN
    RAISE EXCEPTION 'Acesso negado: o payload contém campos não autorizados para alteração.';
  END IF;

  -- 6. Validar os tipos de valores do payload (aceitar apenas string e null)
  IF EXISTS (
    SELECT 1 
    FROM jsonb_each(p_changes) AS e(key, value)
    WHERE jsonb_typeof(e.value) NOT IN ('string', 'null')
  ) THEN
    RAISE EXCEPTION 'Payload de alterações inválido.';
  END IF;

  -- Executar o UPDATE
  RETURN QUERY
  UPDATE public.profiles p
  SET
    name = CASE WHEN p_changes ? 'name' THEN (p_changes->>'name') ELSE p.name END,
    social_name = CASE WHEN p_changes ? 'social_name' THEN (p_changes->>'social_name') ELSE p.social_name END,
    date_of_birth = CASE WHEN p_changes ? 'date_of_birth' THEN (p_changes->>'date_of_birth') ELSE p.date_of_birth END,
    phone = CASE WHEN p_changes ? 'phone' THEN (p_changes->>'phone') ELSE p.phone END,
    state = CASE WHEN p_changes ? 'state' THEN (p_changes->>'state') ELSE p.state END,
    city = CASE WHEN p_changes ? 'city' THEN (p_changes->>'city') ELSE p.city END,
    gender = CASE WHEN p_changes ? 'gender' THEN (p_changes->>'gender') ELSE p.gender END,
    race = CASE WHEN p_changes ? 'race' THEN (p_changes->>'race') ELSE p.race END,
    institution = CASE WHEN p_changes ? 'institution' THEN (p_changes->>'institution') ELSE p.institution END
  WHERE p.id = auth.uid()
  RETURNING 
    p.name, 
    p.social_name, 
    p.date_of_birth, 
    p.phone, 
    p.state, 
    p.city, 
    p.gender, 
    p.race, 
    p.institution, 
    p.updated_at;

  GET DIAGNOSTICS v_row_count = ROW_COUNT;
  IF v_row_count = 0 THEN
    RAISE EXCEPTION 'Perfil não encontrado para o usuário atual.';
  END IF;
END;
$$;

COMMENT ON FUNCTION public.conectea_update_own_profile_v1(jsonb) IS 'RPC segura com validação rigorosa do tipo de dados do payload JSONB.';


-- ─────────────────────────────────────────────────────────────────────────
-- 3. PERMISSÕES DA RPC
-- ─────────────────────────────────────────────────────────────────────────
REVOKE ALL ON FUNCTION public.conectea_update_own_profile_v1(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.conectea_update_own_profile_v1(jsonb) FROM anon;
GRANT EXECUTE ON FUNCTION public.conectea_update_own_profile_v1(jsonb) TO authenticated;
