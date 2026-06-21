-- =========================================================================
-- ConeCTEA — Correção do Cooldown de Reenvio do OTP
--
-- MIGRATION: 20260621032100_fix_email_change_resend_cooldown_60s_v1.sql
-- OBJETIVO:
--   1. Separar resend_available_at (60s) de expires_at (15m).
--   2. Atualizar a constraint chk_conectea_challenge_delivery_rules para permitir essa separação.
--   3. Redefinir a função privada private.conectea_mark_email_change_challenge_sent_v1.
--
-- STATUS: Migração corretiva local.
-- =========================================================================

-- 1. Atualizar a Constraint de Regras de Entrega
ALTER TABLE private.account_change_challenges
  DROP CONSTRAINT IF EXISTS chk_conectea_challenge_delivery_rules;

ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_delivery_rules CHECK (
    -- Estado pending: nada enviado, prazos nulos
    (delivery_status = 'pending' AND 
     delivery_attempts = 0 AND 
     last_delivery_attempt_at IS NULL AND 
     sent_at IS NULL AND 
     failed_at IS NULL AND 
     delivery_failure_reason_private IS NULL AND
     expires_at IS NULL AND
     resend_available_at IS NULL) OR
     
    -- Estado sending: em processo de envio, prazos nulos
    (delivery_status = 'sending' AND 
     delivery_attempts > 0 AND 
     last_delivery_attempt_at IS NOT NULL AND 
     sent_at IS NULL AND 
     failed_at IS NULL AND 
     delivery_failure_reason_private IS NULL AND
     expires_at IS NULL AND
     resend_available_at IS NULL) OR
     
    -- Estado sent: envio aceito/concluído pelo MailApp/GAS
    --   - prazo de expiração de exatamente 15 minutos a partir de sent_at
    --   - reenvio liberado após 60 segundos do envio, mas obrigatoriamente antes da expiração total
    (delivery_status = 'sent' AND 
     delivery_attempts > 0 AND 
     last_delivery_attempt_at IS NOT NULL AND 
     sent_at IS NOT NULL AND 
     failed_at IS NULL AND 
     delivery_failure_reason_private IS NULL AND
     expires_at = sent_at + interval '15 minutes' AND
     resend_available_at = sent_at + interval '60 seconds' AND
     resend_available_at < expires_at) OR
     
    -- Estado failed: e-mail falhou definitivamente, cancelado atômico
    (delivery_status = 'failed' AND 
     delivery_attempts > 0 AND 
     last_delivery_attempt_at IS NOT NULL AND 
     failed_at IS NOT NULL AND 
     sent_at IS NULL AND 
     delivery_failure_reason_private IS NOT NULL AND 
     trim(both from delivery_failure_reason_private) <> '' AND 
     length(delivery_failure_reason_private) <= 250 AND
     expires_at IS NULL AND
     resend_available_at IS NULL)
  ) NOT VALID;

-- 2. Redefinir a Função Privada
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
  v_resend_at timestamptz;
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

  -- 5. Definição dos Tempos (Validade vs Cooldown)
  v_expires_at := v_now + interval '15 minutes';
  v_resend_at := v_now + interval '60 seconds';

  -- 6. Atualização do Desafio
  UPDATE private.account_change_challenges
  SET delivery_status = 'sent',
      sent_at = v_now,
      expires_at = v_expires_at,
      resend_available_at = v_resend_at,
      failed_at = NULL,
      delivery_failure_reason_private = NULL,
      code_ciphertext = NULL,
      code_nonce = NULL,
      code_auth_tag = NULL,
      code_encryption_algorithm = NULL,
      code_encryption_key_version = NULL,
      updated_at = v_now
  WHERE id = p_challenge_id;

  -- 7. Atualização de Hold do Ciclo e da Reserva
  UPDATE private.account_change_email_reservations
  SET cycle_hold_until = GREATEST(coalesce(cycle_hold_until, v_expires_at), v_expires_at),
      updated_at = v_now
  WHERE id = v_reservation_id;

  RETURN jsonb_build_object(
    'result', 'marked_sent',
    'delivery_status', 'sent',
    'send_sequence', v_send_sequence,
    'delivery_attempts', v_delivery_attempts,
    'expires_at', v_expires_at,
    'resend_available_at', v_resend_at
  );
END;
$$;

-- Revoga privilégios de execução pública e de roles para a função privada
REVOKE ALL ON FUNCTION private.conectea_mark_email_change_challenge_sent_v1(
  uuid, uuid, uuid, integer
) FROM PUBLIC, anon, authenticated, service_role;
