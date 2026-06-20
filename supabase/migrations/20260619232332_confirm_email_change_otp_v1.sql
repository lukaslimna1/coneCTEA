-- =========================================================================
-- ConeCTEA — Confirmação Segura e Consolidação do OTP de Alteração de E-mail
--
-- MIGRATION: 20260619232332_confirm_email_change_otp_v1.sql
-- OBJETIVO:
--   1. Criar a função conectea_confirm_email_change_otp_v1 para validação
--      atômica, consumo do OTP e criação do protocolo de alteração.
--   2. Criar a função conectea_consolidate_email_change_success_v1 para
--      consolidação definitiva do novo e-mail no profiles e no protocolo.
--   3. Criar a função conectea_consolidate_email_change_failure_v1 para
--      registro de falha técnica ou de credenciais na aplicação.
--   4. Implementar restrições severas de privilégios via RLS e Grants (service_role).
--
-- STATUS: Criação local da migration para auditoria e testes de sintaxe.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. FUNÇÕES PRIVADAS DE NEGÓCIO E CONTROLE
-- ─────────────────────────────────────────────────────────────────────────

-- A. Função Privada: private.conectea_confirm_email_change_otp_v1
CREATE OR REPLACE FUNCTION private.conectea_confirm_email_change_otp_v1(
  p_user_id uuid,
  p_session_id uuid,
  p_session_hmac text,
  p_session_hmac_key_version integer,
  p_code_hmac text,
  p_code_hmac_key_version integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_now timestamptz;
  v_profile_exists boolean;
  v_profile_email text;

  -- Variáveis do Ciclo Ativo
  v_cycle_id uuid;
  v_cycle_reauth_session_hmac text;
  v_cycle_reauth_key_version integer;
  v_cycle_destination_hmac text;
  v_cycle_destination_masked text;
  v_cycle_destination_ciphertext text;
  v_cycle_destination_nonce text;
  v_cycle_destination_auth_tag text;
  v_cycle_encryption_algorithm text;
  v_cycle_encryption_key_version integer;

  -- Variáveis do Desafio Ativo
  v_challenge_id uuid;
  v_challenge_state text;
  v_delivery_status text;
  v_challenge_code_hmac text;
  v_challenge_code_version integer;
  v_challenge_attempts integer;
  v_challenge_max_attempts integer;
  v_challenge_expires_at timestamptz;
  v_challenge_idempotency_key uuid;

  -- Variáveis da Reserva
  v_reservation_id uuid;
  v_reservation_state text;

  -- Variáveis para criação do Protocolo
  v_request_id uuid;
  v_old_local text;
  v_old_domain text;
  v_old_masked text;
  v_protocol_number text;
BEGIN
  -- 1. Validação de Parâmetros de Entrada
  IF p_user_id IS NULL
     OR p_session_id IS NULL
     OR p_session_hmac IS NULL
     OR trim(both from p_session_hmac) = ''
     OR p_session_hmac_key_version IS NULL
     OR p_session_hmac_key_version <> 1
     OR p_code_hmac IS NULL
     OR trim(both from p_code_hmac) = ''
     OR p_code_hmac_key_version IS NULL
     OR p_code_hmac_key_version <> 1
  THEN
    RETURN jsonb_build_object('result', 'invalid_request');
  END IF;

  v_now := transaction_timestamp();

  -- 2. Validação da Sessão Ativa
  IF NOT private.conectea_is_active_auth_session_v1(p_user_id, p_session_id) THEN
    RETURN jsonb_build_object('result', 'unauthorized');
  END IF;

  -- 3. Locks pessimistas em ordem hierárquica estrita
  -- Lock 1: profiles
  SELECT true, email INTO v_profile_exists, v_profile_email
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_profile_exists IS NOT TRUE THEN
    RETURN jsonb_build_object('result', 'unauthorized');
  END IF;

  -- Lock 2: cycles (busca ciclo aberto do usuário)
  SELECT
    id, reauth_session_hmac, reauth_session_hmac_key_version,
    destination_hmac, destination_masked, destination_ciphertext,
    destination_nonce, destination_auth_tag, encryption_algorithm, encryption_key_version
  INTO
    v_cycle_id, v_cycle_reauth_session_hmac, v_cycle_reauth_key_version,
    v_cycle_destination_hmac, v_cycle_destination_masked, v_cycle_destination_ciphertext,
    v_cycle_destination_nonce, v_cycle_destination_auth_tag, v_cycle_encryption_algorithm, v_cycle_encryption_key_version
  FROM private.account_change_challenge_cycles
  WHERE user_id = p_user_id
    AND purpose = 'email_change'
    AND closed_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'flow_not_found');
  END IF;

  -- Validar se a prova recente de reautenticação bate com a sessão informada
  IF v_cycle_reauth_session_hmac <> p_session_hmac
     OR v_cycle_reauth_key_version <> p_session_hmac_key_version
  THEN
    RETURN jsonb_build_object('result', 'unauthorized');
  END IF;

  -- Lock 3: challenges (busca desafio ativo associado ao ciclo)
  SELECT
    id, challenge_state, delivery_status, code_hmac, code_hmac_key_version,
    attempts, max_attempts, expires_at, idempotency_key
  INTO
    v_challenge_id, v_challenge_state, v_delivery_status, v_challenge_code_hmac, v_challenge_code_version,
    v_challenge_attempts, v_challenge_max_attempts, v_challenge_expires_at, v_challenge_idempotency_key
  FROM private.account_change_challenges
  WHERE cycle_id = v_cycle_id
    AND user_id = p_user_id
    AND purpose = 'email_change'
    AND challenge_state = 'active'
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'otp_invalid');
  END IF;

  -- Lock 4: reservations (busca reserva vinculada ao ciclo)
  SELECT id, reservation_state INTO v_reservation_id, v_reservation_state
  FROM private.account_change_email_reservations
  WHERE cycle_id = v_cycle_id
    AND user_id = p_user_id
    AND purpose = 'email_change'
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'flow_not_found');
  END IF;

  -- 4. Validação Lógica de Expiração
  IF v_now >= v_challenge_expires_at THEN
    -- Marca o desafio como expirado
    UPDATE private.account_change_challenges
    SET challenge_state = 'expired',
        expired_at = v_challenge_expires_at,
        updated_at = v_now
    WHERE id = v_challenge_id;

    -- Fecha o ciclo correspondente
    UPDATE private.account_change_challenge_cycles
    SET closed_at = v_now,
        updated_at = v_now
    WHERE id = v_cycle_id;

    -- Libera a reserva
    UPDATE private.account_change_email_reservations
    SET reservation_state = 'released',
        cycle_closed_at = v_now,
        released_at = v_now,
        release_reason = 'otp_expired',
        updated_at = v_now
    WHERE id = v_reservation_id;

    RETURN jsonb_build_object('result', 'otp_expired');
  END IF;

  -- 5. Validação de Tentativas Excedidas antes da digitação
  IF v_challenge_attempts >= v_challenge_max_attempts THEN
    UPDATE private.account_change_challenges
    SET challenge_state = 'blocked',
        blocked_at = v_now,
        updated_at = v_now
    WHERE id = v_challenge_id;

    UPDATE private.account_change_challenge_cycles
    SET closed_at = v_now,
        updated_at = v_now
    WHERE id = v_cycle_id;

    UPDATE private.account_change_email_reservations
    SET reservation_state = 'released',
        cycle_closed_at = v_now,
        released_at = v_now,
        release_reason = 'otp_attempts_exceeded',
        updated_at = v_now
    WHERE id = v_reservation_id;

    RETURN jsonb_build_object('result', 'otp_attempts_exceeded');
  END IF;

  -- 6. Validação do Código (Compara HMACs)
  IF v_challenge_code_hmac <> p_code_hmac OR v_challenge_code_version <> p_code_hmac_key_version THEN
    -- Incrementa tentativas incorretas
    v_challenge_attempts := v_challenge_attempts + 1;

    IF v_challenge_attempts >= v_challenge_max_attempts THEN
      -- Bloqueia por excesso de tentativas
      UPDATE private.account_change_challenges
      SET attempts = v_challenge_attempts,
          challenge_state = 'blocked',
          blocked_at = v_now,
          updated_at = v_now
      WHERE id = v_challenge_id;

      UPDATE private.account_change_challenge_cycles
      SET closed_at = v_now,
          updated_at = v_now
      WHERE id = v_cycle_id;

      UPDATE private.account_change_email_reservations
      SET reservation_state = 'released',
          cycle_closed_at = v_now,
          released_at = v_now,
          release_reason = 'otp_attempts_exceeded',
          updated_at = v_now
      WHERE id = v_reservation_id;

      RETURN jsonb_build_object('result', 'otp_attempts_exceeded');
    ELSE
      -- Apenas registra a tentativa falha
      UPDATE private.account_change_challenges
      SET attempts = v_challenge_attempts,
          updated_at = v_now
      WHERE id = v_challenge_id;

      RETURN jsonb_build_object(
        'result', 'otp_invalid',
        'attempts_remaining', (v_challenge_max_attempts - v_challenge_attempts)
      );
    END IF;
  END IF;

  -- 7. OTP Correto: Inicia fluxo de consolidação pós-OTP
  -- Marca o desafio como consumido
  UPDATE private.account_change_challenges
  SET challenge_state = 'consumed',
      consumed_at = v_now,
      updated_at = v_now
  WHERE id = v_challenge_id;

  -- Fecha o ciclo de desafios
  UPDATE private.account_change_challenge_cycles
  SET closed_at = v_now,
      updated_at = v_now
  WHERE id = v_cycle_id;

  -- Gerar mascaramento para o e-mail antigo
  v_old_local := split_part(v_profile_email, '@', 1);
  v_old_domain := split_part(v_profile_email, '@', 2);
  IF length(v_old_local) >= 3 THEN
    v_old_masked := substring(v_old_local, 1, 2) || '***@' || v_old_domain;
  ELSIF length(v_old_local) > 0 THEN
    v_old_masked := substring(v_old_local, 1, 1) || '***@' || v_old_domain;
  ELSE
    v_old_masked := '***@' || v_old_domain;
  END IF;

  -- Gerar id do protocolo
  v_request_id := gen_random_uuid();

  -- Criar o protocolo de alteração em public.account_change_requests
  INSERT INTO public.account_change_requests (
    id,
    user_id,
    type,
    status,
    old_value_masked,
    new_value_masked,
    new_value_hmac,
    idempotency_key,
    created_at,
    updated_at
  ) VALUES (
    v_request_id,
    p_user_id,
    'email',
    'applying',
    v_old_masked,
    v_cycle_destination_masked,
    v_cycle_destination_hmac,
    v_challenge_idempotency_key,
    v_now,
    v_now
  )
  RETURNING protocol_number INTO v_protocol_number;

  -- Atualizar a reserva de e-mail vinculando-a ao protocolo criado
  UPDATE private.account_change_email_reservations
  SET reservation_state = 'attached',
      request_id = v_request_id,
      cycle_closed_at = v_now,
      updated_at = v_now
  WHERE id = v_reservation_id;

  -- Retornar os materiais necessários para a Edge Function descriptografar o destino e atualizar no Auth
  RETURN jsonb_build_object(
    'result', 'otp_valid',
    'request_id', v_request_id,
    'protocol_number', v_protocol_number,
    'destination_ciphertext', v_cycle_destination_ciphertext,
    'destination_nonce', v_cycle_destination_nonce,
    'destination_auth_tag', v_cycle_destination_auth_tag,
    'destination_encryption_algorithm', v_cycle_encryption_algorithm,
    'destination_encryption_key_version', v_cycle_encryption_key_version
  );
END;
$$;

-- B. Função Privada: private.conectea_consolidate_email_change_success_v1
CREATE OR REPLACE FUNCTION private.conectea_consolidate_email_change_success_v1(
  p_request_id uuid,
  p_user_id uuid,
  p_new_email_clear text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_now timestamptz;
  v_profile_exists boolean;
  v_request_exists boolean;
  v_reservation_id uuid;
BEGIN
  -- 1. Validação de Parâmetros
  IF p_request_id IS NULL OR p_user_id IS NULL OR p_new_email_clear IS NULL OR trim(both from p_new_email_clear) = '' THEN
    RETURN jsonb_build_object('result', 'invalid_request');
  END IF;

  v_now := transaction_timestamp();

  -- 2. Locks pessimistas
  -- Lock 1: profiles
  SELECT true INTO v_profile_exists
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_profile_exists IS NOT TRUE THEN
    RETURN jsonb_build_object('result', 'unauthorized');
  END IF;

  -- Lock 2: requests
  SELECT true INTO v_request_exists
  FROM public.account_change_requests
  WHERE id = p_request_id
    AND user_id = p_user_id
    AND type = 'email'
    AND status = 'applying'
  FOR UPDATE;

  IF NOT FOUND OR v_request_exists IS NOT TRUE THEN
    RETURN jsonb_build_object('result', 'request_not_found');
  END IF;

  -- Lock 3: email reservations
  SELECT id INTO v_reservation_id
  FROM private.account_change_email_reservations
  WHERE request_id = p_request_id
    AND user_id = p_user_id
    AND purpose = 'email_change'
    AND reservation_state = 'attached'
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'reservation_not_found');
  END IF;

  -- 3. Atualizar e-mail no profiles público
  UPDATE public.profiles
  SET email = p_new_email_clear,
      updated_at = v_now
  WHERE id = p_user_id;

  -- 4. Atualizar status do protocolo para completed
  UPDATE public.account_change_requests
  SET status = 'completed',
      application_completed_at = v_now,
      updated_at = v_now
  WHERE id = p_request_id;

  -- 5. Liberar a reserva de e-mail
  UPDATE private.account_change_email_reservations
  SET reservation_state = 'released',
      released_at = v_now,
      release_reason = 'completed',
      updated_at = v_now
  WHERE id = v_reservation_id;

  RETURN jsonb_build_object('result', 'consolidated_success');
END;
$$;

-- C. Função Privada: private.conectea_consolidate_email_change_failure_v1
CREATE OR REPLACE FUNCTION private.conectea_consolidate_email_change_failure_v1(
  p_request_id uuid,
  p_user_id uuid,
  p_failure_code text,
  p_failure_reason text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_now timestamptz;
  v_profile_exists boolean;
  v_request_exists boolean;
  v_reservation_id uuid;
BEGIN
  -- 1. Validação de Parâmetros
  IF p_request_id IS NULL OR p_user_id IS NULL OR p_failure_code IS NULL OR trim(both from p_failure_code) = '' THEN
    RETURN jsonb_build_object('result', 'invalid_request');
  END IF;

  v_now := transaction_timestamp();

  -- 2. Locks pessimistas
  -- Lock 1: profiles
  SELECT true INTO v_profile_exists
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_profile_exists IS NOT TRUE THEN
    RETURN jsonb_build_object('result', 'unauthorized');
  END IF;

  -- Lock 2: requests
  SELECT true INTO v_request_exists
  FROM public.account_change_requests
  WHERE id = p_request_id
    AND user_id = p_user_id
    AND type = 'email'
    AND status = 'applying'
  FOR UPDATE;

  IF NOT FOUND OR v_request_exists IS NOT TRUE THEN
    RETURN jsonb_build_object('result', 'request_not_found');
  END IF;

  -- Lock 3: email reservations
  SELECT id INTO v_reservation_id
  FROM private.account_change_email_reservations
  WHERE request_id = p_request_id
    AND user_id = p_user_id
    AND purpose = 'email_change'
    AND reservation_state = 'attached'
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'reservation_not_found');
  END IF;

  -- 3. Atualizar status do protocolo para falha
  UPDATE public.account_change_requests
  SET status = 'application_failed',
      failure_code = p_failure_code,
      updated_at = v_now
  WHERE id = p_request_id;

  -- 4. Liberar a reserva com a respectiva justificativa
  UPDATE private.account_change_email_reservations
  SET reservation_state = 'released',
      released_at = v_now,
      release_reason = coalesce(p_failure_reason, p_failure_code),
      updated_at = v_now
  WHERE id = v_reservation_id;

  RETURN jsonb_build_object('result', 'consolidated_failure');
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────
-- 2. WRAPPERS RPC PUBLICAS E GRANTS RESTRITOS
-- ─────────────────────────────────────────────────────────────────────────

-- A. RPC pública: public.conectea_confirm_email_change_otp_v1
CREATE OR REPLACE FUNCTION public.conectea_confirm_email_change_otp_v1(
  p_user_id uuid,
  p_session_id uuid,
  p_session_hmac text,
  p_session_hmac_key_version integer,
  p_code_hmac text,
  p_code_hmac_key_version integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
BEGIN
  RETURN private.conectea_confirm_email_change_otp_v1(
    p_user_id := p_user_id,
    p_session_id := p_session_id,
    p_session_hmac := p_session_hmac,
    p_session_hmac_key_version := p_session_hmac_key_version,
    p_code_hmac := p_code_hmac,
    p_code_hmac_key_version := p_code_hmac_key_version
  );
END;
$$;

-- B. RPC pública: public.conectea_consolidate_email_change_success_v1
CREATE OR REPLACE FUNCTION public.conectea_consolidate_email_change_success_v1(
  p_request_id uuid,
  p_user_id uuid,
  p_new_email_clear text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
BEGIN
  RETURN private.conectea_consolidate_email_change_success_v1(
    p_request_id := p_request_id,
    p_user_id := p_user_id,
    p_new_email_clear := p_new_email_clear
  );
END;
$$;

-- C. RPC pública: public.conectea_consolidate_email_change_failure_v1
CREATE OR REPLACE FUNCTION public.conectea_consolidate_email_change_failure_v1(
  p_request_id uuid,
  p_user_id uuid,
  p_failure_code text,
  p_failure_reason text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
BEGIN
  RETURN private.conectea_consolidate_email_change_failure_v1(
    p_request_id := p_request_id,
    p_user_id := p_user_id,
    p_failure_code := p_failure_code,
    p_failure_reason := p_failure_reason
  );
END;
$$;

-- Revoga privilégios para usuários comuns (anon, authenticated, PUBLIC) em todas as wrappers
REVOKE ALL ON FUNCTION public.conectea_confirm_email_change_otp_v1(uuid, uuid, text, integer, text, integer) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.conectea_consolidate_email_change_success_v1(uuid, uuid, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.conectea_consolidate_email_change_failure_v1(uuid, uuid, text, text) FROM PUBLIC, anon, authenticated;

-- Concede execução exclusiva à service_role
GRANT EXECUTE ON FUNCTION public.conectea_confirm_email_change_otp_v1(uuid, uuid, text, integer, text, integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.conectea_consolidate_email_change_success_v1(uuid, uuid, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.conectea_consolidate_email_change_failure_v1(uuid, uuid, text, text) TO service_role;

-- Comentários de Documentação de Segurança
COMMENT ON FUNCTION public.conectea_confirm_email_change_otp_v1 IS
  'Wrapper RPC publica restrita a service_role para confirmacao e consumo atômico do OTP. Cria o protocolo account_change_requests em status applying e retorna o payload criptografado.';

COMMENT ON FUNCTION public.conectea_consolidate_email_change_success_v1 IS
  'Wrapper RPC publica restrita a service_role para consolidar o sucesso da aplicacao da mudanca de email. Atualiza o email em profiles e o protocolo para completed.';

COMMENT ON FUNCTION public.conectea_consolidate_email_change_failure_v1 IS
  'Wrapper RPC publica restrita a service_role para consolidar falhas na aplicacao da mudanca de email. Atualiza o status do protocolo para failed.';
