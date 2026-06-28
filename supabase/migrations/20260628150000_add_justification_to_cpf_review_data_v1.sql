-- =========================================================================
-- ConeCTEA — Backend Justification na Revisão CPF Admin
--
-- MIGRATION: 20260628150000_add_justification_to_cpf_review_data_v1.sql
-- OBJETIVO:
--   - Adicionar a coluna justification em private.account_change_review_data
--   - Atualizar private.conectea_create_cpf_change_request_v2
--   - Atualizar public.conectea_admin_get_cpf_change_sensitive_review_v1
--   - Atualizar private.conectea_clear_account_change_review_data_v1
-- =========================================================================

-- 1. ADICIONAR COLUNA NA TABELA PRIVADA
ALTER TABLE private.account_change_review_data
ADD COLUMN IF NOT EXISTS justification text;

-- =========================================================================
-- 2. ATUALIZAR RPC DE CRIAÇÃO
-- =========================================================================

CREATE OR REPLACE FUNCTION private.conectea_create_cpf_change_request_v2(
  p_user_id uuid,
  p_new_cpf_clear text,
  p_new_cpf_hmac text,
  p_justification text,
  p_ciphertext text,
  p_nonce text,
  p_auth_tag text,
  p_algorithm text,
  p_key_version integer,
  p_document_file_id text
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
  
  -- Variáveis estruturais do documento
  v_doc_file_id text;
  v_doc_state text;

  -- Variáveis de diagnóstico seguro
  v_sqlstate text;
  v_constraint text;
  v_table text;
  v_column text;
  v_datatype text;
BEGIN
  -- A. Validação de Parâmetros de Entrada
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

  -- Validação estrita do algoritmo e versão de chave criptográfica
  IF p_algorithm <> 'aes-256-gcm' OR p_key_version <> 1 THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- B. Validar e formatar p_document_file_id
  v_doc_file_id := trim(p_document_file_id);
  IF v_doc_file_id = '' THEN
    v_doc_file_id := NULL;
  END IF;

  IF v_doc_file_id IS NULL THEN
    v_doc_state := 'none';
  ELSE
    -- Validação com regex de ID de arquivo do Google Drive
    IF length(v_doc_file_id) < 10 OR length(v_doc_file_id) > 256 OR v_doc_file_id !~ '^[A-Za-z0-9_-]+$' THEN
      RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
    END IF;
    v_doc_state := 'available';
  END IF;

  v_now := transaction_timestamp();

  -- C. Normalização do CPF solicitado (deixar apenas dígitos)
  v_clean_cpf := regexp_replace(p_new_cpf_clear, '[^0-9]', '', 'g');

  IF length(v_clean_cpf) <> 11 THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- D. Validação matemática do CPF (Dígitos Verificadores)
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

  -- E. Validar formato do HMAC (64 caracteres hexadecimal em lowercase)
  IF p_new_cpf_hmac !~ '^[a-f0-9]{64}$' THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- F. Lock pessimista sobre o perfil do usuário para evitar concorrência
  SELECT true, cpf INTO v_profile_exists, v_profile_cpf
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_profile_exists IS NOT TRUE THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- G. Impedir CPF solicitado igual ao CPF atual da conta
  IF v_profile_cpf IS NOT NULL AND regexp_replace(v_profile_cpf, '[^0-9]', '', 'g') = v_clean_cpf THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- H. Verificar se o CPF solicitado já existe cadastrado em outros perfis (profiles)
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

  -- I. Verificar se o CPF solicitado já existe cadastrado em dependentes (members)
  SELECT EXISTS (
    SELECT 1 
    FROM public.members 
    WHERE cpf IS NOT NULL 
      AND regexp_replace(cpf, '[^0-9]', '', 'g') = v_clean_cpf
  ) INTO v_conflict_member_exists;

  IF v_conflict_member_exists THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- J. Verificar se já existe solicitação ativa de alteração de CPF para o usuário
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

  -- K. Geração do ID do protocolo
  v_request_id := gen_random_uuid();

  -- L. Inserção na tabela pública de solicitações
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

  -- M. Inserção do payload privado criptografado
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

  -- N. Inserção da reserva de CPF por HMAC
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

  -- O. Inserção na tabela privada de dados transitórios de CPF para revisão
  -- Nota de Segurança: CPFs e o file_id do documento de identidade são mantidos 
  -- estritamente em banco privado para revisão de administradores master/dev autorizados.
  INSERT INTO private.account_change_review_data (
    request_id,
    old_cpf_clear,
    new_cpf_clear,
    document_file_id,
    document_state,
    justification
  ) VALUES (
    v_request_id,
    regexp_replace(v_profile_cpf, '[^0-9]', '', 'g'), -- old_cpf_clear (decriptado do perfil atual)
    v_clean_cpf,                                      -- new_cpf_clear (CPF novo em texto limpo)
    v_doc_file_id,                                    -- document_file_id (validado com regex alfanumérica)
    v_doc_state,                                      -- document_state (none ou available)
    NULLIF(BTRIM(p_justification), '')                -- justification adicionada
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

-- Revogação total de privilégios públicos padrão na RPC privada v2
REVOKE ALL ON FUNCTION private.conectea_create_cpf_change_request_v2(
  uuid, text, text, text, text, text, text, text, integer, text
) FROM PUBLIC, anon, authenticated;

-- Concessão de execução exclusiva para o service_role
GRANT EXECUTE ON FUNCTION private.conectea_create_cpf_change_request_v2(
  uuid, text, text, text, text, text, text, text, integer, text
) TO service_role;

COMMENT ON FUNCTION private.conectea_create_cpf_change_request_v2 IS
  'Função SQL/PLPGSQL privada restrita a service_role para criação transacional de solicitações de alteração de CPF (V2) com gravação na tabela de review privada na mesma transação. Modificada para retornar stacked diagnostics de internal_error e suportar justification.';

-- =========================================================================
-- 3. ATUALIZAR RPC DE LEITURA
-- =========================================================================

CREATE OR REPLACE FUNCTION public.conectea_admin_get_cpf_change_sensitive_review_v1(
  p_request_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private, pg_temp
AS $$
DECLARE
  v_caller_id uuid;
  v_caller_role text;
  v_request_exists boolean;
  v_request_type public.account_change_type;
  v_request_status public.account_change_status;
  v_review_record record;
  v_can_view boolean;
  v_review_found boolean := false;
  v_safe_document_state text := 'unavailable';
  v_can_view_document boolean := false;
  v_review_is_active boolean := false;
  
  -- Nota de Segurança: document_file_id é extremamente sensível, não deve ser logado pelo
  -- servidor de aplicação e não deve ser renderizado diretamente na UI. O seu retorno é
  -- restrito a esta RPC Security Definer sob demanda de admin dev/master autenticado para
  -- abertura de documento e auditoria.
  -- Dados sensíveis devem ser expurgados ao sair dos status analisáveis por fluxo backend específico.
BEGIN
  -- A. Validar caller autenticado
  v_caller_id := auth.uid();
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Acesso negado: usuario nao autenticado.' USING ERRCODE = '42501';
  END IF;

  -- B. Validar role do caller (Somente admin_master ou admin_dev possuem permissão)
  SELECT role INTO v_caller_role
  FROM public.profiles
  WHERE id = v_caller_id;

  IF v_caller_role IS NULL OR v_caller_role NOT IN ('admin_master', 'admin_dev') THEN
    RAISE EXCEPTION 'Acesso negado: privilegios insuficientes.' USING ERRCODE = '42501';
  END IF;

  -- C. Validar existência da solicitação
  SELECT EXISTS (
    SELECT 1 FROM public.account_change_requests WHERE id = p_request_id
  ) INTO v_request_exists;

  IF NOT v_request_exists THEN
    RAISE EXCEPTION 'Solicitacao nao encontrada.' USING ERRCODE = 'P0002';
  END IF;

  -- D. Validar tipo da solicitação (Deve ser CPF)
  SELECT type, status INTO v_request_type, v_request_status
  FROM public.account_change_requests
  WHERE id = p_request_id;

  IF v_request_type <> 'cpf'::public.account_change_type THEN
    RAISE EXCEPTION 'Operacao invalida: tipo de solicitacao incorreto.' USING ERRCODE = '42809';
  END IF;

  -- E. Determinar se o status permite leitura completa dos dados limpos
  -- Permitido apenas em: under_review, waiting_document_replacement, waiting_cpf_correction
  IF v_request_status IN (
    'under_review'::public.account_change_status,
    'waiting_document_replacement'::public.account_change_status,
    'waiting_cpf_correction'::public.account_change_status
  ) THEN
    v_can_view := true;
  ELSE
    v_can_view := false;
  END IF;

  -- F. Consultar tabela de review privada (vínculo de consistência e user_id resolvido no JOIN público)
  SELECT rd.* INTO v_review_record
  FROM private.account_change_review_data rd
  JOIN public.account_change_requests cr ON rd.request_id = cr.id
  WHERE rd.request_id = p_request_id;

  v_review_found := FOUND;

  -- G. Atribuir e calcular de forma segura o estado do documento e expurgo
  IF v_review_found THEN
    v_safe_document_state := COALESCE(v_review_record.document_state, 'unavailable');
    v_review_is_active := v_review_record.cleared_at IS NULL;

    v_can_view_document :=
      v_review_is_active
      AND v_safe_document_state = 'available'
      AND v_review_record.document_file_id IS NOT NULL
      AND v_review_record.document_file_id <> '';
  END IF;

  -- H. Montar retorno condicional baseado no status e expurgo
  IF v_can_view AND v_review_found AND v_review_is_active THEN
    RETURN jsonb_build_object(
      'can_view', true,
      'request_id', p_request_id,
      'status', v_request_status,
      'old_cpf_clear', v_review_record.old_cpf_clear,
      'new_cpf_clear', v_review_record.new_cpf_clear,
      'document_state', v_safe_document_state,
      'can_view_document', v_can_view_document,
      'document_file_id', CASE WHEN v_can_view_document THEN v_review_record.document_file_id ELSE NULL END,
      'justification', CASE WHEN v_can_view THEN v_review_record.justification ELSE NULL END,
      'server_now', now()
    );
  ELSE
    RETURN jsonb_build_object(
      'can_view', false,
      'request_id', p_request_id,
      'status', v_request_status,
      'old_cpf_clear', null,
      'new_cpf_clear', null,
      'document_state', v_safe_document_state,
      'can_view_document', false,
      'document_file_id', null,
      'justification', null,
      'server_now', now()
    );
  END IF;
END;
$$;

COMMENT ON FUNCTION public.conectea_admin_get_cpf_change_sensitive_review_v1(uuid)
  IS 'Obtém dados confidenciais e limpos da solicitação de CPF para admins dev/master, mascarando o PII se o status da solicitação estiver fechado ou inativo.';

-- Grants rígidos de execução
REVOKE ALL ON FUNCTION public.conectea_admin_get_cpf_change_sensitive_review_v1(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_admin_get_cpf_change_sensitive_review_v1(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_get_cpf_change_sensitive_review_v1(uuid) TO service_role;

-- =========================================================================
-- 4. ATUALIZAR RPC DE LIMPEZA
-- =========================================================================

CREATE OR REPLACE FUNCTION private.conectea_clear_account_change_review_data_v1(
  p_request_id uuid,
  p_reason text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private, pg_temp
AS $$
DECLARE
  v_exists boolean;
  v_state text;
  v_reason_trimmed text;
  v_current_cleared_at timestamptz;
  v_current_clear_reason text;
  v_current_document_state text;
BEGIN
  -- A. Validar e sanitizar motivo de limpeza (não pode ser nulo ou vazio)
  -- Valores logicos esperados para clear_reason (documentado para auditoria):
  --   'status_completed', 'status_rejected', 'status_cancelled', 'status_expired', 'document_replaced', 'manual_cleanup', 'unavailable'
  v_reason_trimmed := trim(COALESCE(p_reason, ''));
  IF v_reason_trimmed = '' THEN
    RAISE EXCEPTION 'Motivo de limpeza invalido: clear_reason nao pode ser nulo ou vazio.' USING ERRCODE = '22004';
  END IF;

  -- B. Obter status de expurgo e estado do documento atual para garantir a idempotência perfeita
  SELECT cleared_at, clear_reason, document_state 
  INTO v_current_cleared_at, v_current_clear_reason, v_current_document_state
  FROM private.account_change_review_data
  WHERE request_id = p_request_id;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  -- C. Mapear estado do documento baseado no motivo do expurgo
  IF v_reason_trimmed IN ('status_completed', 'status_rejected', 'status_cancelled', 'status_expired', 'document_replaced', 'manual_cleanup') THEN
    v_state := 'discarded';
  ELSE
    v_state := 'unavailable';
  END IF;

  -- D. Executar expurgo dos dados sensíveis mantendo registro de auditoria anônimo (idempotente)
  -- Nota: Se o document_state atual já for terminal (discarded ou unavailable), ele é preservado.
  UPDATE private.account_change_review_data
  SET
    old_cpf_clear = null,
    new_cpf_clear = null,
    document_file_id = null,
    justification = null,
    document_state = CASE
      WHEN v_current_document_state IN ('discarded', 'unavailable') THEN v_current_document_state
      ELSE v_state
    END,
    cleared_at = COALESCE(v_current_cleared_at, now()),
    clear_reason = COALESCE(v_current_clear_reason, v_reason_trimmed),
    updated_at = now()
  WHERE request_id = p_request_id;
END;
$$;

COMMENT ON FUNCTION private.conectea_clear_account_change_review_data_v1(uuid, text)
  IS 'Realiza a limpeza física dos dados PII de CPF, documento e justificativa no banco privado, mantendo apenas metadados de auditoria.';

-- Apenas o banco de dados interno ou service_role podem executar o expurgo
REVOKE ALL ON FUNCTION private.conectea_clear_account_change_review_data_v1(uuid, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.conectea_clear_account_change_review_data_v1(uuid, text) TO service_role;
