-- =========================================================================
-- ConeCTEA — RPC Interna de Criação de Solicitação de Revisão de CPF
--
-- MIGRATION: 20260623190000_create_cpf_change_request_rpc_v1.sql
-- OBJETIVO:
--   - Criar a função interna private.conectea_create_cpf_change_request_v1.
--   - Permitir que a futura Edge Function crie solicitações de alteração de CPF
--     de forma transacional, atômica e segura.
--
-- PRIVACIDADE E SEGURANÇA:
--   - A função é SECURITY DEFINER e restrita estritamente a service_role.
--   - Grants para PUBLIC, anon e authenticated são revogados por completo.
--   - O search_path é blindado contra hijack: pg_catalog, public, private, pg_temp.
--   - O CPF puro recebido temporariamente na transação serve apenas para validação
--     relacional em memória e é imediatamente descartado, nunca sendo persistido.
-- =========================================================================

CREATE OR REPLACE FUNCTION private.conectea_create_cpf_change_request_v1(
  p_user_id uuid,
  p_new_cpf_clear text,
  p_new_cpf_hmac text,
  p_justification text,
  p_ciphertext text,
  p_nonce text,
  p_auth_tag text,
  p_algorithm text,
  p_key_version integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $$
DECLARE
  v_now timestamptz;
  v_clean_cpf text;
  v_profile_exists boolean;
  v_profile_cpf text;
  v_active_exists boolean;
  v_conflict_profile_exists boolean;
  v_conflict_member_exists boolean;
  
  -- Variáveis de CPF matemático
  v_digits integer[];
  v_sum1 integer := 0;
  v_sum2 integer := 0;
  v_digit1 integer;
  v_digit2 integer;
  v_all_equal boolean := true;
  
  -- Variáveis de inserção
  v_request_id uuid;
  v_protocol_number text;
BEGIN
  -- 1. Validação de Parâmetros de Entrada
  IF p_user_id IS NULL
     OR p_new_cpf_clear IS NULL
     OR p_new_cpf_hmac IS NULL
     OR p_ciphertext IS NULL OR trim(both from p_ciphertext) = ''
     OR p_nonce IS NULL OR trim(both from p_nonce) = ''
     OR p_auth_tag IS NULL OR trim(both from p_auth_tag) = ''
     OR p_algorithm IS NULL OR trim(both from p_algorithm) = ''
     OR p_key_version IS NULL
  THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- Validação estrita do algoritmo e versão de chave baseados no padrão real do email
  IF p_algorithm <> 'aes-256-gcm' OR p_key_version <> 1 THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  v_now := transaction_timestamp();

  -- 2. Normalização do CPF solicitado (deixar apenas dígitos)
  v_clean_cpf := regexp_replace(p_new_cpf_clear, '[^0-9]', '', 'g');

  IF length(v_clean_cpf) <> 11 THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- 3. Validação matemática do CPF (Dígitos Verificadores)
  FOR i IN 1..11 LOOP
    v_digits[i] := substring(v_clean_cpf FROM i FOR 1)::integer;
    IF i > 1 AND v_digits[i] <> v_digits[i-1] THEN
      v_all_equal := false;
    END IF;
  END LOOP;

  IF v_all_equal THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
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
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- 4. Validar formato do HMAC (64 caracteres hexadecimal em lowercase)
  IF p_new_cpf_hmac !~ '^[a-f0-9]{64}$' THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- 5. Lock pessimista sobre o perfil do usuário para evitar concorrência
  SELECT true, cpf INTO v_profile_exists, v_profile_cpf
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_profile_exists IS NOT TRUE THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- 6. Impedir CPF solicitado igual ao CPF atual da conta
  IF v_profile_cpf IS NOT NULL AND regexp_replace(v_profile_cpf, '[^0-9]', '', 'g') = v_clean_cpf THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- 7. Verificar se o CPF solicitado já existe cadastrado em outros perfis (profiles)
  SELECT EXISTS (
    SELECT 1 
    FROM public.profiles 
    WHERE id <> p_user_id 
      AND cpf IS NOT NULL 
      AND regexp_replace(cpf, '[^0-9]', '', 'g') = v_clean_cpf
  ) INTO v_conflict_profile_exists;

  IF v_conflict_profile_exists THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- 8. Verificar se o CPF solicitado já existe cadastrado em dependentes (members)
  -- NOTA: Validação global de exclusividade
  SELECT EXISTS (
    SELECT 1 
    FROM public.members 
    WHERE cpf IS NOT NULL 
      AND regexp_replace(cpf, '[^0-9]', '', 'g') = v_clean_cpf
  ) INTO v_conflict_member_exists;

  IF v_conflict_member_exists THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- 9. Verificar se já existe solicitação ativa de alteração de CPF para o usuário
  SELECT EXISTS (
    SELECT 1 
    FROM public.account_change_requests
    WHERE user_id = p_user_id
      AND type = 'cpf'::public.account_change_type
      AND status IN (
        'under_review'::public.account_change_status,
        'waiting_document_replacement'::public.account_change_status,
        'waiting_cpf_correction'::public.account_change_status,
        'waiting_holder_confirmation'::public.account_change_status,
        'applying'::public.account_change_status,
        'application_failed'::public.account_change_status
      )
  ) INTO v_active_exists;

  IF v_active_exists THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'active_request_exists');
  END IF;

  -- 10. Geração do ID do protocolo
  v_request_id := gen_random_uuid();

  -- 11. Inserção na tabela pública de solicitações
  -- O trigger 'tr_account_change_requests_protocol' cuidará da geração automática do protocol_number
  INSERT INTO public.account_change_requests (
    id,
    user_id,
    type,
    status,
    old_value_masked,
    new_value_masked,
    new_value_hmac,
    justification,
    document_state,
    document_reference,
    admin_deadline_started_at,
    admin_deadline_exclusive_at,
    holder_deadline_started_at,
    holder_deadline_exclusive_at,
    created_at,
    updated_at
  ) VALUES (
    v_request_id,
    p_user_id,
    'cpf'::public.account_change_type,
    'under_review'::public.account_change_status,
    CASE 
      WHEN v_profile_cpf IS NOT NULL AND v_profile_cpf <> '' THEN 
        CASE 
          WHEN length(regexp_replace(v_profile_cpf, '[^0-9]', '', 'g')) = 11 THEN
            '***.***.***-' || SUBSTRING(regexp_replace(v_profile_cpf, '[^0-9]', '', 'g') FROM 10 FOR 2)
          ELSE '***.***.***-**'
        END
      ELSE '***.***.***-**' 
    END,
    '***.***.***-' || SUBSTRING(v_clean_cpf FROM 10 FOR 2),
    p_new_cpf_hmac,
    NULL, -- p_justification não é persistido em tabela pública por segurança de dados/PII
    'pending_review',
    NULL,
    v_now,
    public.conectea_account_change_admin_deadline_v1(v_now),
    NULL,
    NULL,
    v_now,
    v_now
  )
  RETURNING protocol_number INTO v_protocol_number;

  -- 12. Inserção do payload privado criptografado
  INSERT INTO private.account_change_secure_payloads (
    request_id,
    ciphertext,
    nonce,
    auth_tag,
    algorithm,
    key_version,
    created_at,
    updated_at
  ) VALUES (
    v_request_id,
    p_ciphertext,
    p_nonce,
    p_auth_tag,
    p_algorithm,
    p_key_version,
    v_now,
    v_now
  );

  -- 13. Inserção da reserva de CPF por HMAC
  INSERT INTO private.account_change_cpf_reservations (
    request_id,
    user_id,
    request_type,
    new_cpf_hmac,
    new_cpf_hmac_key_version,
    reservation_state,
    released_at,
    created_at,
    updated_at
  ) VALUES (
    v_request_id,
    p_user_id,
    'cpf'::public.account_change_type,
    p_new_cpf_hmac,
    1,
    'attached',
    NULL,
    v_now,
    v_now
  );

  RETURN jsonb_build_object(
    'success', true,
    'request_id', v_request_id,
    'protocol_number', v_protocol_number
  );

EXCEPTION
  WHEN unique_violation THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'unavailable');
  WHEN foreign_key_violation THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'internal_error');
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- SEGURANÇA: CONTROLE DE GRANTS (PRIVILÉGIOS MÍNIMOS)
-- ─────────────────────────────────────────────────────────────────────────

-- Revogação total de privilégios públicos padrão
REVOKE ALL ON FUNCTION private.conectea_create_cpf_change_request_v1(
  uuid, text, text, text, text, text, text, text, integer
) FROM PUBLIC, anon, authenticated;

-- Concessão de execução exclusiva para o service_role
GRANT EXECUTE ON FUNCTION private.conectea_create_cpf_change_request_v1(
  uuid, text, text, text, text, text, text, text, integer
) TO service_role;

-- ─────────────────────────────────────────────────────────────────────────
-- COMENTÁRIOS DE DOCUMENTAÇÃO E SEGURANÇA
-- ─────────────────────────────────────────────────────────────────────────

COMMENT ON FUNCTION private.conectea_create_cpf_change_request_v1 IS
  'Função SQL/PLPGSQL privada restrita a service_role para criação transacional de solicitações de alteração de CPF com validação atômica de CPF, unicidade global e reserva por HMAC.';
