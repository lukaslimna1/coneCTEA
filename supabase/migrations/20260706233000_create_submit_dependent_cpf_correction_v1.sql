-- =========================================================================
-- ConeCTEA — Submissão de Correção de CPF de Dependente pelo Usuário Titular
--
-- MIGRATION: 20260706233000_create_submit_dependent_cpf_correction_v1.sql
-- OBJETIVO:
--   - Criar a RPC public.conectea_submit_dependent_cpf_correction_v1.
--   - Permitir ao usuário titular responder ao status waiting_cpf_correction.
--   - Garantir validação de CPF, restrições de concorrência e conformidade com LGPD.
-- =========================================================================

CREATE OR REPLACE FUNCTION public.conectea_submit_dependent_cpf_correction_v1(
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
  v_member record;
  v_reservation record;
  v_review_id uuid;
  v_now timestamptz;
  v_clean_cpf text;
  v_parent_cpf text;
  v_parent_cpf_normalized text;
  v_conflict_member_exists boolean;
  v_active_reservation_exists boolean;

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

  -- 1. Buscar e bloquear a solicitação pública (FOR UPDATE)
  SELECT id, user_id, member_id, status, expires_at 
  INTO v_request
  FROM public.dependent_cpf_change_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'not_found'
    );
  END IF;

  -- Validar posse (pertence ao titular que submeteu)
  IF v_request.user_id <> p_user_id THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'forbidden'
    );
  END IF;

  -- 2. Validar status da solicitação
  IF v_request.status <> 'waiting_cpf_correction' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status'
    );
  END IF;

  v_now := now();

  -- 3. Validar expiração do prazo do titular (se aplicável)
  IF v_request.expires_at IS NOT NULL AND v_now >= v_request.expires_at THEN
    -- Transiciona para expirado in-place
    UPDATE public.dependent_cpf_change_requests
    SET 
      status = 'expired',
      updated_at = v_now
    WHERE id = p_request_id;

    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'expired',
      'status', 'expired'
    );
  END IF;

  -- 4. Validar parâmetros de CPF
  IF p_new_cpf_clear IS NULL OR p_new_cpf_hmac IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_cpf'
    );
  END IF;

  -- Validar formato do HMAC
  IF p_new_cpf_hmac !~ '^[a-f0-9]{64}$' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_cpf'
    );
  END IF;

  -- Normalização do CPF solicitado (deixar apenas dígitos)
  v_clean_cpf := regexp_replace(p_new_cpf_clear, '[^0-9]', '', 'g');

  IF length(v_clean_cpf) <> 11 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_cpf'
    );
  END IF;

  -- 5. Validação matemática do CPF (Dígitos Verificadores)
  FOR i IN 1..11 LOOP
    v_digits[i] := substring(v_clean_cpf FROM i FOR 1)::integer;
    IF i > 1 AND v_digits[i] <> v_digits[i-1] THEN
      v_all_equal := false;
    END IF;
  END LOOP;

  IF v_all_equal THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_cpf'
    );
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
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_cpf'
    );
  END IF;

  -- 6. Buscar e travar o dependente (FOR UPDATE)
  SELECT id, user_id, status, cpf 
  INTO v_member
  FROM public.members
  WHERE id = v_request.member_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'member_not_found'
    );
  END IF;

  -- Validar se o dependente pertence ao titular correto
  IF v_member.user_id <> p_user_id THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'forbidden'
    );
  END IF;

  -- Validar se o dependente está em status ativo/aprovado
  IF v_member.status NOT IN ('active', 'approved') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  -- Impedir CPF solicitado igual ao CPF atual do próprio dependente
  IF v_member.cpf IS NOT NULL AND regexp_replace(v_member.cpf, '[^0-9]', '', 'g') = v_clean_cpf THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_cpf'
    );
  END IF;

  -- 7. Validar conflito com o CPF do titular responsável da conta (parent)
  SELECT cpf INTO v_parent_cpf
  FROM public.profiles
  WHERE id = p_user_id;

  v_parent_cpf_normalized := COALESCE(regexp_replace(v_parent_cpf, '[^0-9]', '', 'g'), '');

  IF v_clean_cpf = v_parent_cpf_normalized THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'account_cpf_conflict'
    );
  END IF;

  -- 8. Validar conflito com CPF de outro dependente (members)
  SELECT EXISTS (
    SELECT 1 
    FROM public.members 
    WHERE id <> v_request.member_id
      AND cpf IS NOT NULL 
      AND regexp_replace(cpf, '[^0-9]', '', 'g') = v_clean_cpf
  ) INTO v_conflict_member_exists;

  IF v_conflict_member_exists THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'cpf_in_use'
    );
  END IF;

  -- 9. Validar se já existe reserva ativa do novo CPF solicitado por HMAC em outra solicitação
  SELECT EXISTS (
    SELECT 1
    FROM private.dependent_cpf_change_reservations
    WHERE request_id <> p_request_id
      AND new_cpf_hmac = p_new_cpf_hmac
      AND reservation_state = 'attached'
  ) INTO v_active_reservation_exists;

  IF v_active_reservation_exists THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'cpf_in_use'
    );
  END IF;

  -- 10. Buscar e travar review_data (FOR UPDATE)
  SELECT request_id
  INTO v_review_id
  FROM private.dependent_cpf_change_review_data
  WHERE request_id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  -- 11. Buscar e travar reserva (FOR UPDATE)
  SELECT id, request_id, member_id, reservation_state, released_at
  INTO v_reservation
  FROM private.dependent_cpf_change_reservations
  WHERE request_id = p_request_id
  FOR UPDATE;

  IF NOT FOUND OR v_reservation.member_id <> v_request.member_id OR v_reservation.reservation_state <> 'attached' OR v_reservation.released_at IS NOT NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'reservation_unavailable'
    );
  END IF;

  -- 12. Atualizar dados de review privados
  UPDATE private.dependent_cpf_change_review_data
  SET 
    new_cpf_clear = v_clean_cpf,
    updated_at = v_now
  WHERE request_id = p_request_id;

  -- 13. Atualizar a reserva de CPF por HMAC in-place
  UPDATE private.dependent_cpf_change_reservations
  SET 
    new_cpf_hmac = p_new_cpf_hmac,
    updated_at = v_now
  WHERE request_id = p_request_id;

  -- 14. Atualizar a solicitação pública de dependente
  UPDATE public.dependent_cpf_change_requests
  SET 
    status = 'under_review',
    requested_cpf_masked = '***.***.***-' || SUBSTRING(v_clean_cpf FROM 10 FOR 2),
    admin_feedback = NULL,
    expires_at = public.conectea_account_change_admin_deadline_v1(v_now),
    updated_at = v_now
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'status', 'under_review',
    'message', 'CPF corrigido enviado para análise.'
  );

EXCEPTION 
  WHEN unique_violation THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'cpf_in_use'
    );
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'internal_error'
    );
END;
$function$;

-- Revogar execução pública padrão
REVOKE ALL ON FUNCTION public.conectea_submit_dependent_cpf_correction_v1(uuid, uuid, text, text) FROM PUBLIC, anon, authenticated;

-- Conceder execução exclusiva a service_role (chamado via Edge Function)
GRANT EXECUTE ON FUNCTION public.conectea_submit_dependent_cpf_correction_v1(uuid, uuid, text, text) TO service_role;

-- Comentário explicativo
COMMENT ON FUNCTION public.conectea_submit_dependent_cpf_correction_v1(uuid, uuid, text, text) IS
  'Chamado via Edge Function submit-dependent-cpf-correction para que o titular corrija o CPF do dependente (status under_review).';
