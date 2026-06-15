-- =========================================================================
-- ConeCTEA — Consolidação Atômica da Entrega do OTP
--
-- MIGRATION: 20260613160000_create_finalize_email_change_challenge_delivery_v1.sql
-- OBJETIVO:
--   1. Criar as funções privadas de consolidação: mark_sent e mark_failed.
--   2. Criar os wrappers RPC públicos restritos estritamente à service_role.
--   3. Implementar locks pessimistas e fencing tokens (delivery_attempts).
--   4. Configurar regras de cooldown e retenção da reserva exclusiva do e-mail.
--   5. Assegurar atomicidade transacional e limpeza do OTP reversível.
--
-- STATUS: Criação local da migration para auditoria e testes de sintaxe.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. FUNÇÕES PRIVADAS: mark_sent e mark_failed
-- ─────────────────────────────────────────────────────────────────────────

-- A. Função Privada: private.conectea_mark_email_change_challenge_sent_v1
CREATE OR REPLACE FUNCTION private.conectea_mark_email_change_challenge_sent_v1(
  p_user_id uuid,
  p_cycle_id uuid,
  p_challenge_id uuid,
  p_expected_delivery_attempts integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_now timestamptz;
  v_profile_id uuid;
  v_cycle_purpose text;
  v_cycle_closed_at timestamptz;
  v_challenge_state text;
  v_delivery_status text;
  v_delivery_attempts integer;
  v_send_sequence integer;
  v_expires_at timestamptz;
  v_final_hold timestamptz;
  v_reservation_id uuid;
  v_res_state text;
  v_res_released timestamptz;
BEGIN
  -- 1. Validação de Parâmetros de Entrada
  IF p_user_id IS NULL OR p_cycle_id IS NULL OR p_challenge_id IS NULL OR p_expected_delivery_attempts IS NULL OR p_expected_delivery_attempts <= 0 THEN
    RETURN jsonb_build_object('result', 'invalid_request');
  END IF;

  v_now := transaction_timestamp();

  -- 2. Locks pessimistas em ordem hierárquica estrita
  -- Lock 1: profiles
  SELECT id INTO v_profile_id
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'challenge_mismatch');
  END IF;

  -- Lock 2: cycles
  SELECT purpose, closed_at INTO v_cycle_purpose, v_cycle_closed_at
  FROM private.account_change_challenge_cycles
  WHERE id = p_cycle_id AND user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_cycle_purpose <> 'email_change' THEN
    RETURN jsonb_build_object('result', 'challenge_mismatch');
  END IF;

  -- Lock 3: challenges
  SELECT challenge_state, delivery_status, delivery_attempts, send_sequence
  INTO v_challenge_state, v_delivery_status, v_delivery_attempts, v_send_sequence
  FROM private.account_change_challenges
  WHERE id = p_challenge_id AND cycle_id = p_cycle_id AND user_id = p_user_id AND purpose = 'email_change'
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'challenge_mismatch');
  END IF;

  -- Lock 4: email_reservations (localizada pelo ciclo)
  SELECT id, reservation_state, released_at INTO v_reservation_id, v_res_state, v_res_released
  FROM private.account_change_email_reservations
  WHERE cycle_id = p_cycle_id AND user_id = p_user_id AND purpose = 'email_change'
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'challenge_mismatch');
  END IF;

  -- 3. Validação do Fencing Token (Comparar attempts)
  IF v_delivery_attempts <> p_expected_delivery_attempts THEN
    RETURN jsonb_build_object('result', 'stale_claim');
  END IF;

  -- 4. Análise de Idempotência e Estado Terminal
  IF v_delivery_status = 'sent' THEN
    RETURN jsonb_build_object('result', 'already_sent');
  ELSIF v_delivery_status = 'failed' THEN
    RETURN jsonb_build_object('result', 'already_failed');
  END IF;

  IF v_challenge_state IN ('consumed', 'expired', 'cancelled', 'blocked') THEN
    RETURN jsonb_build_object('result', 'invalid_delivery_state');
  END IF;

  IF v_cycle_closed_at IS NOT NULL THEN
    RETURN jsonb_build_object('result', 'flow_closed');
  END IF;

  IF v_delivery_status <> 'sending' OR v_challenge_state <> 'active' OR v_res_state <> 'active' OR v_res_released IS NOT NULL THEN
    RETURN jsonb_build_object('result', 'invalid_delivery_state');
  END IF;

  -- 5. Atualização do Desafio
  UPDATE private.account_change_challenges
  SET delivery_status = 'sent',
      sent_at = v_now,
      expires_at = v_now + interval '15 minutes',
      resend_available_at = v_now + interval '15 minutes',
      failed_at = NULL,
      delivery_failure_reason_private = NULL,
      code_ciphertext = NULL,
      code_nonce = NULL,
      code_auth_tag = NULL,
      code_encryption_algorithm = NULL,
      code_encryption_key_version = NULL,
      updated_at = v_now
  WHERE id = p_challenge_id;

  -- 6. Atualização de Cooldown / Hold do Ciclo e da Reserva
  v_expires_at := v_now + interval '15 minutes';

  IF v_send_sequence IN (1, 2) THEN
    UPDATE private.account_change_email_reservations
    SET cycle_hold_until = pg_catalog.greatest(coalesce(cycle_hold_until, v_expires_at), v_expires_at),
        updated_at = v_now
    WHERE id = v_reservation_id;

  ELSIF v_send_sequence = 3 THEN
    v_final_hold := v_expires_at + interval '1 hour';

    UPDATE private.account_change_email_reservations
    SET cycle_hold_until = pg_catalog.greatest(coalesce(cycle_hold_until, v_final_hold), v_final_hold),
        updated_at = v_now
    WHERE id = v_reservation_id;

    UPDATE private.account_change_challenge_cycles
    SET cooldown_until = pg_catalog.greatest(coalesce(cooldown_until, v_final_hold), v_final_hold),
        updated_at = v_now
    WHERE id = p_cycle_id;
  END IF;

  RETURN jsonb_build_object(
    'result', 'marked_sent',
    'delivery_status', 'sent',
    'send_sequence', v_send_sequence,
    'delivery_attempts', v_delivery_attempts,
    'expires_at', v_expires_at,
    'resend_available_at', v_expires_at
  );
END;
$$;

-- B. Função Privada: private.conectea_mark_email_change_challenge_failed_v1
CREATE OR REPLACE FUNCTION private.conectea_mark_email_change_challenge_failed_v1(
  p_user_id uuid,
  p_cycle_id uuid,
  p_challenge_id uuid,
  p_expected_delivery_attempts integer,
  p_failure_reason_private text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_now timestamptz;
  v_profile_id uuid;
  v_cycle_purpose text;
  v_cycle_closed_at timestamptz;
  v_challenge_state text;
  v_delivery_status text;
  v_delivery_attempts integer;
  v_send_sequence integer;
  v_reservation_id uuid;
  v_res_state text;
  v_res_released timestamptz;
BEGIN
  -- 1. Validação de Parâmetros de Entrada
  IF p_user_id IS NULL OR p_cycle_id IS NULL OR p_challenge_id IS NULL OR p_expected_delivery_attempts IS NULL OR p_expected_delivery_attempts <= 0 THEN
    RETURN jsonb_build_object('result', 'invalid_request');
  END IF;

  -- Validar se o motivo privado está trimado e pertence à enumeração permitida
  IF p_failure_reason_private IS NULL
     OR p_failure_reason_private <> trim(both from p_failure_reason_private)
     OR p_failure_reason_private NOT IN (
          'invalid_destination_permanent',
          'recipient_rejected_permanent',
          'domain_rejected_permanent',
          'mailbox_disabled_permanent'
        )
  THEN
    RETURN jsonb_build_object('result', 'invalid_request');
  END IF;

  v_now := transaction_timestamp();

  -- 2. Locks pessimistas em ordem hierárquica estrita
  -- Lock 1: profiles
  SELECT id INTO v_profile_id
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'challenge_mismatch');
  END IF;

  -- Lock 2: cycles
  SELECT purpose, closed_at INTO v_cycle_purpose, v_cycle_closed_at
  FROM private.account_change_challenge_cycles
  WHERE id = p_cycle_id AND user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_cycle_purpose <> 'email_change' THEN
    RETURN jsonb_build_object('result', 'challenge_mismatch');
  END IF;

  -- Lock 3: challenges
  SELECT challenge_state, delivery_status, delivery_attempts, send_sequence
  INTO v_challenge_state, v_delivery_status, v_delivery_attempts, v_send_sequence
  FROM private.account_change_challenges
  WHERE id = p_challenge_id AND cycle_id = p_cycle_id AND user_id = p_user_id AND purpose = 'email_change'
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'challenge_mismatch');
  END IF;

  -- Lock 4: email_reservations (localizada pelo ciclo)
  SELECT id, reservation_state, released_at INTO v_reservation_id, v_res_state, v_res_released
  FROM private.account_change_email_reservations
  WHERE cycle_id = p_cycle_id AND user_id = p_user_id AND purpose = 'email_change'
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'challenge_mismatch');
  END IF;

  -- 3. Validação do Fencing Token (Comparar attempts)
  IF v_delivery_attempts <> p_expected_delivery_attempts THEN
    RETURN jsonb_build_object('result', 'stale_claim');
  END IF;

  -- 4. Análise de Idempotência e Estado Terminal
  IF v_delivery_status = 'sent' THEN
    RETURN jsonb_build_object('result', 'already_sent');
  ELSIF v_delivery_status = 'failed' THEN
    RETURN jsonb_build_object('result', 'already_failed');
  END IF;

  IF v_challenge_state IN ('consumed', 'expired', 'cancelled', 'blocked') THEN
    RETURN jsonb_build_object('result', 'invalid_delivery_state');
  END IF;

  IF v_cycle_closed_at IS NOT NULL THEN
    RETURN jsonb_build_object('result', 'flow_closed');
  END IF;

  IF v_delivery_status <> 'sending' OR v_challenge_state <> 'active' OR v_res_state <> 'active' OR v_res_released IS NOT NULL THEN
    RETURN jsonb_build_object('result', 'invalid_delivery_state');
  END IF;

  -- 5. Atualização do Desafio
  UPDATE private.account_change_challenges
  SET delivery_status = 'failed',
      challenge_state = 'cancelled',
      failed_at = v_now,
      cancelled_at = v_now,
      delivery_failure_reason_private = p_failure_reason_private,
      sent_at = NULL,
      expires_at = NULL,
      resend_available_at = NULL,
      code_ciphertext = NULL,
      code_nonce = NULL,
      code_auth_tag = NULL,
      code_encryption_algorithm = NULL,
      code_encryption_key_version = NULL,
      updated_at = v_now
  WHERE id = p_challenge_id;

  -- 6. Fechamento do Ciclo
  UPDATE private.account_change_challenge_cycles
  SET closed_at = v_now,
      updated_at = v_now
  WHERE id = p_cycle_id;

  -- 7. Liberação da Reserva (Executado estritamente após o ciclo por causa da FK fk_conectea_reservation_cycle_closed)
  UPDATE private.account_change_email_reservations
  SET reservation_state = 'released',
      cycle_closed_at = v_now,
      released_at = v_now,
      release_reason = p_failure_reason_private,
      updated_at = v_now
  WHERE id = v_reservation_id;

  RETURN jsonb_build_object(
    'result', 'marked_failed',
    'delivery_status', 'failed',
    'challenge_state', 'cancelled',
    'cycle_closed', true,
    'reservation_released', true
  );
END;
$$;

-- Revoga privilégios de execução pública e de roles para as funções privadas
REVOKE ALL ON FUNCTION private.conectea_mark_email_change_challenge_sent_v1(
  uuid, uuid, uuid, integer
) FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON FUNCTION private.conectea_mark_email_change_challenge_failed_v1(
  uuid, uuid, uuid, integer, text
) FROM PUBLIC, anon, authenticated, service_role;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. WRAPPERS RPC PÚBLICAS
-- ─────────────────────────────────────────────────────────────────────────

-- A. Wrapper Pública: public.conectea_mark_email_change_challenge_sent_v1
CREATE OR REPLACE FUNCTION public.conectea_mark_email_change_challenge_sent_v1(
  p_user_id uuid,
  p_cycle_id uuid,
  p_challenge_id uuid,
  p_expected_delivery_attempts integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
BEGIN
  RETURN private.conectea_mark_email_change_challenge_sent_v1(
    p_user_id := p_user_id,
    p_cycle_id := p_cycle_id,
    p_challenge_id := p_challenge_id,
    p_expected_delivery_attempts := p_expected_delivery_attempts
  );
END;
$$;

-- B. Wrapper Pública: public.conectea_mark_email_change_challenge_failed_v1
CREATE OR REPLACE FUNCTION public.conectea_mark_email_change_challenge_failed_v1(
  p_user_id uuid,
  p_cycle_id uuid,
  p_challenge_id uuid,
  p_expected_delivery_attempts integer,
  p_failure_reason_private text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
BEGIN
  RETURN private.conectea_mark_email_change_challenge_failed_v1(
    p_user_id := p_user_id,
    p_cycle_id := p_cycle_id,
    p_challenge_id := p_challenge_id,
    p_expected_delivery_attempts := p_expected_delivery_attempts,
    p_failure_reason_private := p_failure_reason_private
  );
END;
$$;

-- Revoga privilégios para as rotinas públicas (impedindo acesso anônimo/autenticado normal)
REVOKE ALL ON FUNCTION public.conectea_mark_email_change_challenge_sent_v1(
  uuid, uuid, uuid, integer
) FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.conectea_mark_email_change_challenge_failed_v1(
  uuid, uuid, uuid, integer, text
) FROM PUBLIC, anon, authenticated;

-- Concede execução exclusiva à service_role (usada pela Edge Function)
GRANT EXECUTE ON FUNCTION public.conectea_mark_email_change_challenge_sent_v1(
  uuid, uuid, uuid, integer
) TO service_role;

GRANT EXECUTE ON FUNCTION public.conectea_mark_email_change_challenge_failed_v1(
  uuid, uuid, uuid, integer, text
) TO service_role;

-- ─────────────────────────────────────────────────────────────────────────
-- 3. DOCUMENTAÇÃO E COMENTÁRIOS DE SEGURANÇA
-- ─────────────────────────────────────────────────────────────────────────

COMMENT ON FUNCTION public.conectea_mark_email_change_challenge_sent_v1 IS
  'Wrapper RPC pública para consolidar o status de envio confirmado do OTP.
   A. REGRAS DE CONCORRÊNCIA E SEGURANÇA:
     1. Apenas a service_role possui privilégio de execução. O Flutter nunca executa chamadas diretas a esta rotina.
     2. Não recebe nem retorna e-mails puros, OTPs, HMACs ou secrets, limitando-se a parâmetros de controle operacional.
     3. A ordem hierárquica de locks pessimistas (profiles -> cycles -> challenges -> reservations) previne deadlocks.
     4. A comparação de p_expected_delivery_attempts contra o banco age como fencing token (impede workers lentos após expiração do lease).
   B. ATUALIZAÇÕES E COOLDOWN:
     1. Grava delivery_status = sent e calcula o prazo de validade (expires_at) de 15 minutos.
     2. Limpa o material reversível (ciphers, nonces) para proteção contra vazamento, mas preserva o code_hmac para validação futura.
     3. Em sequências 1 e 2, atualiza o cycle_hold_until da reserva usando GREATEST. Em sequência 3, estende a retenção e o cooldown_until do ciclo por mais 1 hora de bloqueio final.';

COMMENT ON FUNCTION public.conectea_mark_email_change_challenge_failed_v1 IS
  'Wrapper RPC pública para consolidar a falha permanente e definitiva de entrega do OTP.
   A. REGRAS DE CONCORRÊNCIA E SEGURANÇA:
     1. Apenas a service_role possui privilégio de execução.
     2. Apenas falhas permanentes e comprovadas enumeradas são aceitas (invalid_destination_permanent, recipient_rejected_permanent, domain_rejected_permanent, mailbox_disabled_permanent). Timeouts ou erros de rede mantêm o status sending para permitir retries pelo claim.
     3. O fencing token delivery_attempts e os locks pessimistas previnem gravação de estado tardio.
   B. ATUALIZAÇÕES E CICLO DE VIDA:
     1. Grava delivery_status = failed e challenge_state = cancelled.
     2. Zera todo o material reversível de criptografia do OTP, preservando apenas o code_hmac.
     3. Fecha transacionalmente o ciclo de desafios (closed_at) e libera a reserva do e-mail destino (released).
     4. A ordem de fechamento (ciclo antes da reserva) é obrigatória para satisfazer a chave estrangeira fk_conectea_reservation_cycle_closed.';
