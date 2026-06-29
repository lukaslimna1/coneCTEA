-- ==============================================================================
-- MIGRATION: 20260629212000_patch_submit_cpf_correction_service_role_user_v1.sql
-- PURPOSE: Fix RPC signature to receive p_user_id from Edge and restrict access
-- ==============================================================================

-- 1. DROP the old signature to prevent its use
DROP FUNCTION IF EXISTS public.conectea_submit_cpf_correction_v1(uuid, text, text);

-- 2. CREATE the function with the new signature
CREATE OR REPLACE FUNCTION public.conectea_submit_cpf_correction_v1(
  p_request_id uuid,
  p_user_id uuid,
  p_new_cpf_clear text,
  p_new_cpf_hmac text
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_temp'
AS $function$
DECLARE
  v_request record;
  v_now timestamptz;
  v_clean_cpf text;
  v_profile_cpf text;
  v_conflict_profile_exists boolean;
  v_conflict_member_exists boolean;

  -- Variáveis de CPF matemático
  v_digits integer[];
  v_sum1 integer := 0;
  v_sum2 integer := 0;
  v_digit1 integer;
  v_digit2 integer;
  v_all_equal boolean := true;
BEGIN
  IF p_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'unauthenticated'
    );
  END IF;

  IF p_request_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  -- Buscar e bloquear a solicitação
  SELECT id, user_id, type, status, holder_deadline_exclusive_at 
  INTO v_request
  FROM public.account_change_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND OR v_request.user_id <> p_user_id THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'forbidden'
    );
  END IF;

  IF v_request.type <> 'cpf'::public.account_change_type THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_type'
    );
  END IF;

  IF v_request.status <> 'waiting_cpf_correction'::public.account_change_status THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status'
    );
  END IF;

  v_now := now();

  -- Regra Crítica: Expiração 10 dias úteis
  IF v_now >= v_request.holder_deadline_exclusive_at THEN
    UPDATE public.account_change_requests
    SET status = 'expired'::public.account_change_status,
        closed_at = v_now,
        status_changed_at = v_now,
        updated_at = v_now
    WHERE id = p_request_id;
    
    RETURN jsonb_build_object(
      'success', false, 
      'error_code', 'expired', 
      'status', 'expired'
    );
  END IF;

  IF p_new_cpf_clear IS NULL OR p_new_cpf_hmac IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_cpf');
  END IF;

  -- Validar formato do HMAC
  IF p_new_cpf_hmac !~ '^[a-f0-9]{64}$' THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_cpf');
  END IF;

  -- Normalização do CPF solicitado (deixar apenas dígitos)
  v_clean_cpf := regexp_replace(p_new_cpf_clear, '[^0-9]', '', 'g');

  IF length(v_clean_cpf) <> 11 THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_cpf');
  END IF;

  -- Validação matemática do CPF (Dígitos Verificadores)
  FOR i IN 1..11 LOOP
    v_digits[i] := substring(v_clean_cpf FROM i FOR 1)::integer;
    IF i > 1 AND v_digits[i] <> v_digits[i-1] THEN
      v_all_equal := false;
    END IF;
  END LOOP;

  IF v_all_equal THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_cpf');
  END IF;

  -- Primeiro dígito verificador (pesos 10 a 2)
  FOR i IN 1..9 LOOP
    v_sum1 := v_sum1 + v_digits[i] * (11 - i);
  END LOOP;
  v_digit1 := 11 - (v_sum1 % 11);
  IF v_digit1 >= 10 THEN
    v_digit1 := 0;
  END IF;

  -- Segundo dígito verificador (pesos 11 a 2)
  FOR i IN 1..10 LOOP
    v_sum2 := v_sum2 + v_digits[i] * (12 - i);
  END LOOP;
  v_digit2 := 11 - (v_sum2 % 11);
  IF v_digit2 >= 10 THEN
    v_digit2 := 0;
  END IF;

  IF v_digit1 <> v_digits[10] OR v_digit2 <> v_digits[11] THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_cpf');
  END IF;

  -- Impedir CPF solicitado igual ao CPF atual da conta
  SELECT cpf INTO v_profile_cpf FROM public.profiles WHERE id = p_user_id;
  IF v_profile_cpf IS NOT NULL AND regexp_replace(v_profile_cpf, '[^0-9]', '', 'g') = v_clean_cpf THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'cpf_unchanged');
  END IF;

  -- Verificar se o CPF solicitado já existe cadastrado em outros perfis
  SELECT EXISTS (
    SELECT 1 
    FROM public.profiles 
    WHERE id <> p_user_id 
      AND cpf IS NOT NULL 
      AND regexp_replace(cpf, '[^0-9]', '', 'g') = v_clean_cpf
  ) INTO v_conflict_profile_exists;

  IF v_conflict_profile_exists THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'cpf_conflict');
  END IF;

  -- Verificar se o CPF solicitado já existe cadastrado em dependentes
  SELECT EXISTS (
    SELECT 1 
    FROM public.members 
    WHERE cpf IS NOT NULL 
      AND regexp_replace(cpf, '[^0-9]', '', 'g') = v_clean_cpf
  ) INTO v_conflict_member_exists;

  IF v_conflict_member_exists THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'cpf_conflict');
  END IF;

  -- Atualiza reservation (reescreve in-place para que constraints UNIQUE avaliem o novo HMAC e liberem o antigo)
  UPDATE private.account_change_cpf_reservations
  SET new_cpf_hmac = p_new_cpf_hmac,
      updated_at = v_now
  WHERE request_id = p_request_id;

  -- Atualiza review_data
  UPDATE private.account_change_review_data
  SET new_cpf_clear = v_clean_cpf
  WHERE request_id = p_request_id;

  -- Atualiza solicitação de volta para under_review
  UPDATE public.account_change_requests
  SET new_value_masked = '***.***.***-' || SUBSTRING(v_clean_cpf FROM 10 FOR 2),
      new_value_hmac = p_new_cpf_hmac,
      status = 'under_review'::public.account_change_status,
      holder_deadline_started_at = NULL,
      holder_deadline_exclusive_at = NULL,
      admin_deadline_started_at = v_now,
      admin_deadline_exclusive_at = public.conectea_account_change_admin_deadline_v1(v_now),
      status_changed_at = v_now,
      updated_at = v_now
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'status', 'under_review',
    'request_id', p_request_id
  );

EXCEPTION
  WHEN unique_violation THEN
    -- Pode acontecer se o novo HMAC já está reservado em outra solicitação
    RETURN jsonb_build_object('success', false, 'error_code', 'cpf_conflict');
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'internal_error'
    );
END;
$function$;

-- 3. GRANTS
REVOKE ALL ON FUNCTION public.conectea_submit_cpf_correction_v1(uuid, uuid, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.conectea_submit_cpf_correction_v1(uuid, uuid, text, text) FROM anon;
REVOKE ALL ON FUNCTION public.conectea_submit_cpf_correction_v1(uuid, uuid, text, text) FROM authenticated;

GRANT EXECUTE ON FUNCTION public.conectea_submit_cpf_correction_v1(uuid, uuid, text, text) TO service_role;

-- 4. COMMENT
COMMENT ON FUNCTION public.conectea_submit_cpf_correction_v1(uuid, uuid, text, text) IS 'Função interna; chamada apenas via Edge submit-cpf-correction. HMAC calculado server-side. p_user_id deve vir do JWT validado pela Edge.';
