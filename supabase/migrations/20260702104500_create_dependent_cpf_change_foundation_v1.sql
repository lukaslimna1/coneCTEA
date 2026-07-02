-- =========================================================================
-- ConeCTEA — Fundação de Domínio e Banco para Alteração de CPF de Dependente
--
-- MIGRATION: 20260702104500_create_dependent_cpf_change_foundation_v1.sql
-- OBJETIVO:
--   - Criar as tabelas pública e privadas de solicitação de alteração de CPF de dependente.
--   - Criar a RPC segura no schema private e sua wrapper pública para service_role.
--   - Estabelecer RLS, índices de exclusividade, triggers de updated_at/protocolo e grants mínimos.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. CRIAÇÃO DA TABELA PÚBLICA DE SOLICITAÇÕES
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.dependent_cpf_change_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  member_id uuid NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'under_review',
  protocol_number text UNIQUE NOT NULL,
  current_cpf_masked text,
  requested_cpf_masked text,
  document_reference_masked text,
  admin_feedback text, -- Mensagem pública e sanitizada destinada ao usuário
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  cancelled_at timestamptz,
  completed_at timestamptz,

  -- Restrição de status válidos
  CONSTRAINT chk_dep_cpf_request_status CHECK (
    status IN (
      'under_review',
      'waiting_document_replacement',
      'waiting_cpf_correction',
      'applying',
      'completed',
      'rejected_by_admin',
      'cancelled_by_holder',
      'expired',
      'application_failed'
    )
  ),

  -- Restrição de coerência de cancelamento/conclusão
  CONSTRAINT chk_dep_cpf_request_cancelled_at CHECK (
    (status = 'cancelled_by_holder' AND cancelled_at IS NOT NULL) OR
    (status <> 'cancelled_by_holder' AND cancelled_at IS NULL)
  ),
  CONSTRAINT chk_dep_cpf_request_completed_at CHECK (
    (status = 'completed' AND completed_at IS NOT NULL) OR
    (status <> 'completed' AND completed_at IS NULL)
  )
);

COMMENT ON TABLE public.dependent_cpf_change_requests IS 
  'Tabela pública contendo protocolos e estados de solicitações de alteração de CPF de dependente.';

-- ─────────────────────────────────────────────────────────────────────────
-- 2. CRIAÇÃO DAS TABELAS PRIVADAS (SCHEMA PRIVATE)
-- ─────────────────────────────────────────────────────────────────────────

CREATE SCHEMA IF NOT EXISTS private;

-- Restringe totalmente o schema private
REVOKE USAGE ON SCHEMA private FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA private TO service_role;

-- A. Tabela de payloads seguros criptografados
CREATE TABLE IF NOT EXISTS private.dependent_cpf_change_secure_payloads (
  request_id uuid PRIMARY KEY REFERENCES public.dependent_cpf_change_requests(id) ON DELETE CASCADE,
  ciphertext text NOT NULL,
  nonce text NOT NULL,
  auth_tag text,
  algorithm text NOT NULL,
  key_version integer NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT chk_dep_cpf_secure_payload_algorithm CHECK (algorithm = 'aes-256-gcm'),
  CONSTRAINT chk_dep_cpf_secure_payload_key_version CHECK (key_version = 1)
);

COMMENT ON TABLE private.dependent_cpf_change_secure_payloads IS 
  'Tabela privada contendo payloads criptografados de CPF de dependente (PII).';

-- B. Tabela transitória de análise/review
CREATE TABLE IF NOT EXISTS private.dependent_cpf_change_review_data (
  request_id uuid PRIMARY KEY REFERENCES public.dependent_cpf_change_requests(id) ON DELETE CASCADE,
  old_cpf_clear text NULL,
  new_cpf_clear text NULL,
  document_file_id text NULL,
  document_state text NOT NULL DEFAULT 'unknown',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  cleared_at timestamptz NULL,
  clear_reason text NULL,

  CONSTRAINT chk_dep_cpf_review_doc_state CHECK (
    document_state IN ('unknown', 'none', 'available', 'replaced', 'discarded', 'unavailable')
  ),
  CONSTRAINT chk_dep_cpf_review_doc_file_id CHECK (
    document_file_id IS NULL OR document_file_id ~ '^[A-Za-z0-9_-]{10,256}$'
  ),
  CONSTRAINT chk_dep_cpf_review_old_cpf CHECK (
    old_cpf_clear IS NULL OR length(regexp_replace(old_cpf_clear, '[^0-9]', '', 'g')) = 11
  ),
  CONSTRAINT chk_dep_cpf_review_new_cpf CHECK (
    new_cpf_clear IS NULL OR length(regexp_replace(new_cpf_clear, '[^0-9]', '', 'g')) = 11
  ),
  CONSTRAINT chk_dep_cpf_review_coherence CHECK (
    (cleared_at IS NULL) OR (
      old_cpf_clear IS NULL AND
      new_cpf_clear IS NULL AND
      document_file_id IS NULL
    )
  ),
  CONSTRAINT chk_dep_cpf_review_clear_reason CHECK (
    (clear_reason IS NULL OR btrim(clear_reason) <> '') AND
    (cleared_at IS NULL OR clear_reason IS NOT NULL)
  )
);

COMMENT ON TABLE private.dependent_cpf_change_review_data IS 
  'Tabela privada transitória para análise de CPFs limpos de dependentes pelo admin.';

-- C. Tabela de reservas de CPF por HMAC
-- NOTA DE PROJETO SOBRE A RESERVA DE CPFs:
-- - Reservas no estado 'attached' bloqueiam qualquer nova solicitação para o mesmo CPF.
-- - Futuras RPCs de cancelamento, rejeição, expiração ou conclusão devem alterar o estado
--   da reserva para 'released' e definir a data 'released_at' correspondente.
-- - Esta migration atua exclusivamente como a fundação de banco e não implementa o fluxo
--   completo de cancelamento/aprovação/liberação, o qual será adicionado nas frentes de controle admin/usuário.
CREATE TABLE IF NOT EXISTS private.dependent_cpf_change_reservations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NOT NULL REFERENCES public.dependent_cpf_change_requests(id) ON DELETE CASCADE,
  member_id uuid NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  new_cpf_hmac text NOT NULL,
  new_cpf_hmac_key_version integer NOT NULL DEFAULT 1,
  reservation_state text NOT NULL DEFAULT 'attached',
  released_at timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT chk_dep_cpf_res_hmac_format CHECK (new_cpf_hmac ~ '^[a-f0-9]{64}$'),
  CONSTRAINT chk_dep_cpf_res_hmac_version CHECK (new_cpf_hmac_key_version = 1),
  CONSTRAINT chk_dep_cpf_res_state CHECK (reservation_state IN ('attached', 'released')),
  CONSTRAINT chk_dep_cpf_res_state_coherence CHECK (
    (reservation_state = 'attached' AND released_at IS NULL) OR
    (reservation_state = 'released' AND released_at IS NOT NULL)
  )
);

COMMENT ON TABLE private.dependent_cpf_change_reservations IS 
  'Tabela privada de reserva exclusiva de CPFs de dependentes via HMAC-SHA256 para impedir duplicidade de solicitações.';

-- ─────────────────────────────────────────────────────────────────────────
-- 3. ÍNDICES DE PERFORMANCE E UNICIDADE
-- ─────────────────────────────────────────────────────────────────────────

-- Índices operacionais públicos
CREATE INDEX IF NOT EXISTS idx_dep_cpf_requests_user_id ON public.dependent_cpf_change_requests (user_id);
CREATE INDEX IF NOT EXISTS idx_dep_cpf_requests_member_id ON public.dependent_cpf_change_requests (member_id);
CREATE INDEX IF NOT EXISTS idx_dep_cpf_requests_status ON public.dependent_cpf_change_requests (status);
CREATE INDEX IF NOT EXISTS idx_dep_cpf_requests_created_at ON public.dependent_cpf_change_requests (created_at);

-- Bloqueia mais de uma solicitação ativa simultânea para o mesmo dependente
CREATE UNIQUE INDEX IF NOT EXISTS idx_dep_cpf_requests_active_uniq
ON public.dependent_cpf_change_requests (member_id)
WHERE status IN (
  'under_review',
  'waiting_document_replacement',
  'waiting_cpf_correction',
  'applying',
  'application_failed'
);

-- Impede concorrência de reservas de CPF ativas
CREATE UNIQUE INDEX IF NOT EXISTS idx_dep_cpf_reservations_active_uniq
ON private.dependent_cpf_change_reservations (new_cpf_hmac)
WHERE reservation_state = 'attached';

-- ─────────────────────────────────────────────────────────────────────────
-- 4. GERADOR DE PROTOCOLO E TRIGGERS AUTOMÁTICOS
-- ─────────────────────────────────────────────────────────────────────────

-- Função de geração de protocolo com prefixo "DC"
CREATE OR REPLACE FUNCTION public.generate_dependent_cpf_change_protocol_v1()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  v_date_str text;
  v_random_num int;
  v_protocol text;
  v_exists boolean;
BEGIN
  v_date_str := to_char(timezone('America/Sao_Paulo', now()), 'YYYYMMDD');
  LOOP
    v_random_num := floor(random() * (9999 - 1000 + 1) + 1000)::int;
    v_protocol := 'DC-' || v_date_str || '-' || v_random_num::text;
    
    SELECT EXISTS (
      SELECT 1 FROM public.dependent_cpf_change_requests WHERE protocol_number = v_protocol
    ) INTO v_exists;
    
    IF NOT v_exists THEN
      EXIT;
    END IF;
  END LOOP;
  RETURN v_protocol;
END;
$$;

-- Trigger de protocolo
CREATE OR REPLACE FUNCTION public.handle_dependent_cpf_change_requests_protocol()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.protocol_number IS NULL OR NEW.protocol_number = '' THEN
    NEW.protocol_number := public.generate_dependent_cpf_change_protocol_v1();
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER tr_dependent_cpf_change_requests_protocol
  BEFORE INSERT ON public.dependent_cpf_change_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_dependent_cpf_change_requests_protocol();

-- Triggers de updated_at
CREATE OR REPLACE FUNCTION public.handle_dependent_cpf_change_requests_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER tr_dependent_cpf_change_requests_updated_at
  BEFORE UPDATE ON public.dependent_cpf_change_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_dependent_cpf_change_requests_updated_at();

CREATE OR REPLACE FUNCTION private.handle_dependent_cpf_change_review_data_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER tr_dependent_cpf_change_review_data_updated_at
  BEFORE UPDATE ON private.dependent_cpf_change_review_data
  FOR EACH ROW
  EXECUTE FUNCTION private.handle_dependent_cpf_change_review_data_updated_at();

CREATE OR REPLACE FUNCTION private.handle_dependent_cpf_change_secure_payloads_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER tr_dependent_cpf_change_secure_payloads_updated_at
  BEFORE UPDATE ON private.dependent_cpf_change_secure_payloads
  FOR EACH ROW
  EXECUTE FUNCTION private.handle_dependent_cpf_change_secure_payloads_updated_at();

-- ─────────────────────────────────────────────────────────────────────────
-- 5. RPC PRIVADA DE CRIAÇÃO (SERVICE_ROLE ONLY)
-- ─────────────────────────────────────────────────────────────────────────

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
BEGIN
  -- 1. Validação de Parâmetros de Entrada (p_document_file_id obrigatório e verificado contra regex)
  IF p_user_id IS NULL
     OR p_member_id IS NULL
     OR p_new_cpf_clear IS NULL
     OR p_new_cpf_hmac IS NULL
     OR p_document_file_id IS NULL OR p_document_file_id !~ '^[A-Za-z0-9_-]{10,256}$'
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

  -- 6. Impedir CPF solicitado igual ao CPF atual do próprio dependente
  IF v_member_cpf IS NOT NULL AND regexp_replace(v_member_cpf, '[^0-9]', '', 'g') = v_clean_cpf THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_request');
  END IF;

  -- 7. Impedir CPF solicitado igual ao CPF da conta do titular (parent)
  SELECT cpf INTO v_parent_cpf
  FROM public.profiles
  WHERE id = p_user_id;

  IF v_parent_cpf IS NOT NULL AND regexp_replace(v_parent_cpf, '[^0-9]', '', 'g') = v_clean_cpf THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'account_cpf_flow_required');
  END IF;

  -- CORREÇÃO OBRIGATÓRIA 1: Impedir que o fluxo de CPF de dependente seja usado
  -- quando o CPF atual do member for igual ao CPF da conta (titular). Esse caso
  -- deve ir para o fluxo de CPF da conta.
  IF v_member_cpf IS NOT NULL AND v_parent_cpf IS NOT NULL AND
     regexp_replace(v_member_cpf, '[^0-9]', '', 'g') = regexp_replace(v_parent_cpf, '[^0-9]', '', 'g') THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'account_cpf_flow_required');
  END IF;

  -- 8. Verificar se o CPF solicitado já existe cadastrado em outros dependentes (members)
  -- NOTA DE SEGURANÇA: Bloqueio absoluto em members.cpf para evitar duplicidade de identidade.
  -- Qualquer dependente existente com o mesmo CPF bloqueia a nova solicitação,
  -- garantindo que não existam CPFs duplicados ativos ou inativos sem auditoria.
  -- Esta regra é restrita por design e pode ser revisada futuramente pelo Lucas.
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

  -- 12. Inserção na tabela pública de solicitações (admin_id removido para evitar exposição)
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
      WHEN v_member_cpf IS NOT NULL AND v_member_cpf <> '' THEN 
        CASE 
          WHEN length(regexp_replace(v_member_cpf, '[^0-9]', '', 'g')) = 11 THEN
            '***.***.***-' || SUBSTRING(regexp_replace(v_member_cpf, '[^0-9]', '', 'g') FROM 10 FOR 2)
          ELSE '***.***.***-**'
        END
      ELSE '***.***.***-**' 
    END,
    '***.***.***-' || SUBSTRING(v_clean_cpf FROM 10 FOR 2),
    'documento_enviado', -- Referência textual mascarada e segura para a tabela pública
    NULL,
    v_now + INTERVAL '30 days', -- expira em 30 dias por padrão
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

  -- 14. Inserção na tabela privada de review data (document_state passa a 'available')
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
    v_member_cpf,
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
    -- Remoção de detalhes técnicos/SQLERRM para evitar vazamento de informações internas
    RETURN jsonb_build_object('success', false, 'error_code', 'internal_error');
END;
$$;

-- Revoga execução pública padrão
REVOKE ALL ON FUNCTION private.conectea_create_dependent_cpf_change_request_v1(
  uuid, uuid, text, text, text, text, text, text, text, integer
) FROM PUBLIC, anon, authenticated;

-- Concede execução exclusiva a service_role
GRANT EXECUTE ON FUNCTION private.conectea_create_dependent_cpf_change_request_v1(
  uuid, uuid, text, text, text, text, text, text, text, integer
) TO service_role;

-- ─────────────────────────────────────────────────────────────────────────
-- 6. WRAPPER PÚBLICA DE CRIAÇÃO (SERVICE_ROLE ONLY)
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_create_dependent_cpf_change_request_v1(
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
BEGIN
  RETURN private.conectea_create_dependent_cpf_change_request_v1(
    p_user_id => p_user_id,
    p_member_id => p_member_id,
    p_new_cpf_clear => p_new_cpf_clear,
    p_new_cpf_hmac => p_new_cpf_hmac,
    p_document_file_id => p_document_file_id,
    p_ciphertext => p_ciphertext,
    p_nonce => p_nonce,
    p_auth_tag => p_auth_tag,
    p_algorithm => p_algorithm,
    p_key_version => p_key_version
  );
END;
$$;

-- Revoga execução pública padrão
REVOKE ALL ON FUNCTION public.conectea_create_dependent_cpf_change_request_v1(
  uuid, uuid, text, text, text, text, text, text, text, integer
) FROM PUBLIC, anon, authenticated;

-- Concede execução exclusiva a service_role
GRANT EXECUTE ON FUNCTION public.conectea_create_dependent_cpf_change_request_v1(
  uuid, uuid, text, text, text, text, text, text, text, integer
) TO service_role;

-- ─────────────────────────────────────────────────────────────────────────
-- 7. REVOGAÇÃO E SEGURANÇA DE FUNÇÕES AUXILIARES PÚBLICAS
-- ─────────────────────────────────────────────────────────────────────────

REVOKE ALL ON FUNCTION public.generate_dependent_cpf_change_protocol_v1() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.generate_dependent_cpf_change_protocol_v1() TO service_role;

REVOKE ALL ON FUNCTION public.handle_dependent_cpf_change_requests_protocol() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_dependent_cpf_change_requests_protocol() TO service_role;

REVOKE ALL ON FUNCTION public.handle_dependent_cpf_change_requests_updated_at() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_dependent_cpf_change_requests_updated_at() TO service_role;

-- ─────────────────────────────────────────────────────────────────────────
-- 8. ATIVAÇÃO DE RLS E POLÍTICAS DE ACESSO
-- ─────────────────────────────────────────────────────────────────────────

ALTER TABLE public.dependent_cpf_change_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.dependent_cpf_change_secure_payloads ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.dependent_cpf_change_review_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.dependent_cpf_change_reservations ENABLE ROW LEVEL SECURITY;

-- Usuários authenticated comuns: visualizam apenas seus próprios pedidos
CREATE POLICY "Permitir que usuários leiam os próprios protocolos de dependentes"
ON public.dependent_cpf_change_requests
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Admins Master/Dev: visualizam todos os protocolos de dependentes
CREATE POLICY "Permitir que admins leiam todos os protocolos de dependentes"
ON public.dependent_cpf_change_requests
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 
    FROM public.profiles p 
    WHERE p.id = auth.uid() 
      AND p.role IN ('admin', 'admin_master', 'admin_dev')
  )
);

-- ─────────────────────────────────────────────────────────────────────────
-- 9. CONTROLE DE GRANTS MÍNIMOS
-- ─────────────────────────────────────────────────────────────────────────

-- Tabela Pública
REVOKE ALL ON TABLE public.dependent_cpf_change_requests FROM public, anon, authenticated;
GRANT SELECT ON TABLE public.dependent_cpf_change_requests TO authenticated;
GRANT ALL ON TABLE public.dependent_cpf_change_requests TO service_role;

-- Tabelas Privadas
REVOKE ALL ON TABLE private.dependent_cpf_change_secure_payloads FROM public, anon, authenticated;
GRANT ALL ON TABLE private.dependent_cpf_change_secure_payloads TO service_role;

REVOKE ALL ON TABLE private.dependent_cpf_change_review_data FROM public, anon, authenticated;
GRANT ALL ON TABLE private.dependent_cpf_change_review_data TO service_role;

REVOKE ALL ON TABLE private.dependent_cpf_change_reservations FROM public, anon, authenticated;
GRANT ALL ON TABLE private.dependent_cpf_change_reservations TO service_role;
