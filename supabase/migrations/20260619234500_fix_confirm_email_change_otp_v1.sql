-- =========================================================================
-- ConeCTEA — Correção da Consolidação de Sucesso (Adiciona closed_at)
--
-- MIGRATION: 20260619234500_fix_confirm_email_change_otp_v1.sql
-- OBJETIVO:
--   Corrigir conectea_consolidate_email_change_success_v1 para preencher
--   closed_at ao marcar o request como completed, respeitando a constraint
--   chk_conectea_change_closure.
-- =========================================================================

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

  -- 4. Atualizar status do protocolo para completed (adicionando closed_at)
  UPDATE public.account_change_requests
  SET status = 'completed',
      application_completed_at = v_now,
      closed_at = v_now,
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

-- Recriar Wrapper RPC pública para garantir consistência e search_path
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

-- Revoga privilégios para usuários comuns (anon, authenticated, PUBLIC) na wrapper
REVOKE ALL ON FUNCTION public.conectea_consolidate_email_change_success_v1(uuid, uuid, text) FROM PUBLIC, anon, authenticated;

-- Concede execução exclusiva à service_role
GRANT EXECUTE ON FUNCTION public.conectea_consolidate_email_change_success_v1(uuid, uuid, text) TO service_role;

COMMENT ON FUNCTION public.conectea_consolidate_email_change_success_v1 IS
  'Wrapper RPC publica restrita a service_role para consolidar o sucesso da aplicacao da mudanca de email. Atualiza o email em profiles, define closed_at e atualiza o protocolo para completed.';
