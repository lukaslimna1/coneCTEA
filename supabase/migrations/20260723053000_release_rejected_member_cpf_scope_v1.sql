-- =========================================================================
-- ConeCTEA — Liberação de Escopo de CPF de Dependente Rejeitado (H6-B-R4)
--
-- MIGRATION: 20260723053000_release_rejected_member_cpf_scope_v1.sql
-- OBJETIVO:
--   1. Checar duplicidades prévias de CPF entre dependentes não-rejeitados antes de qualquer alteração de índice.
--   2. Dropar o índice único global anterior (`members_cpf_normalized_unique_idx`)
--      que bloqueava inadvertidamente CPFs de dependentes rejeitados.
--   3. Garantir idempotência dropando versões de índices das revisões anteriores (`members_cpf_active_approved_unique_idx`, `members_cpf_non_rejected_unique_idx`).
--   4. Limpar a coluna `cpf` de registros existentes em `public.members` com status 'rejected',
--      liberando o CPF sem apagar histórico cadastral ou administrativo.
--   5. Criar trigger automático e seguro em `public.members` com SECURITY DEFINER e search_path para anular `cpf`
--      sempre que um membro for marcado com status 'rejected' no futuro.
--   6. Criar índice único parcial conservador (`members_cpf_non_rejected_unique_idx`)
--      restringindo a unicidade de CPF para dependentes cujo status IS DISTINCT FROM 'rejected'
--      (liberando apenas 'rejected' e mantendo outros status como 'inactive', 'cancelled', 'expired' bloqueando até regra futura).
--   7. Atualizar a RPC `private.conectea_create_dependent_cpf_change_request_v1`
--      para que `v_conflict_member_exists` consulte apenas dependentes cujo status IS DISTINCT FROM 'rejected'.
--   8. Atualizar a RPC `public.conectea_submit_dependent_cpf_correction_v1`
--      para que `v_conflict_member_exists` consulte apenas dependentes cujo status IS DISTINCT FROM 'rejected'.
-- =========================================================================

-- 1. Checagem de segurança prévia contra duplicidades entre membros não-rejeitados (executada ANTES de alterar qualquer índice)
DO $$
DECLARE
  v_duplicate_count integer;
BEGIN
  SELECT count(*) INTO v_duplicate_count
  FROM (
    SELECT regexp_replace(cpf, '[^0-9]', '', 'g')
    FROM public.members
    WHERE status IS DISTINCT FROM 'rejected'
      AND cpf IS NOT NULL
      AND NULLIF(regexp_replace(cpf, '[^0-9]', '', 'g'), '') IS NOT NULL
    GROUP BY regexp_replace(cpf, '[^0-9]', '', 'g')
    HAVING count(*) > 1
  ) d;

  IF v_duplicate_count > 0 THEN
    RAISE EXCEPTION 'duplicate_non_rejected_member_cpf_detected';
  END IF;
END $$;

-- 2. Dropar índices (global antigo e versões anteriores por idempotência)
DROP INDEX IF EXISTS public.members_cpf_normalized_unique_idx;
DROP INDEX IF EXISTS public.members_cpf_active_approved_unique_idx;
DROP INDEX IF EXISTS public.members_cpf_non_rejected_unique_idx;

-- 3. Anular a coluna `cpf` em registros com status 'rejected' já existentes
UPDATE public.members
SET cpf = NULL,
    updated_at = transaction_timestamp()
WHERE status = 'rejected'
  AND cpf IS NOT NULL
  AND NULLIF(regexp_replace(cpf, '[^0-9]', '', 'g'), '') IS NOT NULL;

-- 4. Criar trigger automático para garantir que rejeições futuras limpem o campo `cpf` de members
CREATE OR REPLACE FUNCTION public.conectea_members_clear_cpf_on_rejected_trigger_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
BEGIN
  IF NEW.status = 'rejected' AND NEW.cpf IS NOT NULL THEN
    NEW.cpf := NULL;
    NEW.updated_at := transaction_timestamp();
  END IF;
  RETURN NEW;
END;
$$;

-- Ajustar privilégios e permissões da função de trigger
REVOKE ALL ON FUNCTION public.conectea_members_clear_cpf_on_rejected_trigger_v1() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_members_clear_cpf_on_rejected_trigger_v1() TO service_role, postgres;

COMMENT ON FUNCTION public.conectea_members_clear_cpf_on_rejected_trigger_v1() IS
  'Função de trigger de segurança para anular automaticamente a coluna cpf de members quando o status for alterado ou inserido como rejected.';

DROP TRIGGER IF EXISTS trg_conectea_members_clear_cpf_on_rejected ON public.members;

CREATE TRIGGER trg_conectea_members_clear_cpf_on_rejected
BEFORE INSERT OR UPDATE OF status, cpf ON public.members
FOR EACH ROW
WHEN (NEW.status = 'rejected' AND NEW.cpf IS NOT NULL)
EXECUTE FUNCTION public.conectea_members_clear_cpf_on_rejected_trigger_v1();

-- 5. Criar novo índice único parcial restrito a status não-rejeitados (liberando apenas 'rejected')
CREATE UNIQUE INDEX members_cpf_non_rejected_unique_idx 
ON public.members USING btree (regexp_replace(cpf, '[^0-9]'::text, ''::text, 'g'::text)) 
WHERE ((status IS DISTINCT FROM 'rejected') AND (NULLIF(regexp_replace(cpf, '[^0-9]'::text, ''::text, 'g'::text), ''::text) IS NOT NULL));

-- 6. Recriar RPC private.conectea_create_dependent_cpf_change_request_v1 (com v_conflict_member_exists restrito a não-rejeitados)
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

  -- Validar se member está ativo/aprovado (Retorna código semântico member_not_active)
  IF v_member_status NOT IN ('active', 'approved') THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'member_not_active');
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

  -- 6. Impedir CPF solicitado igual ao CPF atual do próprio dependente (Retorna código semântico same_current_cpf)
  IF v_old_cpf_normalized IS NOT NULL AND v_old_cpf_normalized = v_clean_cpf THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'same_current_cpf');
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

  -- 8. Verificar se o CPF solicitado já existe cadastrado em outros dependentes (members) não-rejeitados (Retorna código seguro unavailable)
  SELECT EXISTS (
    SELECT 1 
    FROM public.members 
    WHERE id <> p_member_id
      AND status IS DISTINCT FROM 'rejected'
      AND cpf IS NOT NULL 
      AND regexp_replace(cpf, '[^0-9]', '', 'g') = v_clean_cpf
  ) INTO v_conflict_member_exists;

  IF v_conflict_member_exists THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'unavailable');
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
  'Função PL/PGSQL privada restrita a service_role para criação transacional de solicitações de alteração de CPF de dependente. Refinada em H6-B-R4 para consultar apenas dependentes com status não-rejeitado (IS DISTINCT FROM rejected) em v_conflict_member_exists.';

-- 7. Recriar RPC public.conectea_submit_dependent_cpf_correction_v1 (com v_conflict_member_exists restrito a não-rejeitados)
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

  -- 8. Validar conflito com CPF de outro dependente (members) não-rejeitado
  SELECT EXISTS (
    SELECT 1 
    FROM public.members 
    WHERE id <> v_request.member_id
      AND status IS DISTINCT FROM 'rejected'
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
  'Chamado via Edge Function submit-dependent-cpf-correction para que o titular corrija o CPF do dependente (status under_review). Refinada em H6-B-R4 para consultar apenas dependentes com status não-rejeitado (IS DISTINCT FROM rejected) em v_conflict_member_exists.';
