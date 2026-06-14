-- =========================================================================
-- ConeCTEA — Início Transacional da Tentativa de Reautenticação
--
-- MIGRATION: 20260613120000_create_start_email_change_reauth_attempt_v1.sql
-- OBJETIVO:
--   1. Criar função privada para iniciar transacionalmente uma tentativa de reautenticação.
--   2. Criar wrapper RPC pública no schema public exposta apenas para a service_role.
--   3. Garantir fluxo com verificação de idempotência prioritária antes dos throttles.
--   4. Tratar exceções específicas de unique_violation por CONSTRAINT_NAME.
--
-- STATUS: Criação local da migration para validação. Não aplicar neste turno.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. FUNÇÃO PRIVADA: private.conectea_start_email_change_reauth_attempt_v1
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION private.conectea_start_email_change_reauth_attempt_v1(
  p_user_id uuid,
  p_session_id uuid,
  p_session_hmac text,
  p_session_hmac_key_version integer,
  p_idempotency_key uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_profile_exists boolean;

  -- Variáveis de Idempotência
  v_exist_id uuid;
  v_exist_state text;
  v_exist_hmac text;
  v_exist_version integer;
  v_exist_expires_at timestamptz;

  -- Variáveis de Throttle de Conta
  v_account_blocked_until timestamptz;
  v_account_window_expires_at timestamptz;

  -- Variáveis de Throttle de Sessão
  v_session_blocked_until timestamptz;
  v_session_window_expires_at timestamptz;

  -- Variáveis de Concorrência
  v_concorrente_exists boolean;

  -- Variáveis de Criação
  v_now timestamptz;
  v_new_expires timestamptz;
  v_new_id uuid;

  -- Variável de Diagnóstico de Erro
  v_constraint_name text;
BEGIN
  -- 1.1 Validação inicial dos parâmetros (Falha fechada em invalid_request)
  IF p_user_id IS NULL
     OR p_session_id IS NULL
     OR p_session_hmac IS NULL
     OR trim(both from p_session_hmac) = ''
     OR p_session_hmac <> trim(both from p_session_hmac)
     OR p_session_hmac ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
     OR p_session_hmac ~ '^eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$'
     OR p_session_hmac_key_version IS NULL
     OR p_session_hmac_key_version <> 1
     OR p_idempotency_key IS NULL
  THEN
    RETURN jsonb_build_object('result', 'invalid_request');
  END IF;

  -- 1.2 Validação da Sessão Ativa usando a função dedicada
  IF NOT private.conectea_is_active_auth_session_v1(p_user_id, p_session_id) THEN
    RETURN jsonb_build_object('result', 'session_invalid');
  END IF;

  -- 1.3 Lock estável do perfil (Garante exclusão mútua e serializa acessos)
  SELECT true INTO v_profile_exists
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_profile_exists IS NOT TRUE THEN
    -- Não revela a ausência do perfil para evitar vazamento de dados de existência
    RETURN jsonb_build_object('result', 'session_invalid');
  END IF;

  -- 1.4 Prioridade de Idempotência: busca pela chave idempotency_key antes dos throttles
  SELECT id, attempt_state, session_hmac, session_hmac_key_version, processing_expires_at
  INTO v_exist_id, v_exist_state, v_exist_hmac, v_exist_version, v_exist_expires_at
  FROM private.account_change_reauth_attempts
  WHERE user_id = p_user_id
    AND purpose = 'email_change_reauth'
    AND idempotency_key = p_idempotency_key
  FOR UPDATE;

  IF FOUND THEN
    -- A. Sessão divergente (HMAC ou Versão colidem com chave já usada)
    IF v_exist_hmac <> p_session_hmac OR v_exist_version <> p_session_hmac_key_version THEN
      RETURN jsonb_build_object('result', 'idempotency_conflict');
    END IF;

    -- B. Mesma sessão: reconciliação da resposta original
    -- Caso 1: processing ainda válida (TTL ativo)
    IF v_exist_state = 'processing' AND v_exist_expires_at > transaction_timestamp() THEN
      RETURN jsonb_build_object(
        'result', 'reused',
        'attempt_id', v_exist_id,
        'attempt_state', 'processing',
        'processing_expires_at', to_jsonb(v_exist_expires_at),
        'should_authenticate', false
      );
    -- Caso 2: processing vencida (expira atomicamente e retorna como expired)
    ELSIF v_exist_state = 'processing' AND v_exist_expires_at <= transaction_timestamp() THEN
      UPDATE private.account_change_reauth_attempts
      SET attempt_state = 'expired',
          finalized_at = transaction_timestamp(),
          purge_after = transaction_timestamp() + interval '10 minutes'
      WHERE id = v_exist_id
      RETURNING attempt_state INTO v_exist_state;

      RETURN jsonb_build_object(
        'result', 'reused',
        'attempt_id', v_exist_id,
        'attempt_state', 'expired',
        'should_authenticate', false
      );
    -- Caso 3: estado terminal existente (succeeded, failed_credentials, failed_technical, expired)
    ELSE
      RETURN jsonb_build_object(
        'result', 'reused',
        'attempt_id', v_exist_id,
        'attempt_state', v_exist_state,
        'should_authenticate', false
      );
    END IF;
  END IF;

  -- 1.5 Somente para novas chaves de idempotência: avalia throttles e concorrência

  -- 1.5.1 Throttle Global da Conta (Ordem de Lock 2)
  SELECT blocked_until, window_expires_at
  INTO v_account_blocked_until, v_account_window_expires_at
  FROM private.account_change_reauth_account_throttles
  WHERE user_id = p_user_id
    AND purpose = 'email_change_reauth'
  FOR UPDATE;

  IF FOUND THEN
    IF v_account_blocked_until IS NOT NULL AND v_account_blocked_until > transaction_timestamp() THEN
      RETURN jsonb_build_object('result', 'reauth_blocked');
    ELSIF v_account_window_expires_at <= transaction_timestamp() THEN
      DELETE FROM private.account_change_reauth_account_throttles
      WHERE user_id = p_user_id
        AND purpose = 'email_change_reauth';
    END IF;
  END IF;

  -- 1.5.2 Throttle da Sessão (Ordem de Lock 3)
  SELECT blocked_until, window_expires_at
  INTO v_session_blocked_until, v_session_window_expires_at
  FROM private.account_change_reauth_throttles
  WHERE user_id = p_user_id
    AND purpose = 'email_change_reauth'
    AND session_hmac = p_session_hmac
    AND session_hmac_key_version = p_session_hmac_key_version
  FOR UPDATE;

  IF FOUND THEN
    IF v_session_blocked_until IS NOT NULL AND v_session_blocked_until > transaction_timestamp() THEN
      RETURN jsonb_build_object('result', 'reauth_blocked');
    ELSIF v_session_window_expires_at <= transaction_timestamp() THEN
      DELETE FROM private.account_change_reauth_throttles
      WHERE user_id = p_user_id
        AND purpose = 'email_change_reauth'
        AND session_hmac = p_session_hmac
        AND session_hmac_key_version = p_session_hmac_key_version;
    END IF;
  END IF;

  -- 1.5.3 Expiração de tentativa 'processing' anterior vencida
  UPDATE private.account_change_reauth_attempts
  SET attempt_state = 'expired',
      finalized_at = transaction_timestamp(),
      purge_after = transaction_timestamp() + interval '10 minutes'
  WHERE user_id = p_user_id
    AND purpose = 'email_change_reauth'
    AND attempt_state = 'processing'
    AND processing_expires_at <= transaction_timestamp();

  -- 1.5.4 Concorrência Ativa de processamento concorrente
  SELECT true INTO v_concorrente_exists
  FROM private.account_change_reauth_attempts
  WHERE user_id = p_user_id
    AND purpose = 'email_change_reauth'
    AND attempt_state = 'processing'
  LIMIT 1;

  IF FOUND AND v_concorrente_exists IS TRUE THEN
    RETURN jsonb_build_object('result', 'attempt_in_progress');
  END IF;

  -- 1.5.5 Criação da nova tentativa (Ordem de Lock 4)
  v_now := transaction_timestamp();
  v_new_expires := v_now + interval '60 seconds';

  BEGIN
    INSERT INTO private.account_change_reauth_attempts (
      user_id,
      purpose,
      session_hmac,
      session_hmac_key_version,
      idempotency_key,
      attempt_state,
      processing_expires_at,
      created_at,
      updated_at
    ) VALUES (
      p_user_id,
      'email_change_reauth',
      p_session_hmac,
      p_session_hmac_key_version,
      p_idempotency_key,
      'processing',
      v_new_expires,
      v_now,
      v_now
    )
    RETURNING id INTO v_new_id;

    RETURN jsonb_build_object(
      'result', 'created',
      'attempt_id', v_new_id,
      'attempt_state', 'processing',
      'processing_expires_at', to_jsonb(v_new_expires),
      'should_authenticate', true
    );
  EXCEPTION WHEN unique_violation THEN
    -- Diagnóstico da constraint específica que causou a colisão única
    GET STACKED DIAGNOSTICS v_constraint_name = CONSTRAINT_NAME;

    -- Idempotência residual (colisão na chave idempotency_key)
    IF v_constraint_name = 'account_change_reauth_attempts_idempotency_idx' THEN
      SELECT id, attempt_state, session_hmac, session_hmac_key_version, processing_expires_at
      INTO v_exist_id, v_exist_state, v_exist_hmac, v_exist_version, v_exist_expires_at
      FROM private.account_change_reauth_attempts
      WHERE user_id = p_user_id
        AND purpose = 'email_change_reauth'
        AND idempotency_key = p_idempotency_key
      FOR UPDATE;

      IF FOUND THEN
        IF v_exist_hmac = p_session_hmac AND v_exist_version = p_session_hmac_key_version THEN
          IF v_exist_state = 'processing' AND v_exist_expires_at > transaction_timestamp() THEN
            RETURN jsonb_build_object(
              'result', 'reused',
              'attempt_id', v_exist_id,
              'attempt_state', 'processing',
              'processing_expires_at', to_jsonb(v_exist_expires_at),
              'should_authenticate', false
            );
          ELSIF v_exist_state = 'processing' AND v_exist_expires_at <= transaction_timestamp() THEN
            UPDATE private.account_change_reauth_attempts
            SET attempt_state = 'expired',
                finalized_at = transaction_timestamp(),
                purge_after = transaction_timestamp() + interval '10 minutes'
            WHERE id = v_exist_id
            RETURNING attempt_state INTO v_exist_state;

            RETURN jsonb_build_object(
              'result', 'reused',
              'attempt_id', v_exist_id,
              'attempt_state', 'expired',
              'should_authenticate', false
            );
          ELSE
            RETURN jsonb_build_object(
              'result', 'reused',
              'attempt_id', v_exist_id,
              'attempt_state', v_exist_state,
              'should_authenticate', false
            );
          END IF;
        ELSE
          RETURN jsonb_build_object('result', 'idempotency_conflict');
        END IF;
      END IF;

    -- Concorrência de processamento único ativa (colisão no índice parcial de 'processing')
    ELSIF v_constraint_name = 'account_change_reauth_attempts_processing_uniq_idx' THEN
      RETURN jsonb_build_object('result', 'attempt_in_progress');

    -- Qualquer outro unique_violation falha sem mascarar o erro
    ELSE
      RAISE;
    END IF;
  END;
END;
$$;

-- Revoga privilégios públicos de execução da rotina privada
REVOKE ALL ON FUNCTION private.conectea_start_email_change_reauth_attempt_v1(
  uuid, uuid, text, integer, uuid
) FROM PUBLIC, anon, authenticated, service_role;


-- ─────────────────────────────────────────────────────────────────────────
-- 2. WRAPPER RPC PÚBLICA: public.conectea_start_email_change_reauth_attempt_v1
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_start_email_change_reauth_attempt_v1(
  p_user_id uuid,
  p_session_id uuid,
  p_session_hmac text,
  p_session_hmac_key_version integer,
  p_idempotency_key uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
BEGIN
  -- Delega exclusivamente para a rotina privada
  RETURN private.conectea_start_email_change_reauth_attempt_v1(
    p_user_id := p_user_id,
    p_session_id := p_session_id,
    p_session_hmac := p_session_hmac,
    p_session_hmac_key_version := p_session_hmac_key_version,
    p_idempotency_key := p_idempotency_key
  );
END;
$$;

-- Revoga acessos de usuários comuns e anônimos da RPC pública
REVOKE ALL ON FUNCTION public.conectea_start_email_change_reauth_attempt_v1(
  uuid, uuid, text, integer, uuid
) FROM PUBLIC, anon, authenticated;

-- Concede execução restrita e exclusiva à service_role (usada pela Edge Function)
GRANT EXECUTE ON FUNCTION public.conectea_start_email_change_reauth_attempt_v1(
  uuid, uuid, text, integer, uuid
) TO service_role;


-- ─────────────────────────────────────────────────────────────────────────
-- 3. DOCUMENTAÇÃO E COMENTÁRIOS OPERACIONAIS OBRIGATÓRIOS
-- ─────────────────────────────────────────────────────────────────────────

COMMENT ON FUNCTION public.conectea_start_email_change_reauth_attempt_v1 IS
  'Wrapper RPC pública executável exclusivamente pela service_role para iniciar o processo de reautenticação.
   A. PREMISSAS DO FLUXO E SEGURANÇA:
     1. A função não valida a senha do usuário; ela apenas registra a tentativa em estado "processing" no banco.
     2. A validação e a senha em si permanecem exclusivamente na memória da futura Edge Function, que chamará o Supabase Auth.
     3. O lock inicial adquirido sequencialmente na tabela public.profiles serializa o acesso concorrente e impede deadlocks.
     4. A ordem de locks (public.profiles -> account_change_reauth_account_throttles -> account_change_reauth_throttles -> account_change_reauth_attempts) é estruturada e imutável.
     5. O bloqueio ativo nos throttles é verificado antes de qualquer limpeza de janelas vencidas.
     6. Qualquer tentativa vencida no estado "processing" é expirada atomicamente para o estado "expired" antes de novas inserções.
     7. A idempotency_key é gerada no backend seguro da Edge Function e nunca trafega do Flutter sem a devida mediação.
     8. O attempt_id gerado é retornado à Edge Function e nunca chega ao Flutter.
     9. O resultado "created" autoriza formalmente a Edge Function a invocar o signInWithPassword.
     10. O resultado "reused" indica reuso idempotente válido e não autoriza nova chamada paralela ao Supabase Auth.
     11. Tentativas em estado terminal ("expired", "succeeded", "failed_credentials", "failed_technical") são imutáveis.
     12. Nenhuma chamada de negócio ou integração externa (como GAS) é executada nesta etapa.
   B. COMPORTAMENTO FAIL-CLOSED DE RESPOSTA PERDIDA:
     1. Se a tentativa foi criada com sucesso pelo banco, mas o retorno HTTP "created" se perdeu no tráfego até a Edge Function:
        - O retry subsequente da Edge Function enviando a mesma "idempotency_key" cairá na reconciliação e retornará "reused" com "should_authenticate = false".
        - A Edge Function interpretará o "should_authenticate = false" e não submeterá a autenticação concorrente ao Auth.
        - O usuário precisará aguardar o término do TTL de processamento de 60 segundos exato da tentativa ativa.
        - Após 60 segundos, a tentativa passa a ser reconciliada como "expired", liberando o fluxo para uma nova tentativa que deverá obrigatoriamente fornecer uma nova "idempotency_key".
        - Essa espera de até 60 segundos é uma escolha consciente de segurança para mitigar bypasses, concorrências e replays.
   C. FINALIZAÇÃO FUTURA (CONTRATO DE VÍNCULO):
     1. A futura rotina de finalização da reautenticação precisará obrigatoriamente revalidar a sessão ativa no banco, o usuário correspondente, o HMAC da sessão atual e garantir que a tentativa continua no estado "processing" com TTL válido. O sucesso da senha na Edge Function não dispensa a revalidação transacional.
   D. ORIGEM DO HMAC E EDGE:
     1. O parâmetro p_session_hmac nunca trafega e nunca é gerado a partir do Flutter. A Edge Function deriva este hash a partir do "session_id" presente na claim do JWT validado com uma chave de criptografia privada. O banco de dados não recalcula o hash e o session_id bruto nunca é persistido ou logado.';
