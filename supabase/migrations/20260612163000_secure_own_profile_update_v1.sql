-- =========================================================================
-- ConeCTEA — Migration: Edição Segura do Perfil do Titular (Microfrente 1)
-- 
-- MIGRATION: 20260612163000_secure_own_profile_update_v1.sql
-- OBJETIVO: 
--   1. Criar e configurar a trigger BEFORE UPDATE em profiles para proteger colunas
--      administrativas e validar campos comuns para usuários autenticados comuns.
--   2. Criar e configurar a trigger AFTER UPDATE em profiles para sincronizar
--      dados atualizados do titular com seu correspondente na tabela members e digital_cards.
--   3. Criar a RPC public.conectea_update_own_profile_v1 para permitir edições
--      seguras do próprio titular via payload JSONB com validação de allowlist.
--   4. Configurar as permissões da RPC (REVOKE PUBLIC/anon, GRANT authenticated).
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. FUNÇÃO DE PROTEÇÃO BEFORE UPDATE DE public.profiles
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
    
    -- A. Bloqueio estrito de colunas protegidas
    IF (NEW.id IS DISTINCT FROM OLD.id OR
        NEW.cpf IS DISTINCT FROM OLD.cpf OR
        NEW.email IS DISTINCT FROM OLD.email OR
        NEW.role IS DISTINCT FROM OLD.role OR
        NEW.is_active IS DISTINCT FROM OLD.is_active OR
        NEW.created_at IS DISTINCT FROM OLD.created_at OR
        NEW.consent_terms_version IS DISTINCT FROM OLD.consent_terms_version OR
        NEW.consent_privacy_version IS DISTINCT FROM OLD.consent_privacy_version OR
        NEW.consent_terms_accepted_at IS DISTINCT FROM OLD.consent_terms_accepted_at OR
        NEW.consent_privacy_accepted_at IS DISTINCT FROM OLD.consent_privacy_accepted_at OR
        NEW.consent_personal_data_accepted_at IS DISTINCT FROM OLD.consent_personal_data_accepted_at OR
        NEW.consent_health_data_accepted_at IS DISTINCT FROM OLD.consent_health_data_accepted_at OR
        NEW.consent_legal_age_accepted_at IS DISTINCT FROM OLD.consent_legal_age_accepted_at OR
        NEW.legal_age_declared IS DISTINCT FROM OLD.legal_age_declared OR
        NEW.consent_source IS DISTINCT FROM OLD.consent_source) THEN
      RAISE EXCEPTION 'Acesso negado: tentativa de alterar campo protegido do perfil.';
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

  -- Sempre atualiza updated_at no servidor, rejecting valor vindo do cliente
  NEW.updated_at := now();

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.conectea_protect_profile_update_v1() IS 'Valida e restringe a edição do perfil de usuários comuns autenticados, além de normalizar telefones e definir timestamps.';

-- Criar a trigger BEFORE UPDATE
DROP TRIGGER IF EXISTS tr_conectea_protect_profile_update_v1 ON public.profiles;
CREATE TRIGGER tr_conectea_protect_profile_update_v1
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.conectea_protect_profile_update_v1();


-- ─────────────────────────────────────────────────────────────────────────
-- 2. FUNÇÃO DE SINCRONIZAÇÃO AFTER UPDATE DE public.profiles
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_sync_profile_holder_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_member_id uuid;
  v_member_count int;
  v_card_name text;
BEGIN
  -- Executa somente se pelo menos um dos campos compartilhados mudar
  IF (OLD.name IS DISTINCT FROM NEW.name OR
      OLD.social_name IS DISTINCT FROM NEW.social_name OR
      OLD.date_of_birth IS DISTINCT FROM NEW.date_of_birth OR
      OLD.phone IS DISTINCT FROM NEW.phone OR
      OLD.state IS DISTINCT FROM NEW.state OR
      OLD.city IS DISTINCT FROM NEW.city OR
      OLD.gender IS DISTINCT FROM NEW.gender OR
      OLD.race IS DISTINCT FROM NEW.race) THEN

    -- Identifica o member correspondente ao próprio titular (comparando CPFs normalizados apenas por digito)
    SELECT count(*) INTO v_member_count
    FROM public.members
    WHERE user_id = NEW.id AND regexp_replace(cpf, '[^0-9]', '', 'g') = regexp_replace(NEW.cpf, '[^0-9]', '', 'g');

    -- Aborta se houver mais de uma correspondência (anomalia de banco)
    IF v_member_count > 1 THEN
      RAISE EXCEPTION 'Erro de integridade cadastral: múltiplos registros de membro encontrados para o titular.';
    END IF;

    -- Atualiza member e digital_cards se houver exatamente um correspondente
    IF v_member_count = 1 THEN
      SELECT id INTO v_member_id
      FROM public.members
      WHERE user_id = NEW.id AND regexp_replace(cpf, '[^0-9]', '', 'g') = regexp_replace(NEW.cpf, '[^0-9]', '', 'g')
      LIMIT 1;

      -- Sincronizar dados comuns com o member
      UPDATE public.members
      SET 
        name = NEW.name,
        social_name = NEW.social_name,
        birth_date = NEW.date_of_birth,
        phone = NEW.phone,
        state = NEW.state,
        city = NEW.city,
        gender = NEW.gender,
        raca_cor = NEW.race,
        updated_at = now()
      WHERE id = v_member_id;

      -- Determina o nome para exibição na carteirinha
      IF NEW.social_name IS NOT NULL AND btrim(NEW.social_name) <> '' THEN
        v_card_name := btrim(NEW.social_name);
      ELSE
        v_card_name := btrim(NEW.name);
      END IF;

      -- Atualiza apenas o front_data.name em digital_cards, preservando as demais chaves
      UPDATE public.digital_cards
      SET
        front_data = jsonb_set(COALESCE(front_data, '{}'::jsonb), '{name}', to_jsonb(v_card_name)),
        updated_at = now()
      WHERE member_id = v_member_id AND user_id = NEW.id;
    END IF;

  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.conectea_sync_profile_holder_v1() IS 'Sincroniza atomicamente as edições de perfil do titular com a tabela members e digital_cards correspondentes.';

-- Criar a trigger AFTER UPDATE
DROP TRIGGER IF EXISTS tr_conectea_sync_profile_holder_v1 ON public.profiles;
CREATE TRIGGER tr_conectea_sync_profile_holder_v1
  AFTER UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.conectea_sync_profile_holder_v1();


-- ─────────────────────────────────────────────────────────────────────────
-- 3. RPC OFICIAL: public.conectea_update_own_profile_v1
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
  -- Validar pré-condições
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Acesso negado: usuário não autenticado.';
  END IF;

  IF p_changes IS NULL THEN
    RAISE EXCEPTION 'Erro: payload de alterações ausente.';
  END IF;

  IF p_changes = '{}'::jsonb THEN
    RAISE EXCEPTION 'Erro: nenhuma alteração enviada.';
  END IF;

  -- Validar se todas as chaves estão na allowlist permitida
  IF EXISTS (
    SELECT 1 
    FROM jsonb_object_keys(p_changes) AS k 
    WHERE k NOT IN ('name', 'social_name', 'date_of_birth', 'phone', 'state', 'city', 'gender', 'race', 'institution')
  ) THEN
    RAISE EXCEPTION 'Acesso negado: o payload contém campos não autorizados para alteração.';
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

COMMENT ON FUNCTION public.conectea_update_own_profile_v1(jsonb) IS 'RPC segura para usuários comuns atualizarem seu próprio perfil com validação server-side de allowlist.';


-- ─────────────────────────────────────────────────────────────────────────
-- 4. CONFIGURAÇÃO DE PRIVILÉGIOS DA RPC
-- ─────────────────────────────────────────────────────────────────────────
REVOKE ALL ON FUNCTION public.conectea_update_own_profile_v1(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.conectea_update_own_profile_v1(jsonb) FROM anon;
GRANT EXECUTE ON FUNCTION public.conectea_update_own_profile_v1(jsonb) TO authenticated;
