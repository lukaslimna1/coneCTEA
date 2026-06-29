-- =========================================================================
-- ConeCTEA — Correções de Auditoria Codex na Confirmação de CPF
--
-- MIGRATION: 20260628202000_fix_confirm_cpf_change_request_contract_v1.sql
-- OBJETIVO:
--   1. Criar bypass seguro (via set_config) no trigger de profiles para a RPC.
--   2. Atualizar chk_conectea_change_closure para application_failed ser fechada.
--   3. Atualizar active index para excluir application_failed.
--   4. Atualizar RPC get_my_active_cpf_account_change_v1 para excluir application_failed.
--   5. Recriar conectea_confirm_cpf_change_request_v1 com closed_at e prazos limpos em application_failed, 
--      e comparação de CPF normalizada na atualização de members.
--   6. Revogar privilégios PUBLIC de funções privadas de limpeza.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. BYPASS SEGURO NO TRIGGER DE PROTEÇÃO DE PERFIL
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
  v_bypass_cpf text;
BEGIN
  -- Lê a flag de bypass transacional para a coluna CPF
  v_bypass_cpf := current_setting('conectea.bypass_cpf_protection', true);

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
    IF EXISTS (
      SELECT 1 
      FROM jsonb_each(to_jsonb(NEW)) AS n(key, val)
      LEFT JOIN jsonb_each(to_jsonb(OLD)) AS o(key, val) ON n.key = o.key
      WHERE n.val IS DISTINCT FROM o.val
        AND n.key NOT IN ('name', 'social_name', 'date_of_birth', 'phone', 'state', 'city', 'gender', 'race', 'institution')
        AND NOT (n.key = 'cpf' AND v_bypass_cpf = 'true')
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
    IF NEW.name IS NULL OR NEW.name = '' THEN
      RAISE EXCEPTION 'O nome completo é obrigatório.';
    END IF;
    IF length(NEW.name) < 3 THEN
      RAISE EXCEPTION 'O nome completo deve conter no mínimo 3 caracteres.';
    END IF;
    IF length(NEW.name) > 100 THEN
      RAISE EXCEPTION 'O nome completo deve conter no máximo 100 caracteres.';
    END IF;

    IF NEW.state IS NULL OR NEW.state = '' THEN
      RAISE EXCEPTION 'O estado é obrigatório.';
    END IF;
    IF length(NEW.state) < 2 THEN
      RAISE EXCEPTION 'O estado deve conter no mínimo 2 caracteres.';
    END IF;
    IF length(NEW.state) > 50 THEN
      RAISE EXCEPTION 'O estado deve conter no máximo 50 caracteres.';
    END IF;

    IF NEW.city IS NULL OR NEW.city = '' THEN
      RAISE EXCEPTION 'A cidade é obrigatória.';
    END IF;
    IF length(NEW.city) < 2 THEN
      RAISE EXCEPTION 'A cidade deve conter no mínimo 2 caracteres.';
    END IF;
    IF length(NEW.city) > 100 THEN
      RAISE EXCEPTION 'A cidade deve conter no máximo 100 caracteres.';
    END IF;

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

-- ─────────────────────────────────────────────────────────────────────────
-- 2. AJUSTE DA CONSTRAINT DE FECHAMENTO PARA APPLICATION_FAILED
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.account_change_requests
  DROP CONSTRAINT IF EXISTS chk_conectea_change_closure;

ALTER TABLE public.account_change_requests
  ADD CONSTRAINT chk_conectea_change_closure CHECK (
    (status IN (
      'completed'::public.account_change_status,
      'rejected_by_admin'::public.account_change_status,
      'cancelled_by_holder'::public.account_change_status,
      'expired'::public.account_change_status,
      'application_failed'::public.account_change_status
    ) AND closed_at IS NOT NULL) OR
    (status IN (
      'under_review'::public.account_change_status,
      'waiting_document_replacement'::public.account_change_status,
      'waiting_cpf_correction'::public.account_change_status,
      'waiting_holder_confirmation'::public.account_change_status,
      'applying'::public.account_change_status
    ) AND closed_at IS NULL)
  );

-- ─────────────────────────────────────────────────────────────────────────
-- 3. AJUSTE DO ÍNDICE ATIVO PARA EXCLUIR APPLICATION_FAILED
-- ─────────────────────────────────────────────────────────────────────────
DROP INDEX IF EXISTS public.account_change_requests_active_idx;

CREATE UNIQUE INDEX account_change_requests_active_idx
  ON public.account_change_requests (user_id, type)
  WHERE status IN (
    'under_review',
    'waiting_document_replacement',
    'waiting_cpf_correction',
    'waiting_holder_confirmation',
    'applying'
  );

-- ─────────────────────────────────────────────────────────────────────────
-- 4. AJUSTE DA RPC DE REQUISIÇÃO ATIVA
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_get_my_active_cpf_account_change_v1()
RETURNS TABLE (
  id uuid,
  protocol_number text,
  type public.account_change_type,
  status public.account_change_status,
  old_value_masked text,
  new_value_masked text,
  created_at timestamp with time zone,
  updated_at timestamp with time zone,
  application_completed_at timestamp with time zone,
  status_changed_at timestamp with time zone,
  holder_deadline_due_date date,
  closed_at timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Acesso negado: usuário não autenticado.' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    cr.id, cr.protocol_number, cr.type, cr.status, cr.old_value_masked, cr.new_value_masked,
    cr.created_at, cr.updated_at, cr.application_completed_at, cr.status_changed_at,
    CASE 
      WHEN cr.holder_deadline_exclusive_at IS NULL THEN NULL
      ELSE (cr.holder_deadline_exclusive_at AT TIME ZONE 'America/Sao_Paulo')::date - 1
    END AS holder_deadline_due_date,
    cr.closed_at
  FROM public.account_change_requests cr
  WHERE cr.user_id = auth.uid()
    AND cr.type = 'cpf'::public.account_change_type
    AND cr.status IN (
      'under_review'::public.account_change_status,
      'waiting_document_replacement'::public.account_change_status,
      'waiting_cpf_correction'::public.account_change_status,
      'waiting_holder_confirmation'::public.account_change_status,
      'applying'::public.account_change_status
    )
  ORDER BY cr.created_at DESC, cr.id DESC
  LIMIT 1;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 5. RECRIAÇÃO DA RPC DE CONFIRMAÇÃO COM SEGURANÇA E TERMINALIDADE
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.conectea_confirm_cpf_change_request_v1(
  p_request_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $$
DECLARE
  v_caller_id uuid;
  v_status public.account_change_status;
  v_type public.account_change_type;
  v_user_id uuid;
  v_deadline timestamptz;
  v_now timestamptz;
  v_old_cpf_clear text;
  v_new_cpf_clear text;
  v_current_cpf text;
BEGIN
  -- 1. Validar autenticacao
  v_caller_id := auth.uid();
  IF v_caller_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'unauthenticated');
  END IF;

  IF p_request_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_parameters');
  END IF;

  v_now := transaction_timestamp();

  -- 2. Buscar e bloquear a requisicao para evitar concorrencia (FOR UPDATE)
  SELECT status, type, user_id, holder_deadline_exclusive_at
  INTO v_status, v_type, v_user_id, v_deadline
  FROM public.account_change_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'not_found');
  END IF;

  IF v_type <> 'cpf'::public.account_change_type THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_type');
  END IF;

  IF v_user_id <> v_caller_id THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'forbidden');
  END IF;

  IF v_status <> 'waiting_holder_confirmation'::public.account_change_status THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_status');
  END IF;

  IF v_deadline IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'internal_error');
  END IF;

  IF v_now >= v_deadline THEN
    UPDATE public.account_change_requests
    SET status = 'expired'::public.account_change_status,
        resolution_reason = 'holder_confirmation_deadline'::public.account_change_resolution_reason,
        closed_at = v_now,
        status_changed_at = v_now,
        updated_at = v_now,
        admin_deadline_started_at = NULL,
        admin_deadline_exclusive_at = NULL,
        holder_deadline_started_at = NULL,
        holder_deadline_exclusive_at = NULL
    WHERE id = p_request_id;
    RETURN jsonb_build_object('success', false, 'error_code', 'expired');
  END IF;

  -- Ler dados puros e sensiveis da tabela de auditoria privada
  SELECT old_cpf_clear, new_cpf_clear
  INTO v_old_cpf_clear, v_new_cpf_clear
  FROM private.account_change_review_data
  WHERE request_id = p_request_id;

  IF NOT FOUND OR v_old_cpf_clear IS NULL OR v_new_cpf_clear IS NULL THEN
    UPDATE public.account_change_requests
    SET status = 'application_failed'::public.account_change_status,
        failure_code = 'missing_review_data',
        closed_at = transaction_timestamp(),
        status_changed_at = transaction_timestamp(),
        updated_at = transaction_timestamp(),
        admin_deadline_started_at = NULL,
        admin_deadline_exclusive_at = NULL,
        holder_deadline_started_at = NULL,
        holder_deadline_exclusive_at = NULL
    WHERE id = p_request_id;
    RETURN jsonb_build_object('success', false, 'error_code', 'missing_review_data');
  END IF;

  IF length(v_old_cpf_clear) <> 11 OR v_old_cpf_clear !~ '^[0-9]+$' OR
     length(v_new_cpf_clear) <> 11 OR v_new_cpf_clear !~ '^[0-9]+$' THEN
    UPDATE public.account_change_requests
    SET status = 'application_failed'::public.account_change_status,
        failure_code = 'invalid_cpf_data',
        closed_at = transaction_timestamp(),
        status_changed_at = transaction_timestamp(),
        updated_at = transaction_timestamp(),
        admin_deadline_started_at = NULL,
        admin_deadline_exclusive_at = NULL,
        holder_deadline_started_at = NULL,
        holder_deadline_exclusive_at = NULL
    WHERE id = p_request_id;
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_cpf_data');
  END IF;

  -- Muda status para applying para garantir logs transacionais
  UPDATE public.account_change_requests
  SET status = 'applying'::public.account_change_status,
      status_changed_at = v_now,
      application_started_at = v_now,
      holder_confirmed_at = v_now,
      updated_at = v_now,
      admin_deadline_started_at = NULL,
      admin_deadline_exclusive_at = NULL,
      holder_deadline_started_at = NULL,
      holder_deadline_exclusive_at = NULL
  WHERE id = p_request_id;

  -- Bloquear e validar CPF atual
  SELECT regexp_replace(coalesce(cpf, ''), '[^0-9]', '', 'g') INTO v_current_cpf
  FROM public.profiles
  WHERE id = v_user_id
  FOR UPDATE;

  IF v_current_cpf IS DISTINCT FROM v_old_cpf_clear THEN
    UPDATE public.account_change_requests
    SET status = 'application_failed'::public.account_change_status,
        failure_code = 'current_cpf_mismatch',
        closed_at = transaction_timestamp(),
        status_changed_at = transaction_timestamp(),
        updated_at = transaction_timestamp()
    WHERE id = p_request_id;
    RETURN jsonb_build_object('success', false, 'error_code', 'current_cpf_mismatch');
  END IF;

  BEGIN
    -- Permitir o bypass da protecao do perfil localmente
    PERFORM set_config('conectea.bypass_cpf_protection', 'true', true);

    -- Atualiza Profiles (Base)
    UPDATE public.profiles
    SET cpf = v_new_cpf_clear
    WHERE id = v_user_id;

    -- Atualiza Members (uso de expressao regular compativel com null-safety)
    UPDATE public.members
    SET cpf = v_new_cpf_clear
    WHERE user_id = v_user_id AND regexp_replace(coalesce(cpf, ''), '[^0-9]', '', 'g') = v_old_cpf_clear;

    UPDATE public.account_change_requests
    SET status = 'completed'::public.account_change_status,
        closed_at = transaction_timestamp(),
        status_changed_at = transaction_timestamp(),
        application_completed_at = transaction_timestamp(),
        updated_at = transaction_timestamp()
    WHERE id = p_request_id;

    RETURN jsonb_build_object('success', true, 'request_id', p_request_id, 'status', 'completed');

  EXCEPTION WHEN unique_violation THEN
    UPDATE public.account_change_requests
    SET status = 'application_failed'::public.account_change_status,
        failure_code = 'cpf_conflict',
        closed_at = transaction_timestamp(),
        status_changed_at = transaction_timestamp(),
        updated_at = transaction_timestamp()
    WHERE id = p_request_id;
    RETURN jsonb_build_object('success', false, 'error_code', 'cpf_conflict');
  WHEN OTHERS THEN
    UPDATE public.account_change_requests
    SET status = 'application_failed'::public.account_change_status,
        failure_code = 'internal_error',
        closed_at = transaction_timestamp(),
        status_changed_at = transaction_timestamp(),
        updated_at = transaction_timestamp()
    WHERE id = p_request_id;
    RETURN jsonb_build_object('success', false, 'error_code', 'internal_error');
  END;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 6. REVOGAÇÃO DE ACESSO PÚBLICO ÀS FUNÇÕES PRIVADAS (SECURING)
-- ─────────────────────────────────────────────────────────────────────────
REVOKE ALL ON FUNCTION private.conectea_release_cpf_reservation_on_final_status_v1() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.conectea_clear_account_change_review_data_v1(uuid, text) FROM PUBLIC, anon;

