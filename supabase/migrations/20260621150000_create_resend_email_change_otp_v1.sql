-- =========================================================================
-- ConeCTEA — Reenvio de OTP de Alteração de E-mail
--
-- MIGRATION: 20260621150000_create_resend_email_change_otp_v1.sql
-- OBJETIVO:
--   1. Criar RPC atômica para transicionar o ciclo para o próximo OTP.
--   2. Validar cooldown e limite máximo de 3 envios.
--   3. Invalidar o challenge anterior mudando seu estado para 'cancelled'.
--   4. Criar o novo challenge com send_sequence incrementado e delivery_attempts zerado.
--
-- STATUS: Criação local da migration para validação. Não aplicar neste turno.
-- =========================================================================

CREATE OR REPLACE FUNCTION public.conectea_resend_email_change_otp_v1(
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
  v_user_id uuid;
  v_now timestamptz;
  v_cycle_id uuid;
  v_masked_email text;
  
  v_old_challenge_id uuid;
  v_old_send_sequence integer;
  v_old_expires_at timestamptz;
  v_old_resend_available_at timestamptz;
  
  v_new_challenge_id uuid;
  v_new_send_sequence integer;
  
  v_idempotency_key uuid;
BEGIN
  -- 1. Validação do Usuário Autenticado
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('result', 'unauthorized');
  END IF;

  -- 2. Validação de Entrada (Material do OTP)
  IF p_code_hmac IS NULL OR trim(both from p_code_hmac) = '' OR length(p_code_hmac) > 128
     OR p_code_ciphertext IS NULL OR trim(both from p_code_ciphertext) = '' OR length(p_code_ciphertext) > 128
     OR p_code_nonce IS NULL OR p_code_nonce !~ '^[A-Za-z0-9_-]{16}$'
     OR p_code_auth_tag IS NULL OR p_code_auth_tag !~ '^[A-Za-z0-9_-]{22}$' THEN
    RETURN jsonb_build_object('result', 'invalid_parameters');
  END IF;

  v_now := transaction_timestamp();

  -- 3. Identificar Ciclo Ativo
  SELECT id, destination_masked INTO v_cycle_id, v_masked_email
  FROM private.account_change_challenge_cycles
  WHERE user_id = v_user_id
    AND purpose = 'email_change'
    AND closed_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'no_active_cycle');
  END IF;

  -- 4. Identificar Challenge Ativo Atual
  SELECT id, send_sequence, expires_at, resend_available_at
  INTO v_old_challenge_id, v_old_send_sequence, v_old_expires_at, v_old_resend_available_at
  FROM private.account_change_challenges
  WHERE cycle_id = v_cycle_id
    AND challenge_state = 'active'
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'no_active_cycle');
  END IF;

  -- 5. Validar Expiração do Ciclo
  IF v_now >= v_old_expires_at THEN
    RETURN jsonb_build_object('result', 'expired_cycle');
  END IF;

  -- 6. Validar Limite de Envios
  IF v_old_send_sequence >= 3 THEN
    RETURN jsonb_build_object('result', 'max_resends_reached');
  END IF;

  -- 7. Validar Cooldown de Reenvio
  IF v_old_resend_available_at IS NOT NULL AND v_now < v_old_resend_available_at THEN
    RETURN jsonb_build_object(
      'result', 'cooldown_active',
      'resend_available_at', v_old_resend_available_at
    );
  END IF;

  -- 8. Lock de Integridade na Reserva
  PERFORM id
  FROM private.account_change_email_reservations
  WHERE cycle_id = v_cycle_id
  FOR UPDATE;

  -- 9. Invalidar Challenge Anterior
  UPDATE private.account_change_challenges
  SET challenge_state = 'cancelled',
      cancelled_at = v_now,
      updated_at = v_now
  WHERE id = v_old_challenge_id;

  -- 10. Criar Novo Challenge
  v_new_challenge_id := gen_random_uuid();
  v_idempotency_key := gen_random_uuid();
  v_new_send_sequence := v_old_send_sequence + 1;

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
    v_new_challenge_id,
    v_cycle_id,
    v_user_id,
    'email_change',
    v_idempotency_key,
    'active',
    'pending',
    0,
    NULL,
    NULL,
    NULL,
    NULL,
    v_new_send_sequence,
    p_code_hmac,
    p_code_hmac_key_version,
    NULL,
    0,
    3,
    NULL,
    p_code_ciphertext,
    p_code_nonce,
    p_code_auth_tag,
    p_code_encryption_algorithm,
    p_code_encryption_key_version,
    v_now,
    v_now
  );

  -- 11. Atualizar Timestamp do Ciclo
  UPDATE private.account_change_challenge_cycles
  SET updated_at = v_now
  WHERE id = v_cycle_id;

  -- 12. Retornar Dados Necessários para a Edge Enviar o E-mail
  RETURN jsonb_build_object(
    'result', 'success',
    'cycle_id', v_cycle_id,
    'challenge_id', v_new_challenge_id,
    'send_sequence', v_new_send_sequence,
    'masked_email', v_masked_email
  );

END;
$$;

-- Restringir a execução apenas para usuários autenticados
REVOKE ALL ON FUNCTION public.conectea_resend_email_change_otp_v1(text, integer, text, text, text, text, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_resend_email_change_otp_v1(text, integer, text, text, text, text, integer) TO authenticated;
