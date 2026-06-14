-- =========================================================================
-- ConeCTEA — Finalização de Falha da Reautenticação
--
-- MIGRATION: 20260613130000_create_finalize_email_change_reauth_failure_v1.sql
-- OBJETIVO:
--   1. Criar função privada para finalizar tentativas em falhas (credenciais, técnicas ou expiradas).
--   2. Criar wrapper RPC público no schema public exposto exclusivamente para a service_role.
--   3. Implementar controle rigoroso de concorrência, idempotência terminal e TTL de 60 segundos.
--   4. Atualizar atomicamente throttles globais e de sessão sob falha de credenciais.
--
-- STATUS: Criação local da migration para validação. Não aplicar neste turno.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. FUNÇÃO PRIVADA: private.conectea_finalize_email_change_reauth_failure_v1
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION private.conectea_finalize_email_change_reauth_failure_v1(
  p_attempt_id uuid,
  p_user_id uuid,
  p_session_id uuid,
  p_session_hmac text,
  p_session_hmac_key_version integer,
  p_result text,
  p_failed_technical_code_private text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_profile_exists boolean;
  v_now timestamptz;

  -- Variáveis de busca da tentativa
  v_attempt_id_found uuid;
  v_attempt_state text;
  v_processing_expires_at timestamptz;

  -- Variáveis do Throttle Global da Conta
  v_acc_failed_attempts integer;
  v_acc_window_started_at timestamptz;
  v_acc_window_expires_at timestamptz;
  v_acc_blocked_until timestamptz;

  -- Variáveis do Throttle de Sessão
  v_sess_failed_attempts integer;
  v_sess_window_started_at timestamptz;
  v_sess_window_expires_at timestamptz;
  v_sess_blocked_until timestamptz;

  -- Variável de controle de bloqueio final
  v_blocked boolean := false;
BEGIN
  -- 1. Validação de Parâmetros de Entrada
  IF p_attempt_id IS NULL
     OR p_user_id IS NULL
     OR p_session_id IS NULL
     OR p_session_hmac IS NULL
     OR trim(both from p_session_hmac) = ''
     OR p_session_hmac <> trim(both from p_session_hmac)
     OR p_session_hmac ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
     OR p_session_hmac ~ '^eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$'
     OR p_session_hmac_key_version IS NULL
     OR p_session_hmac_key_version <> 1
     OR p_result IS NULL
     OR p_result NOT IN ('invalid_credentials', 'technical_failure')
  THEN
    RETURN jsonb_build_object('result', 'invalid_request');
  END IF;

  -- 2. Validação da Sessão Ativa
  IF NOT private.conectea_is_active_auth_session_v1(p_user_id, p_session_id) THEN
    RETURN jsonb_build_object('result', 'session_invalid');
  END IF;

  -- 3. Locks Ordinários Estáveis
  -- Lock 1: profiles
  SELECT true INTO v_profile_exists
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_profile_exists IS NOT TRUE THEN
    RETURN jsonb_build_object('result', 'session_invalid');
  END IF;

  -- Lock 2: attempt
  SELECT id, attempt_state, processing_expires_at
  INTO v_attempt_id_found, v_attempt_state, v_processing_expires_at
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
    RETURN jsonb_build_object('result', 'attempt_mismatch');
  END IF;

  -- 4. Idempotência Terminal
  IF v_attempt_state IN ('succeeded', 'failed_credentials', 'failed_technical', 'expired') THEN
    RETURN jsonb_build_object(
      'result', 'attempt_already_finalized',
      'attempt_state', v_attempt_state
    );
  END IF;

  -- Instante unificado da transação
  v_now := transaction_timestamp();

  -- 5. Validação do TTL de Processamento
  IF v_now >= v_processing_expires_at THEN
    -- Expira atomicamente sem incrementar throttles
    UPDATE private.account_change_reauth_attempts
    SET attempt_state = 'expired',
        finalized_at = v_now,
        purge_after = v_now + interval '10 minutes'
    WHERE id = p_attempt_id;

    RETURN jsonb_build_object('result', 'attempt_expired');
  END IF;

  -- 6. Ramo de Falha de Credenciais
  IF p_result = 'invalid_credentials' THEN
    -- Adquire Locks de Throttles
    -- Lock 3: throttle global
    SELECT failed_attempts, window_started_at, window_expires_at, blocked_until
    INTO v_acc_failed_attempts, v_acc_window_started_at, v_acc_window_expires_at, v_acc_blocked_until
    FROM private.account_change_reauth_account_throttles
    WHERE user_id = p_user_id
      AND purpose = 'email_change_reauth'
    FOR UPDATE;

    -- Lock 4: throttle de sessão
    SELECT failed_attempts, window_started_at, window_expires_at, blocked_until
    INTO v_sess_failed_attempts, v_sess_window_started_at, v_sess_window_expires_at, v_sess_blocked_until
    FROM private.account_change_reauth_throttles
    WHERE user_id = p_user_id
      AND purpose = 'email_change_reauth'
      AND session_hmac = p_session_hmac
      AND session_hmac_key_version = p_session_hmac_key_version
    FOR UPDATE;

    -- --- Atualização do Throttle Global ---
    IF v_acc_failed_attempts IS NULL THEN
      -- Primeiro registro
      INSERT INTO private.account_change_reauth_account_throttles (
        user_id, purpose, failed_attempts, window_started_at, window_expires_at, last_failed_at, blocked_until
      ) VALUES (
        p_user_id, 'email_change_reauth', 1, v_now, v_now + interval '15 minutes', v_now, NULL
      );
    ELSIF v_acc_blocked_until IS NOT NULL AND v_acc_blocked_until > v_now THEN
      -- Se bloqueio já está ativo, preservar
      v_blocked := true;
    ELSIF v_acc_window_expires_at <= v_now THEN
      -- Janela expirou sem bloqueio, reinicia
      UPDATE private.account_change_reauth_account_throttles
      SET failed_attempts = 1,
          window_started_at = v_now,
          window_expires_at = v_now + interval '15 minutes',
          last_failed_at = v_now,
          blocked_until = NULL
      WHERE user_id = p_user_id AND purpose = 'email_change_reauth';
    ELSE
      -- Janela ativa, incrementa
      IF v_acc_failed_attempts < 4 THEN
        UPDATE private.account_change_reauth_account_throttles
        SET failed_attempts = failed_attempts + 1,
            last_failed_at = v_now
        WHERE user_id = p_user_id AND purpose = 'email_change_reauth';
      ELSE
        -- 5ª falha, bloqueia por 1 hora
        UPDATE private.account_change_reauth_account_throttles
        SET failed_attempts = 5,
            last_failed_at = v_now,
            blocked_until = v_now + interval '1 hour'
        WHERE user_id = p_user_id AND purpose = 'email_change_reauth';
        v_blocked := true;
      END IF;
    END IF;

    -- --- Atualização do Throttle por Sessão ---
    IF v_sess_failed_attempts IS NULL THEN
      -- Primeiro registro
      INSERT INTO private.account_change_reauth_throttles (
        user_id, purpose, session_hmac, session_hmac_key_version, failed_attempts, window_started_at, window_expires_at, last_failed_at, blocked_until
      ) VALUES (
        p_user_id, 'email_change_reauth', p_session_hmac, p_session_hmac_key_version, 1, v_now, v_now + interval '15 minutes', v_now, NULL
      );
    ELSIF v_sess_blocked_until IS NOT NULL AND v_sess_blocked_until > v_now THEN
      -- Se bloqueio já está ativo, preservar
      v_blocked := true;
    ELSIF v_sess_window_expires_at <= v_now THEN
      -- Janela expirou sem bloqueio, reinicia
      UPDATE private.account_change_reauth_throttles
      SET failed_attempts = 1,
          window_started_at = v_now,
          window_expires_at = v_now + interval '15 minutes',
          last_failed_at = v_now,
          blocked_until = NULL
      WHERE user_id = p_user_id
        AND purpose = 'email_change_reauth'
        AND session_hmac = p_session_hmac
        AND session_hmac_key_version = p_session_hmac_key_version;
    ELSE
      -- Janela ativa, incrementa
      IF v_sess_failed_attempts < 4 THEN
        UPDATE private.account_change_reauth_throttles
        SET failed_attempts = failed_attempts + 1,
            last_failed_at = v_now
        WHERE user_id = p_user_id
          AND purpose = 'email_change_reauth'
          AND session_hmac = p_session_hmac
          AND session_hmac_key_version = p_session_hmac_key_version;
      ELSE
        -- 5ª falha, bloqueia por 1 hora
        UPDATE private.account_change_reauth_throttles
        SET failed_attempts = 5,
            last_failed_at = v_now,
            blocked_until = v_now + interval '1 hour'
        WHERE user_id = p_user_id
          AND purpose = 'email_change_reauth'
          AND session_hmac = p_session_hmac
          AND session_hmac_key_version = p_session_hmac_key_version;
        v_blocked := true;
      END IF;
    END IF;

    -- Finaliza a tentativa como falha de credencial
    UPDATE private.account_change_reauth_attempts
    SET attempt_state = 'failed_credentials',
        finalized_at = v_now,
        purge_after = v_now + interval '10 minutes'
    WHERE id = p_attempt_id;

    RETURN jsonb_build_object(
      'result', 'finalized_failed_credentials',
      'blocked', v_blocked
    );

  -- 7. Ramo de Falha Técnica
  ELSIF p_result = 'technical_failure' THEN
    -- Validação do código técnico privado
    IF p_failed_technical_code_private IS NULL
       OR trim(both from p_failed_technical_code_private) = ''
       OR p_failed_technical_code_private <> trim(both from p_failed_technical_code_private)
       OR length(p_failed_technical_code_private) > 64
       OR p_failed_technical_code_private !~ '^[a-z0-9_]+$'
       OR p_failed_technical_code_private NOT IN ('auth_timeout', 'auth_unavailable', 'auth_internal_error')
    THEN
      RETURN jsonb_build_object('result', 'invalid_request');
    END IF;

    -- Finaliza a tentativa como falha técnica salvando o código
    UPDATE private.account_change_reauth_attempts
    SET attempt_state = 'failed_technical',
        failed_technical_code_private = p_failed_technical_code_private,
        finalized_at = v_now,
        purge_after = v_now + interval '10 minutes'
    WHERE id = p_attempt_id;

    RETURN jsonb_build_object('result', 'finalized_failed_technical');
  END IF;
END;
$$;

-- Revoga execução pública da função privada
REVOKE ALL ON FUNCTION private.conectea_finalize_email_change_reauth_failure_v1(
  uuid, uuid, uuid, text, integer, text, text
) FROM PUBLIC, anon, authenticated, service_role;


-- ─────────────────────────────────────────────────────────────────────────
-- 2. WRAPPER RPC PÚBLICA: public.conectea_finalize_email_change_reauth_failure_v1
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_finalize_email_change_reauth_failure_v1(
  p_attempt_id uuid,
  p_user_id uuid,
  p_session_id uuid,
  p_session_hmac text,
  p_session_hmac_key_version integer,
  p_result text,
  p_failed_technical_code_private text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
BEGIN
  -- Delega exclusivamente para a rotina privada
  RETURN private.conectea_finalize_email_change_reauth_failure_v1(
    p_attempt_id := p_attempt_id,
    p_user_id := p_user_id,
    p_session_id := p_session_id,
    p_session_hmac := p_session_hmac,
    p_session_hmac_key_version := p_session_hmac_key_version,
    p_result := p_result,
    p_failed_technical_code_private := p_failed_technical_code_private
  );
END;
$$;

-- Revoga privilégios para usuários comuns e públicos da RPC pública
REVOKE ALL ON FUNCTION public.conectea_finalize_email_change_reauth_failure_v1(
  uuid, uuid, uuid, text, integer, text, text
) FROM PUBLIC, anon, authenticated;

-- Concede execução exclusiva à service_role (usada pela Edge Function)
GRANT EXECUTE ON FUNCTION public.conectea_finalize_email_change_reauth_failure_v1(
  uuid, uuid, uuid, text, integer, text, text
) TO service_role;


-- ─────────────────────────────────────────────────────────────────────────
-- 3. DOCUMENTAÇÃO E COMENTÁRIOS OPERACIONAIS OBRIGATÓRIOS
-- ─────────────────────────────────────────────────────────────────────────

COMMENT ON FUNCTION public.conectea_finalize_email_change_reauth_failure_v1 IS
  'Wrapper RPC pública para finalização de falhas em tentativas de reautenticação.
   A. COMPORTAMENTO E SEGURANÇA:
     1. A função não valida senhas brutas; ela apenas processa os estados de falha informados pela Edge Function (invalid_credentials e technical_failure).
     2. A sessão do usuário é revalidada na entrada do fluxo garantindo consistência relacional.
     3. Locks estáveis e sequenciais são adquiridos (profiles -> attempts -> throttles) para evitar deadlocks e concorrências de escrita na mesma conta.
     4. A idempotência terminal é respeitada: se o estado no banco de dados já for succeeded, failed_credentials, failed_technical ou expired, a RPC retorna attempt_already_finalized e não efetua nenhuma nova escrita ou alteração em throttles.
     5. O replay de finalizações em tentativas já resolvidas não incrementa o contador de throttles.
     6. Em caso de falha de credenciais, o throttle global e o da sessão correspondente são atualizados de forma atômica e simultânea na mesma transação.
     7. A quinta falha consecutiva na mesma janela de 15 minutos aciona um bloqueio de exatamente 1 hora (blocked_until = last_failed_at + 1 hora) para o throttle correspondente.
     8. Falhas técnicas (auth_timeout, auth_unavailable, auth_internal_error) registram o erro correspondente no banco de dados para auditoria, mas não penalizam o usuário (não incrementam throttles).
     9. O caminho de sucesso (criação de ciclo, reserva exclusiva e OTP inicial) é omitido e será implementado separadamente em outra rotina transacional.
     10. Nenhum token, JWT ou senha em texto claro trafega como argumento nesta RPC, respeitando os requisitos LGPD do aplicativo.';
