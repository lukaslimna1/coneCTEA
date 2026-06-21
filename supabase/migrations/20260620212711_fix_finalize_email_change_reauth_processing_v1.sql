-- =========================================================================
-- ConeCTEA — Finalização de Sucesso da Reautenticação
--
-- MIGRATION: 20260620212711_fix_finalize_email_change_reauth_processing_v1.sql
-- OBJETIVO:
--   1. Corrigir RPC conectea_finalize_email_change_reauth_success_v1 para marcar tentativa como failed_technical em saídas precoces e unique_violations.
--   2. Evitar que tentativas em processamento fiquem presas em caso de validações falhas (ex: attempt_mismatch, destination_conflict).
--
-- STATUS: Nova migration de correção criada localmente. Não aplicada neste turno.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. FUNÇÃO PRIVADA: private.conectea_finalize_email_change_reauth_success_v1
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION private.conectea_finalize_email_change_reauth_success_v1(
  p_attempt_id uuid,
  p_user_id uuid,
  p_session_id uuid,
  p_session_hmac text,
  p_session_hmac_key_version integer,

  p_destination_email_normalized text,
  p_destination_hmac text,
  p_destination_hmac_key_version integer,
  p_destination_masked text,
  p_destination_ciphertext text,
  p_destination_nonce text,
  p_destination_auth_tag text,
  p_destination_encryption_algorithm text,
  p_destination_encryption_key_version integer,

  p_code_hmac text,
  p_code_hmac_key_version integer,
  p_code_ciphertext text,
  p_code_nonce text,
  p_code_auth_tag text,
  p_code_encryption_algorithm text,
  p_code_encryption_key_version integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_profile_exists boolean;
  v_profile_email text;
  v_auth_email text;
  v_now timestamptz;

  -- Variáveis de busca da tentativa
  v_attempt_state text;
  v_processing_expires_at timestamptz;

  -- Variáveis para tratamento de idempotência terminal (succeeded)
  v_result_cycle_id uuid;
  v_existing_challenge_id uuid;
  v_existing_delivery_status text;
  v_existing_send_sequence integer;

  -- Variável de concorrência na reserva ativa
  v_existing_reservation_id uuid;

  -- UUIDs de sucesso gerados no PostgreSQL
  v_cycle_id uuid;
  v_challenge_id uuid;
  v_challenge_idempotency_key uuid;

  -- Diagnóstico de exceções
  v_constraint_name text;
BEGIN
  -- 1. Validação de Parâmetros de Entrada Básica e Geral
  IF p_attempt_id IS NULL
     OR p_user_id IS NULL
     OR p_session_id IS NULL

     -- session_hmac
     OR p_session_hmac IS NULL
     OR trim(both from p_session_hmac) = ''
     OR p_session_hmac <> trim(both from p_session_hmac)
     OR p_session_hmac ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
     OR p_session_hmac ~ '^eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$'
     OR p_session_hmac_key_version IS NULL
     OR p_session_hmac_key_version <> 1

     -- p_destination_email_normalized (E-mail transitório)
     OR p_destination_email_normalized IS NULL
     OR trim(both from p_destination_email_normalized) = ''
     OR p_destination_email_normalized <> trim(both from p_destination_email_normalized)
     OR p_destination_email_normalized <> lower(p_destination_email_normalized)
     OR length(p_destination_email_normalized) < 3
     OR length(p_destination_email_normalized) > 254
     OR p_destination_email_normalized ~ '[\s\t\r\n]'
     OR p_destination_email_normalized !~ '^[^@]+@[^@]+$'

     -- p_destination_hmac e máscara
     OR p_destination_hmac IS NULL
     OR trim(both from p_destination_hmac) = ''
     OR p_destination_hmac <> trim(both from p_destination_hmac)
     OR p_destination_hmac_key_version IS NULL
     OR p_destination_hmac_key_version <> 1
     OR p_destination_masked IS NULL
     OR trim(both from p_destination_masked) = ''
     OR p_destination_masked <> trim(both from p_destination_masked)
     OR length(p_destination_masked) > 254

     -- Criptografia do destino
     OR p_destination_ciphertext IS NULL
     OR p_destination_ciphertext = ''
     OR p_destination_ciphertext <> trim(both from p_destination_ciphertext)
     OR length(p_destination_ciphertext) > 512
     OR p_destination_ciphertext !~ '^[A-Za-z0-9_-]+$'
     OR p_destination_nonce IS NULL
     OR p_destination_nonce !~ '^[A-Za-z0-9_-]{16}$'
     OR p_destination_auth_tag IS NULL
     OR p_destination_auth_tag !~ '^[A-Za-z0-9_-]{22}$'
     OR p_destination_encryption_algorithm IS NULL
     OR p_destination_encryption_algorithm <> 'aes-256-gcm'
     OR p_destination_encryption_key_version IS NULL
     OR p_destination_encryption_key_version <> 1

     -- Material do OTP
     OR p_code_hmac IS NULL
     OR trim(both from p_code_hmac) = ''
     OR p_code_hmac <> trim(both from p_code_hmac)
     OR p_code_hmac_key_version IS NULL
     OR p_code_hmac_key_version <> 1
     OR p_code_ciphertext IS NULL
     OR p_code_ciphertext = ''
     OR p_code_ciphertext <> trim(both from p_code_ciphertext)
     OR length(p_code_ciphertext) > 128
     OR p_code_ciphertext !~ '^[A-Za-z0-9_-]+$'
     OR p_code_nonce IS NULL
     OR p_code_nonce !~ '^[A-Za-z0-9_-]{16}$'
     OR p_code_auth_tag IS NULL
     OR p_code_auth_tag !~ '^[A-Za-z0-9_-]{22}$'
     OR p_code_encryption_algorithm IS NULL
     OR p_code_encryption_algorithm <> 'aes-256-gcm'
     OR p_code_encryption_key_version IS NULL
     OR p_code_encryption_key_version <> 1
  THEN
    UPDATE private.account_change_reauth_attempts
    SET attempt_state = 'failed_technical',
        failed_technical_code_private = 'invalid_request',
        finalized_at = transaction_timestamp(),
        purge_after = transaction_timestamp() + interval '10 minutes'
    WHERE id = p_attempt_id AND attempt_state = 'processing';
    RETURN jsonb_build_object('result', 'invalid_request');
  END IF;

  -- 2. Validação da Sessão Ativa
  IF NOT private.conectea_is_active_auth_session_v1(p_user_id, p_session_id) THEN
    UPDATE private.account_change_reauth_attempts
    SET attempt_state = 'failed_technical',
        failed_technical_code_private = 'session_invalid',
        finalized_at = transaction_timestamp(),
        purge_after = transaction_timestamp() + interval '10 minutes'
    WHERE id = p_attempt_id AND attempt_state = 'processing';
    RETURN jsonb_build_object('result', 'session_invalid');
  END IF;

  -- 3. Locks Ordinários Estáveis
  -- Lock 1: public.profiles
  SELECT true, email INTO v_profile_exists, v_profile_email
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_profile_exists IS NOT TRUE THEN
    UPDATE private.account_change_reauth_attempts
    SET attempt_state = 'failed_technical',
        failed_technical_code_private = 'session_invalid_profile',
        finalized_at = transaction_timestamp(),
        purge_after = transaction_timestamp() + interval '10 minutes'
    WHERE id = p_attempt_id AND attempt_state = 'processing';
    RETURN jsonb_build_object('result', 'session_invalid');
  END IF;

  -- Lock 2: private.account_change_reauth_attempts
  SELECT attempt_state, processing_expires_at, result_cycle_id
  INTO v_attempt_state, v_processing_expires_at, v_result_cycle_id
  FROM private.account_change_reauth_attempts
  WHERE id = p_attempt_id
  FOR UPDATE;

  -- Se tentativa não existe ou houver qualquer divergência cadastral com os parâmetros de contexto
  IF NOT FOUND
     OR EXISTS (
       SELECT 1
       FROM private.account_change_reauth_attempts
       WHERE id = p_attempt_id
         AND (
           user_id <> p_user_id
           OR purpose <> 'email_change_reauth'
           OR session_hmac <> p_session_hmac
           OR session_hmac_key_version <> p_session_hmac_key_version
         )
     )
  THEN
    UPDATE private.account_change_reauth_attempts
    SET attempt_state = 'failed_technical',
        failed_technical_code_private = 'attempt_mismatch',
        finalized_at = transaction_timestamp(),
        purge_after = transaction_timestamp() + interval '10 minutes'
    WHERE id = p_attempt_id AND attempt_state = 'processing';
    RETURN jsonb_build_object('result', 'attempt_mismatch');
  END IF;

  -- 4. Idempotência Terminal
  -- 4.a. Casos de encerramento em falha ou expirado
  IF v_attempt_state IN ('failed_credentials', 'failed_technical', 'expired') THEN
    RETURN jsonb_build_object(
      'result', 'attempt_already_finalized',
      'attempt_state', v_attempt_state
    );
  END IF;

  -- 4.b. Casos de tentativa já concluída com sucesso (succeeded)
  IF v_attempt_state = 'succeeded' THEN
    SELECT id, delivery_status, send_sequence
    INTO v_existing_challenge_id, v_existing_delivery_status, v_existing_send_sequence
    FROM private.account_change_challenges
    WHERE cycle_id = v_result_cycle_id
      AND send_sequence = 1;

    RETURN jsonb_build_object(
      'result', 'finalized_success',
      'cycle_id', v_result_cycle_id,
      'challenge_id', v_existing_challenge_id,
      'delivery_status', v_existing_delivery_status,
      'send_sequence', v_existing_send_sequence,
      'should_send', (v_existing_delivery_status = 'pending'),
      'reused', true
    );
  END IF;

  -- Instante unificado da transação
  v_now := transaction_timestamp();

  -- 5. Validação do TTL de Processamento
  IF v_now >= v_processing_expires_at THEN
    -- Expira atomicamente a tentativa sem criar ciclos ou reservas
    UPDATE private.account_change_reauth_attempts
    SET attempt_state = 'expired',
        finalized_at = v_now,
        purge_after = v_now + interval '10 minutes'
    WHERE id = p_attempt_id AND attempt_state = 'processing';

    RETURN jsonb_build_object('result', 'attempt_expired');
  END IF;

  -- 6. Lock Lógico do Destino (Advisory Lock Transacional)
  -- Adquire o lock lógico transacional com base no HMAC do destino para evitar race conditions
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'conectea_email_change:' || p_destination_hmac,
      0
    )
  );

  -- 7. Validação de Protocolo Existente
  -- Verifica se existe uma solicitação de alteração de e-mail aberta para o usuário
  IF EXISTS (
    SELECT 1
    FROM public.account_change_requests
    WHERE user_id = p_user_id
      AND type = 'email'
      AND closed_at IS NULL
  ) THEN
    UPDATE private.account_change_reauth_attempts
    SET attempt_state = 'failed_technical',
        failed_technical_code_private = 'protocol_already_exists',
        finalized_at = transaction_timestamp(),
        purge_after = transaction_timestamp() + interval '10 minutes'
    WHERE id = p_attempt_id AND attempt_state = 'processing';
    RETURN jsonb_build_object('result', 'protocol_already_exists');
  END IF;

  -- 8. Validação de Ciclo Aberto Existente
  -- Verifica se existe algum ciclo de desafios aberto para o usuário
  IF EXISTS (
    SELECT 1
    FROM private.account_change_challenge_cycles
    WHERE user_id = p_user_id
      AND purpose = 'email_change'
      AND closed_at IS NULL
  ) THEN
    UPDATE private.account_change_reauth_attempts
    SET attempt_state = 'failed_technical',
        failed_technical_code_private = 'flow_already_exists',
        finalized_at = transaction_timestamp(),
        purge_after = transaction_timestamp() + interval '10 minutes'
    WHERE id = p_attempt_id AND attempt_state = 'processing';
    RETURN jsonb_build_object('result', 'flow_already_exists');
  END IF;

  -- 9. Consistência Auth / Profile para o E-mail Canônico
  -- Recupera o e-mail cadastrado na tabela de autenticação
  SELECT email INTO v_auth_email
  FROM auth.users
  WHERE id = p_user_id;

  IF v_auth_email IS NULL
     OR v_profile_email IS NULL
     OR lower(btrim(v_auth_email)) <> lower(btrim(v_profile_email))
  THEN
    UPDATE private.account_change_reauth_attempts
    SET attempt_state = 'failed_technical',
        failed_technical_code_private = 'account_data_conflict',
        finalized_at = transaction_timestamp(),
        purge_after = transaction_timestamp() + interval '10 minutes'
    WHERE id = p_attempt_id AND attempt_state = 'processing';
    RETURN jsonb_build_object('result', 'account_data_conflict');
  END IF;

  -- 10. E-mail de Destino Igual ao Atual
  IF p_destination_email_normalized = lower(btrim(v_auth_email)) THEN
    UPDATE private.account_change_reauth_attempts
    SET attempt_state = 'failed_technical',
        failed_technical_code_private = 'dest_same_as_current',
        finalized_at = transaction_timestamp(),
        purge_after = transaction_timestamp() + interval '10 minutes'
    WHERE id = p_attempt_id AND attempt_state = 'processing';
    RETURN jsonb_build_object('result', 'destination_same_as_current');
  END IF;

  -- 11. Duplicidade em Outra Conta no Supabase Auth
  IF EXISTS (
    SELECT 1
    FROM auth.users
    WHERE lower(btrim(email)) = p_destination_email_normalized
      AND id <> p_user_id
  ) THEN
    UPDATE private.account_change_reauth_attempts
    SET attempt_state = 'failed_technical',
        failed_technical_code_private = 'destination_conflict_auth',
        finalized_at = transaction_timestamp(),
        purge_after = transaction_timestamp() + interval '10 minutes'
    WHERE id = p_attempt_id AND attempt_state = 'processing';
    RETURN jsonb_build_object('result', 'destination_conflict');
  END IF;

  -- 12. Reserva Ativa do E-mail de Destino
  -- Tenta travar a reserva caso exista algum registro ativo/anexado para o destino
  SELECT id INTO v_existing_reservation_id
  FROM private.account_change_email_reservations
  WHERE destination_hmac = p_destination_hmac
    AND reservation_state IN ('active', 'attached')
    AND released_at IS NULL
  FOR UPDATE;

  IF FOUND THEN
    UPDATE private.account_change_reauth_attempts
    SET attempt_state = 'failed_technical',
        failed_technical_code_private = 'destination_conflict_rsrv',
        finalized_at = transaction_timestamp(),
        purge_after = transaction_timestamp() + interval '10 minutes'
    WHERE id = p_attempt_id AND attempt_state = 'processing';
    RETURN jsonb_build_object('result', 'destination_conflict');
  END IF;

  -- 13. Geração de UUIDs Operacionais no PostgreSQL
  v_cycle_id := gen_random_uuid();
  v_challenge_id := gen_random_uuid();
  v_challenge_idempotency_key := gen_random_uuid();

  -- 14. Sub-bloco Transacional Atômico para Inserções
  BEGIN
    -- 14.a. Inserir Ciclo
    INSERT INTO private.account_change_challenge_cycles (
      id,
      user_id,
      purpose,
      destination_hmac,
      destination_hmac_key_version,
      destination_ciphertext,
      destination_nonce,
      destination_auth_tag,
      destination_masked,
      encryption_algorithm,
      encryption_key_version,
      cooldown_until,
      closed_at,
      reauth_session_hmac,
      reauth_session_hmac_key_version,
      reauthenticated_at,
      reauth_method,
      created_at,
      updated_at
    ) VALUES (
      v_cycle_id,
      p_user_id,
      'email_change',
      p_destination_hmac,
      1,
      p_destination_ciphertext,
      p_destination_nonce,
      p_destination_auth_tag,
      p_destination_masked,
      'aes-256-gcm',
      1,
      NULL,
      NULL,
      p_session_hmac,
      1,
      v_now,
      'password',
      v_now,
      v_now
    );

    -- 14.b. Inserir Reserva Exclusiva
    INSERT INTO private.account_change_email_reservations (
      user_id,
      purpose,
      destination_hmac,
      destination_hmac_key_version,
      cycle_id,
      request_id,
      request_type,
      reservation_state,
      reserved_at,
      cycle_hold_until,
      cycle_closed_at,
      released_at,
      release_reason,
      created_at,
      updated_at
    ) VALUES (
      p_user_id,
      'email_change',
      p_destination_hmac,
      1,
      v_cycle_id,
      NULL,
      'email',
      'active',
      v_now,
      NULL,
      NULL,
      NULL,
      NULL,
      v_now,
      v_now
    );

    -- 14.c. Inserir Primeiro Desafio OTP (Pending)
    INSERT INTO private.account_change_challenges (
      id,
      cycle_id,
      user_id,
      purpose,
      idempotency_key,
      challenge_state,
      delivery_status,
      delivery_attempts,
      last_delivery_attempt_at,
      sent_at,
      failed_at,
      delivery_failure_reason_private,
      send_sequence,
      code_hmac,
      code_hmac_key_version,
      expires_at,
      attempts,
      max_attempts,
      resend_available_at,
      code_ciphertext,
      code_nonce,
      code_auth_tag,
      code_encryption_algorithm,
      code_encryption_key_version,
      created_at,
      updated_at
    ) VALUES (
      v_challenge_id,
      v_cycle_id,
      p_user_id,
      'email_change',
      v_challenge_idempotency_key,
      'active',
      'pending',
      0,
      NULL,
      NULL,
      NULL,
      NULL,
      1,
      p_code_hmac,
      1,
      NULL,
      0,
      3,
      NULL,
      p_code_ciphertext,
      p_code_nonce,
      p_code_auth_tag,
      'aes-256-gcm',
      1,
      v_now,
      v_now
    );

    -- 14.d. Finalizar Tentativa como succeeded
    UPDATE private.account_change_reauth_attempts
    SET attempt_state = 'succeeded',
        finalized_at = v_now,
        result_cycle_id = v_cycle_id,
        result_cycle_purpose = 'email_change',
        purge_after = v_now + interval '10 minutes'
    WHERE id = p_attempt_id;

    -- 14.e. Limpar Throttles Aprovados
    DELETE FROM private.account_change_reauth_account_throttles
    WHERE user_id = p_user_id
      AND purpose = 'email_change_reauth';

    DELETE FROM private.account_change_reauth_throttles
    WHERE user_id = p_user_id
      AND purpose = 'email_change_reauth'
      AND session_hmac = p_session_hmac
      AND session_hmac_key_version = p_session_hmac_key_version;

  EXCEPTION
    WHEN unique_violation THEN
      GET STACKED DIAGNOSTICS v_constraint_name = CONSTRAINT_NAME;

      IF v_constraint_name = 'account_change_email_reservations_active_uniq_idx' THEN
        UPDATE private.account_change_reauth_attempts
        SET attempt_state = 'failed_technical',
            failed_technical_code_private = 'reservation_conflict',
            finalized_at = transaction_timestamp(),
            purge_after = transaction_timestamp() + interval '10 minutes'
        WHERE id = p_attempt_id AND attempt_state = 'processing';
        RETURN jsonb_build_object('result', 'destination_conflict');
      ELSIF v_constraint_name = 'account_change_challenge_cycles_open_idx' THEN
        UPDATE private.account_change_reauth_attempts
        SET attempt_state = 'failed_technical',
            failed_technical_code_private = 'cycle_conflict',
            finalized_at = transaction_timestamp(),
            purge_after = transaction_timestamp() + interval '10 minutes'
        WHERE id = p_attempt_id AND attempt_state = 'processing';
        RETURN jsonb_build_object('result', 'flow_already_exists');
      ELSIF v_constraint_name = 'account_change_challenges_active_uid_purpose_idx' THEN
        UPDATE private.account_change_reauth_attempts
        SET attempt_state = 'failed_technical',
            failed_technical_code_private = 'challenge_conflict',
            finalized_at = transaction_timestamp(),
            purge_after = transaction_timestamp() + interval '10 minutes'
        WHERE id = p_attempt_id AND attempt_state = 'processing';
        RETURN jsonb_build_object('result', 'flow_already_exists');
      ELSE
        UPDATE private.account_change_reauth_attempts
        SET attempt_state = 'failed_technical',
            failed_technical_code_private = 'unique_violation_unknown',
            finalized_at = transaction_timestamp(),
            purge_after = transaction_timestamp() + interval '10 minutes'
        WHERE id = p_attempt_id AND attempt_state = 'processing';
        RETURN jsonb_build_object('result', 'temporarily_unavailable');
      END IF;
  END;

  -- 15. Retorno de Sucesso com Resposta Conceitual da Edge Function
  RETURN jsonb_build_object(
    'result', 'finalized_success',
    'cycle_id', v_cycle_id,
    'challenge_id', v_challenge_id,
    'delivery_status', 'pending',
    'send_sequence', 1,
    'should_send', true,
    'reused', false
  );
END;
$$;

-- Revoga a execução pública da função privada
REVOKE ALL ON FUNCTION private.conectea_finalize_email_change_reauth_success_v1(
  uuid, uuid, uuid, text, integer, text, text, integer, text, text, text, text, text, integer, text, integer, text, text, text, text, integer
) FROM PUBLIC, anon, authenticated, service_role;


-- ─────────────────────────────────────────────────────────────────────────
-- 2. WRAPPER RPC PÚBLICA: public.conectea_finalize_email_change_reauth_success_v1
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_finalize_email_change_reauth_success_v1(
  p_attempt_id uuid,
  p_user_id uuid,
  p_session_id uuid,
  p_session_hmac text,
  p_session_hmac_key_version integer,

  p_destination_email_normalized text,
  p_destination_hmac text,
  p_destination_hmac_key_version integer,
  p_destination_masked text,
  p_destination_ciphertext text,
  p_destination_nonce text,
  p_destination_auth_tag text,
  p_destination_encryption_algorithm text,
  p_destination_encryption_key_version integer,

  p_code_hmac text,
  p_code_hmac_key_version integer,
  p_code_ciphertext text,
  p_code_nonce text,
  p_code_auth_tag text,
  p_code_encryption_algorithm text,
  p_code_encryption_key_version integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
BEGIN
  -- Delega exclusivamente para a rotina privada
  RETURN private.conectea_finalize_email_change_reauth_success_v1(
    p_attempt_id := p_attempt_id,
    p_user_id := p_user_id,
    p_session_id := p_session_id,
    p_session_hmac := p_session_hmac,
    p_session_hmac_key_version := p_session_hmac_key_version,

    p_destination_email_normalized := p_destination_email_normalized,
    p_destination_hmac := p_destination_hmac,
    p_destination_hmac_key_version := p_destination_hmac_key_version,
    p_destination_masked := p_destination_masked,
    p_destination_ciphertext := p_destination_ciphertext,
    p_destination_nonce := p_destination_nonce,
    p_destination_auth_tag := p_destination_auth_tag,
    p_destination_encryption_algorithm := p_destination_encryption_algorithm,
    p_destination_encryption_key_version := p_destination_encryption_key_version,

    p_code_hmac := p_code_hmac,
    p_code_hmac_key_version := p_code_hmac_key_version,
    p_code_ciphertext := p_code_ciphertext,
    p_code_nonce := p_code_nonce,
    p_code_auth_tag := p_code_auth_tag,
    p_code_encryption_algorithm := p_code_encryption_algorithm,
    p_code_encryption_key_version := p_code_encryption_key_version
  );
END;
$$;

-- Revoga privilégios para usuários comuns e públicos da RPC pública
REVOKE ALL ON FUNCTION public.conectea_finalize_email_change_reauth_success_v1(
  uuid, uuid, uuid, text, integer, text, text, integer, text, text, text, text, text, integer, text, integer, text, text, text, text, integer
) FROM PUBLIC, anon, authenticated;

-- Concede execução exclusiva à service_role (usada pela Edge Function)
GRANT EXECUTE ON FUNCTION public.conectea_finalize_email_change_reauth_success_v1(
  uuid, uuid, uuid, text, integer, text, text, integer, text, text, text, text, text, integer, text, integer, text, text, text, text, integer
) TO service_role;


-- ─────────────────────────────────────────────────────────────────────────
-- 3. DOCUMENTAÇÃO E COMENTÁRIOS OPERACIONAIS OBRIGATÓRIOS
-- ─────────────────────────────────────────────────────────────────────────

COMMENT ON FUNCTION public.conectea_finalize_email_change_reauth_success_v1 IS
  'Wrapper RPC pública para finalização atômica do sucesso de tentativas de reautenticação.
   A. COMPORTAMENTO E SEGURANÇA:
     1. A função não valida senhas brutas nem OTPs puros. Ela recebe o e-mail de destino normalizado de forma transitória apenas para validações de unicidade e consistência relacional.
     2. O e-mail puro é processado apenas em memória durante a transação e nunca é persistido ou incluído em logs/erros, preservando os requisitos de privacidade.
     3. A Edge Function futura deve obrigatoriamente derivar o HMAC e a criptografia com base no mesmo e-mail normalizado.
     4. A sessão do usuário é revalidada na entrada do fluxo por meio de conectea_is_active_auth_session_v1.
     5. Locks pessimistas sequenciais são adquiridos (profiles -> attempts -> reservations) para evitar deadlocks.
     6. O lock lógico do destino (pg_advisory_xact_lock) com base no destination_hmac e a reserva exclusiva protegem a concorrência de destino.
     7. A aplicação definitiva do novo e-mail no futuro deverá utilizar o mesmo lock lógico do destino para evitar race conditions.
     8. A idempotência terminal é respeitada: tentativas com estado failed_credentials, failed_technical ou expired retornam attempt_already_finalized. Tentativas já succeeded retornam finalized_success e reutilizam o ciclo/desafio existente de forma idempotente sem criar novos objetos.
     9. Se o tempo atual for maior ou igual ao processamento limite, a tentativa permanece processing nos conflitos de negócio, mas é marcada como expired se expirar o TTL.
     10. O fluxo impede a criação paralela de ciclo se já existir um ciclo ativo (closed_at IS NULL), mantendo-o intacto. O ciclo anterior ou protocolo nunca é fechado ou liberado automaticamente nesta função.
     11. Em caso de sucesso, o ciclo, a reserva e o primeiro desafio OTP (em estado pending) são criados atomicamente dentro de um sub-bloco transacional.
     12. Os throttles da sessão atual e global da conta são removidos em caso de sucesso. Throttles de outras sessões ativas são preservados.
     13. Os IDs retornados são internos do ecossistema de infraestrutura (Edge Function) e nunca chegam de forma direta ao cliente Flutter.
     14. Nenhuma chamada de e-mail ou GAS ocorre nesta função de banco de dados.';
