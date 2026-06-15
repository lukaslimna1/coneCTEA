-- =========================================================================
-- ConeCTEA — Claim Atômico do Envio do OTP
--
-- MIGRATION: 20260613150000_create_claim_email_change_challenge_delivery_v1.sql
-- OBJETIVO:
--   1. Criar função privada para obter ou retomar o claim de envio de OTP.
--   2. Criar wrapper RPC público no schema public exposto exclusivamente para a service_role.
--   3. Implementar lock pessimista sequencial para impedir envios concorrentes.
--   4. Validar o lease de 60 segundos antes de permitir novas tentativas de envio de um mesmo OTP.
--   5. Retornar payloads criptografados necessários para o envio na Edge Function.
--   6. Documentar regras de concorrência, fencing token (delivery_attempts) e idempotência do GAS.
--
-- STATUS: Criação local da migration para validação.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. FUNÇÃO PRIVADA: private.conectea_claim_email_change_challenge_delivery_v1
-- ─────────────────────────────────────────────────────────────────────────

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
    code_encryption_key_version
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
    v_code_encryption_key_version
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
    -- B.1 Lease Ativo: bloqueia tentativas concorrentes
    IF v_now < v_last_delivery_attempt_at + v_lease_interval THEN
      RETURN jsonb_build_object(
        'result', 'lease_active',
        'claimed', false,
        'delivery_attempts', v_delivery_attempts
      );
    END IF;

    -- B.2 Lease Vencido: permite claim de retry reutilizando o mesmo OTP criptografado
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

-- ─────────────────────────────────────────────────────────────────────────
-- 2. WRAPPER RPC PÚBLICA: public.conectea_claim_email_change_challenge_delivery_v1
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_claim_email_change_challenge_delivery_v1(
  p_user_id uuid,
  p_cycle_id uuid,
  p_challenge_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
BEGIN
  -- Delega execução para a rotina privada
  RETURN private.conectea_claim_email_change_challenge_delivery_v1(
    p_user_id := p_user_id,
    p_cycle_id := p_cycle_id,
    p_challenge_id := p_challenge_id
  );
END;
$$;

-- Revoga privilégios públicos e de usuários autenticados da RPC pública
REVOKE ALL ON FUNCTION public.conectea_claim_email_change_challenge_delivery_v1(
  uuid, uuid, uuid
) FROM PUBLIC, anon, authenticated;

-- Concede execução restrita e exclusiva à service_role
GRANT EXECUTE ON FUNCTION public.conectea_claim_email_change_challenge_delivery_v1(
  uuid, uuid, uuid
) TO service_role;

-- ─────────────────────────────────────────────────────────────────────────
-- 3. DOCUMENTAÇÃO OPERACIONAL E REGRAS DE CONCORRÊNCIA
-- ─────────────────────────────────────────────────────────────────────────

COMMENT ON FUNCTION public.conectea_claim_email_change_challenge_delivery_v1 IS
  'Wrapper RPC pública para obter ou retomar o claim de envio do OTP.
   A. REGRAS DE AUTORIZAÇÃO EXTERNA E CONTRATO DE FLUXO:
     1. A sinalização de should_send obtida no sucesso da reautenticação NÃO autoriza o envio direto ao GAS.
     2. A Edge Function só está autorizada a disparar o HTTP para o GAS após obter claimed = true nesta RPC.
     3. O claim é persistido e comitado no banco de dados antes da chamada HTTP externa. Nenhuma transação permanece aberta durante a chamada ao GAS.
     4. A ocorrência de timeout na chamada Edge -> GAS mantém o delivery_status como "sending" e nunca o altera para "failed". O retry reutiliza o mesmo desafio e OTP.
     5. O Flutter nunca executa chamadas diretas a esta RPC pública.
   B. HIERARQUIA DE LOCKS E EVITAÇÃO DE DEADLOCKS:
     1. A aquisição de locks pessimistas segue rigorosamente a ordem estrutural: public.profiles -> private.account_change_challenge_cycles -> private.account_change_challenges.
     2. O lock FOR UPDATE impede que duas requisições paralelas obtenham a propriedade do claim de envio do mesmo desafio simultaneamente.
   C. TRATAMENTO DE TIMEOUT OPERACIONAL (LEASE) E FENCING TOKEN:
     1. O lease de envio atual é configurado estritamente como 60 segundos baseando-se no transaction_timestamp() do PostgreSQL.
     2. O lease baseia-se na premissa de que a futura chamada HTTP Edge -> GAS terá timeout máximo inicial de 20 segundos. Os 40 segundos restantes formam a margem operacional necessária para latências de infraestrutura, processamento e retorno. Qualquer alteração futura no timeout HTTP exige obrigatoriamente a reavaliação do lease.
     3. Qualquer chamada com status "sending" cujo last_delivery_attempt_at seja anterior a (now() - lease) é considerada elegível para novo claim (retry) e retomada do mesmo OTP.
     4. O delivery_attempts é retornado como fencing token obrigatório para consolidar o estado (mark_sent/mark_failed).
     5. Um worker antigo cujo lease expirou não conseguirá consolidar o estado, pois sua chamada fornecerá um p_expected_delivery_attempts defasado, gerando rejeição por stale_claim.
   D. IDEMPOTÊNCIA MANDATÓRIA DO GAS:
     1. O lease de claim do banco de dados não substitui a idempotência obrigatória da integração síncrona do GAS.
     2. A futura implementação no GAS deverá possuir lock e armazenamento para validar de forma estritamente idempotente a chave composta por purpose + challenge_id + send_sequence.
     3. Replays no GAS devem responder o resultado de envio existente sem disparar novamente o MailApp. O delivery_attempts não faz parte da chave idempotente do GAS.';
