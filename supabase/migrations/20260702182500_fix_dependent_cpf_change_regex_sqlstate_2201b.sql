-- =========================================================================
-- ConeCTEA — Correção SQLSTATE 2201B no Fluxo de CPF de Dependente
--
-- MIGRATION: 20260702182500_fix_dependent_cpf_change_regex_sqlstate_2201b.sql
-- OBJETIVO:
--   - Corrigir o uso de {10,256} em expressões regulares que causam SQLSTATE 2201B
--     (invalid_regular_expression) porque o PostgreSQL limita repetições a 255.
--   - Alterar a constraint `chk_dep_cpf_review_doc_file_id` em
--     `private.dependent_cpf_change_review_data`
--   - Atualizar a RPC `private.conectea_create_dependent_cpf_change_request_v1`
--
-- PADRÃO DE REFERÊNCIA:
--   Migration anterior do fluxo de CPF da conta:
--   20260628133500_fix_cpf_change_request_regex_sqlstate_2201b.sql
-- =========================================================================

-- 1. CORREÇÃO DA CONSTRAINT
ALTER TABLE private.dependent_cpf_change_review_data
  DROP CONSTRAINT IF EXISTS chk_dep_cpf_review_doc_file_id;

ALTER TABLE private.dependent_cpf_change_review_data
  ADD CONSTRAINT chk_dep_cpf_review_doc_file_id CHECK (
    document_file_id IS NULL OR (
      length(document_file_id) BETWEEN 10 AND 256
      AND document_file_id ~ '^[A-Za-z0-9_-]+$'
    )
  );

-- 2. CORREÇÃO DA RPC
CREATE OR REPLACE FUNCTION private.conectea_create_dependent_cpf_change_request_v1(
  p_user_id uuid,
  p_member_id uuid,
  p_new_cpf_clear text,
  p_new_cpf_hmac text,
  p_document_file_id text,
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
  v_member_exists boolean;
  v_member_status text;
  v_member_user_id uuid;
  v_member_cpf text;
  v_parent_cpf text;
  v_active_exists boolean;
  v_active_reservation_exists boolean;
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

  -- Variáveis de diagnóstico seguro
  v_sqlstate text;
  v_constraint text;
  v_table text;
  v_column text;
  v_datatype text;

  -- Variável para normalizar o CPF atual
  v_old_cpf_normalized text;
BEGIN
  -- 1. Validação de Parâmetros de Entrada
  IF p_user_id IS NULL
     OR p_member_id IS NULL
     OR p_new_cpf_clear IS NULL
     OR p_new_cpf_hmac IS NULL
     OR p_document_file_id IS NULL
     OR length(p_document_file_id) < 10
     OR length(p_document_file_id) > 256
     OR p_document_file_id !~ '^[A-Za-z0-9_-]+$'
     OR p_ciphertext IS NULL OR trim(both from p_ciphertext) = ''
     OR p_nonce IS NULL OR trim(both from p_nonce) = ''
     OR p_auth_tag IS NULL OR trim(both from p_auth_tag) = ''
     OR p_algorithm IS NULL OR trim(both from p_algorithm) = ''
     OR p_key_version IS NULL
  THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- Validação estrita do algoritmo e versão de chave baseados no padrão real
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

  -- 5. Lock pessimista sobre o dependente (member) para evitar concorrência e validar propriedade
  SELECT true, status, user_id, cpf INTO v_member_exists, v_member_status, v_member_user_id, v_member_cpf
  FROM public.members
  WHERE id = p_member_id
  FOR UPDATE;

  IF NOT FOUND OR v_member_exists IS NOT TRUE THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'member_not_found');
  END IF;

  -- Validar se pertence ao titular autenticado
  IF v_member_user_id <> p_user_id THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'forbidden');
  END IF;

  -- Validar se member está ativo/aprovado
  IF v_member_status NOT IN ('active', 'approved') THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- Normalização de old_cpf_clear para evitar que strings vazias ou inválidas quebrem as constraints da tabela de review
  IF v_member_cpf IS NOT NULL THEN
    v_old_cpf_normalized := regexp_replace(v_member_cpf, '[^0-9]', '', 'g');
    IF length(v_old_cpf_normalized) <> 11 THEN
      v_old_cpf_normalized := NULL;
    END IF;
  ELSE
    v_old_cpf_normalized := NULL;
  END IF;

  -- 6. Impedir CPF solicitado igual ao CPF atual do próprio dependente (se preenchido e válido)
  IF v_old_cpf_normalized IS NOT NULL AND v_old_cpf_normalized = v_clean_cpf THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- 7. Impedir CPF solicitado igual ao CPF da conta do titular (parent)
  SELECT cpf INTO v_parent_cpf
  FROM public.profiles
  WHERE id = p_user_id;

  IF v_parent_cpf IS NOT NULL AND regexp_replace(v_parent_cpf, '[^0-9]', '', 'g') = v_clean_cpf THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'account_cpf_flow_required');
  END IF;

  -- Impedir que o fluxo de CPF de dependente seja usado quando o CPF atual do member for igual ao CPF da conta (titular)
  IF v_old_cpf_normalized IS NOT NULL AND v_parent_cpf IS NOT NULL AND
     v_old_cpf_normalized = regexp_replace(v_parent_cpf, '[^0-9]', '', 'g') THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'account_cpf_flow_required');
  END IF;

  -- 8. Verificar se o CPF solicitado já existe cadastrado em outros dependentes (members)
  SELECT EXISTS (
    SELECT 1 
    FROM public.members 
    WHERE id <> p_member_id
      AND cpf IS NOT NULL 
      AND regexp_replace(cpf, '[^0-9]', '', 'g') = v_clean_cpf
  ) INTO v_conflict_member_exists;

  IF v_conflict_member_exists THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- 9. Verificar se já existe solicitação ativa de alteração de CPF para o dependente
  SELECT EXISTS (
    SELECT 1 
    FROM public.dependent_cpf_change_requests
    WHERE member_id = p_member_id
      AND status IN (
        'under_review',
        'waiting_document_replacement',
        'waiting_cpf_correction',
        'applying',
        'application_failed'
      )
  ) INTO v_active_exists;

  IF v_active_exists THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'active_request_exists');
  END IF;

  -- 10. Verificar se já existe reserva ativa do CPF solicitado por HMAC
  SELECT EXISTS (
    SELECT 1
    FROM private.dependent_cpf_change_reservations
    WHERE new_cpf_hmac = p_new_cpf_hmac
      AND reservation_state = 'attached'
  ) INTO v_active_reservation_exists;

  IF v_active_reservation_exists THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'unavailable');
  END IF;

  -- 11. Geração do ID do protocolo
  v_request_id := gen_random_uuid();

  -- 12. Inserção na tabela pública de solicitações
  INSERT INTO public.dependent_cpf_change_requests (
    id,
    user_id,
    member_id,
    status,
    protocol_number,
    current_cpf_masked,
    requested_cpf_masked,
    document_reference_masked,
    admin_feedback,
    expires_at,
    created_at,
    updated_at
  ) VALUES (
    v_request_id,
    p_user_id,
    p_member_id,
    'under_review',
    '', -- será preenchido pelo trigger
    CASE 
      WHEN v_old_cpf_normalized IS NOT NULL AND v_old_cpf_normalized <> '' THEN 
        '***.***.***-' || SUBSTRING(v_old_cpf_normalized FROM 10 FOR 2)
      ELSE '***.***.***-**' 
    END,
    '***.***.***-' || SUBSTRING(v_clean_cpf FROM 10 FOR 2),
    'documento_enviado',
    NULL,
    v_now + INTERVAL '30 days',
    v_now,
    v_now
  )
  RETURNING protocol_number INTO v_protocol_number;

  -- 13. Inserção na tabela privada de secure payloads
  INSERT INTO private.dependent_cpf_change_secure_payloads (
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

  -- 14. Inserção na tabela privada de review data (old_cpf_clear recebe o CPF devidamente normalizado)
  INSERT INTO private.dependent_cpf_change_review_data (
    request_id,
    old_cpf_clear,
    new_cpf_clear,
    document_file_id,
    document_state,
    created_at,
    updated_at
  ) VALUES (
    v_request_id,
    v_old_cpf_normalized,
    p_new_cpf_clear,
    p_document_file_id,
    'available',
    v_now,
    v_now
  );

  -- 15. Inserção na reserva de CPF por HMAC
  INSERT INTO private.dependent_cpf_change_reservations (
    request_id,
    member_id,
    new_cpf_hmac,
    new_cpf_hmac_key_version,
    reservation_state,
    released_at,
    created_at,
    updated_at
  ) VALUES (
    v_request_id,
    p_member_id,
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
    GET STACKED DIAGNOSTICS
      v_sqlstate = RETURNED_SQLSTATE,
      v_constraint = CONSTRAINT_NAME,
      v_table = TABLE_NAME,
      v_column = COLUMN_NAME,
      v_datatype = PG_DATATYPE_NAME;

    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'internal_error',
      'sqlstate', NULLIF(v_sqlstate, ''),
      'constraint', NULLIF(v_constraint, ''),
      'table', NULLIF(v_table, ''),
      'column', NULLIF(v_column, ''),
      'datatype', NULLIF(v_datatype, '')
    );
END;
$$;

-- Revoga privilégios de execução padrão públicos
REVOKE ALL ON FUNCTION private.conectea_create_dependent_cpf_change_request_v1(
  uuid, uuid, text, text, text, text, text, text, text, integer
) FROM PUBLIC, anon, authenticated;

-- Concede execução exclusiva para o service_role
GRANT EXECUTE ON FUNCTION private.conectea_create_dependent_cpf_change_request_v1(
  uuid, uuid, text, text, text, text, text, text, text, integer
) TO service_role;

COMMENT ON FUNCTION private.conectea_create_dependent_cpf_change_request_v1(
  uuid, uuid, text, text, text, text, text, text, text, integer
) IS
  'Função PL/PGSQL privada restrita a service_role para criação transacional de solicitações de alteração de CPF de dependente. Modificada para normalizar old_cpf_clear para NULL se for string vazia ou inválida, corrigir regex 2201B no document_file_id e retornar stacked diagnostics de internal_error.';
