-- =========================================================================
-- ConeCTEA — Cutoff do Retry de Entrega de OTP
--
-- MIGRATION: 20260613180000_add_email_change_claim_retry_cutoff_v1.sql
-- OBJETIVO:
--   1. Redefinir a função privada de claim para adicionar cutoff de 2 horas.
--   2. Realizar reconciliação atômica se o cutoff e lease expirarem (failed/cancelled).
--   3. Preservar o lease atual se o cutoff passou mas o lease ainda estiver ativo.
--   4. Garantir que as tabelas de ciclo e reserva sejam atualizadas na ordem correta.
--
-- STATUS: Migração corretiva local. A ser aplicada após auditoria.
-- =========================================================================

CREATE OR REPLACE FUNCTION private.conectea_claim_email_change_challenge_delivery_v1(
  p_user_id uuid,
  p_cycle_id uuid,
  p_challenge_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_profile_id uuid;

  -- Variáveis do Ciclo
  v_cycle_purpose text;
  v_cycle_closed_at timestamptz;
  v_destination_ciphertext text;
  v_destination_nonce text;
  v_destination_auth_tag text;
  v_dest_encryption_algorithm text;
  v_dest_encryption_key_version integer;

  -- Variáveis do Desafio
  v_challenge_state text;
  v_delivery_status text;
  v_delivery_attempts integer;
  v_last_delivery_attempt_at timestamptz;
  v_send_sequence integer;
  v_challenge_created_at timestamptz;

  -- Material criptográfico do OTP
  v_code_ciphertext text;
  v_code_nonce text;
  v_code_auth_tag text;
  v_code_encryption_algorithm text;
  v_code_encryption_key_version integer;

  -- Variáveis Operacionais
  v_now timestamptz;
  v_new_attempts integer;
  v_lease_interval CONSTANT interval := interval '60 seconds';

  -- Variáveis de Reconciliação
  v_reservation_id uuid;
BEGIN
  -- 1. Validação de Parâmetros Nulos
  IF p_user_id IS NULL OR p_cycle_id IS NULL OR p_challenge_id IS NULL THEN
    RETURN jsonb_build_object('result', 'invalid_request');
  END IF;

  v_now := transaction_timestamp();

  -- 2. Lock sequencial e ordenado
  -- Lock 1: Profiles
  SELECT id INTO v_profile_id
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'challenge_mismatch');
  END IF;

  -- Lock 2: Ciclo
  SELECT
    purpose,
    closed_at,
    destination_ciphertext,
    destination_nonce,
    destination_auth_tag,
    encryption_algorithm,
    encryption_key_version
  INTO
    v_cycle_purpose,
    v_cycle_closed_at,
    v_destination_ciphertext,
    v_destination_nonce,
    v_destination_auth_tag,
    v_dest_encryption_algorithm,
    v_dest_encryption_key_version
  FROM private.account_change_challenge_cycles
  WHERE id = p_cycle_id AND user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_cycle_purpose <> 'email_change' THEN
    RETURN jsonb_build_object('result', 'challenge_mismatch');
  END IF;

  IF v_cycle_closed_at IS NOT NULL THEN
    RETURN jsonb_build_object('result', 'cycle_closed');
  END IF;

  -- Lock 3: Desafio
  SELECT
    challenge_state,
    delivery_status,
    delivery_attempts,
    last_delivery_attempt_at,
    send_sequence,
    code_ciphertext,
    code_nonce,
    code_auth_tag,
    code_encryption_algorithm,
    code_encryption_key_version,
    created_at
  INTO
    v_challenge_state,
    v_delivery_status,
    v_delivery_attempts,
    v_last_delivery_attempt_at,
    v_send_sequence,
    v_code_ciphertext,
    v_code_nonce,
    v_code_auth_tag,
    v_code_encryption_algorithm,
    v_code_encryption_key_version,
    v_challenge_created_at
  FROM private.account_change_challenges
  WHERE id = p_challenge_id
    AND cycle_id = p_cycle_id
    AND user_id = p_user_id
    AND purpose = 'email_change'
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'challenge_mismatch');
  END IF;

  -- 3. Verificação de Estados Lógicos Terminais do Desafio
  IF v_challenge_state IN ('consumed', 'expired', 'cancelled', 'blocked') THEN
    RETURN jsonb_build_object(
      'result', 'challenge_terminal',
      'claimed', false,
      'challenge_state', v_challenge_state
    );
  END IF;

  -- 4. Verificação de Status de Entrega
  IF v_delivery_status = 'sent' THEN
    RETURN jsonb_build_object(
      'result', 'already_sent',
      'claimed', false
    );
  ELSIF v_delivery_status = 'failed' THEN
    RETURN jsonb_build_object(
      'result', 'delivery_failed',
      'claimed', false
    );
  END IF;

  -- 5. Validação da Existência Completa do Material Criptográfico Obrigatório
  IF v_destination_ciphertext IS NULL OR trim(v_destination_ciphertext) = ''
     OR v_destination_nonce IS NULL OR trim(v_destination_nonce) = ''
     OR v_destination_auth_tag IS NULL OR trim(v_destination_auth_tag) = ''
     OR v_dest_encryption_algorithm IS NULL OR trim(v_dest_encryption_algorithm) = ''
     OR v_dest_encryption_key_version IS NULL OR v_dest_encryption_key_version <= 0
     OR v_code_ciphertext IS NULL OR trim(v_code_ciphertext) = ''
     OR v_code_nonce IS NULL OR trim(v_code_nonce) = ''
     OR v_code_auth_tag IS NULL OR trim(v_code_auth_tag) = ''
     OR v_code_encryption_algorithm IS NULL OR trim(v_code_encryption_algorithm) = ''
     OR v_code_encryption_key_version IS NULL OR v_code_encryption_key_version <= 0
  THEN
    RETURN jsonb_build_object('result', 'invalid_delivery_material');
  END IF;

  -- 6. Transição Lógica por Delivery Status
  -- CASO A: Estado pending (Primeiro envio)
  IF v_delivery_status = 'pending' THEN
    UPDATE private.account_change_challenges
    SET delivery_status = 'sending',
        delivery_attempts = delivery_attempts + 1,
        last_delivery_attempt_at = v_now,
        updated_at = v_now
    WHERE id = p_challenge_id
    RETURNING delivery_attempts INTO v_new_attempts;

    RETURN jsonb_build_object(
      'result', 'claimed_pending',
      'claimed', true,
      'challenge_id', p_challenge_id,
      'cycle_id', p_cycle_id,
      'send_sequence', v_send_sequence,
      'delivery_attempts', v_new_attempts,
      'destination_ciphertext', v_destination_ciphertext,
      'destination_nonce', v_destination_nonce,
      'destination_auth_tag', v_destination_auth_tag,
      'destination_encryption_algorithm', v_dest_encryption_algorithm,
      'destination_encryption_key_version', v_dest_encryption_key_version,
      'code_ciphertext', v_code_ciphertext,
      'code_nonce', v_code_nonce,
      'code_auth_tag', v_code_auth_tag,
      'code_encryption_algorithm', v_code_encryption_algorithm,
      'code_encryption_key_version', v_code_encryption_key_version
    );

  -- CASO B: Estado sending
  ELSIF v_delivery_status = 'sending' THEN
    -- B.1 Validar se o cutoff de 2 horas já expirou
    IF v_now >= v_challenge_created_at + interval '2 hours' THEN
      -- Se o lease operacional ainda estiver ativo (lease não expirou),
      -- retornamos o comportamento de lease ativo SEM realizar a reconciliação
      IF v_now < v_last_delivery_attempt_at + v_lease_interval THEN
        RETURN jsonb_build_object(
          'result', 'lease_active',
          'claimed', false,
          'delivery_attempts', v_delivery_attempts
        );
      END IF;

      -- Reconciliação por Cutoff (Lease vencido e Cutoff vencido)
      -- Lock 4: Reservations
      SELECT id INTO v_reservation_id
      FROM private.account_change_email_reservations
      WHERE cycle_id = p_cycle_id AND user_id = p_user_id AND purpose = 'email_change'
      FOR UPDATE;

      IF NOT FOUND THEN
        RETURN jsonb_build_object('result', 'challenge_mismatch', 'claimed', false);
      END IF;

      -- Atualizar o desafio
      UPDATE private.account_change_challenges
      SET delivery_status = 'failed',
          challenge_state = 'cancelled',
          failed_at = v_now,
          cancelled_at = v_now,
          delivery_failure_reason_private = 'retry_cutoff_expired',
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

      -- Atualizar o ciclo
      UPDATE private.account_change_challenge_cycles
      SET closed_at = v_now,
          updated_at = v_now
      WHERE id = p_cycle_id;

      -- Atualizar a reserva (FK composta fk_conectea_reservation_cycle_closed exige fechamento coerente)
      UPDATE private.account_change_email_reservations
      SET reservation_state = 'released',
          cycle_closed_at = v_now,
          released_at = v_now,
          release_reason = 'retry_cutoff_expired',
          updated_at = v_now
      WHERE id = v_reservation_id;

      RETURN jsonb_build_object(
        'result', 'delivery_retry_expired',
        'claimed', false
      );
    END IF;

    -- B.2 Cutoff não atingido: comportamento normal de lease ativo
    IF v_now < v_last_delivery_attempt_at + v_lease_interval THEN
      RETURN jsonb_build_object(
        'result', 'lease_active',
        'claimed', false,
        'delivery_attempts', v_delivery_attempts
      );
    END IF;

    -- B.3 Lease vencido e dentro da janela de cutoff: permite claim de retry
    UPDATE private.account_change_challenges
    SET delivery_attempts = delivery_attempts + 1,
        last_delivery_attempt_at = v_now,
        updated_at = v_now
    WHERE id = p_challenge_id
    RETURNING delivery_attempts INTO v_new_attempts;

    RETURN jsonb_build_object(
      'result', 'claimed_retry',
      'claimed', true,
      'challenge_id', p_challenge_id,
      'cycle_id', p_cycle_id,
      'send_sequence', v_send_sequence,
      'delivery_attempts', v_new_attempts,
      'destination_ciphertext', v_destination_ciphertext,
      'destination_nonce', v_destination_nonce,
      'destination_auth_tag', v_destination_auth_tag,
      'destination_encryption_algorithm', v_dest_encryption_algorithm,
      'destination_encryption_key_version', v_dest_encryption_key_version,
      'code_ciphertext', v_code_ciphertext,
      'code_nonce', v_code_nonce,
      'code_auth_tag', v_code_auth_tag,
      'code_encryption_algorithm', v_code_encryption_algorithm,
      'code_encryption_key_version', v_code_encryption_key_version
    );
  END IF;

  RETURN jsonb_build_object('result', 'invalid_request');
END;
$$;

-- Revoga privilégios de execução pública da rotina privada
REVOKE ALL ON FUNCTION private.conectea_claim_email_change_challenge_delivery_v1(
  uuid, uuid, uuid
) FROM PUBLIC, anon, authenticated, service_role;

COMMENT ON FUNCTION private.conectea_claim_email_change_challenge_delivery_v1 IS
  'Redefinicao da rotina privada de claim de envio do OTP adicionando cutoff server-side de 2 horas.
   Impede claims infinitos de desafios que fiquem travados em estado sending.
   A reconciliacao desativa o desafio, o ciclo e libera a reserva do e-mail de destino de forma transacional.';
