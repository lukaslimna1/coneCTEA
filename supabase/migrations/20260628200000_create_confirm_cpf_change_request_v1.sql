-- =========================================================================
-- ConeCTEA — RPC de Confirmação de Troca de CPF pelo Titular
--
-- MIGRATION: 20260628200000_create_confirm_cpf_change_request_v1.sql
-- OBJETIVO:
--   Criar a RPC segura conectea_confirm_cpf_change_request_v1 para que
--   o próprio usuário titular confirme e aplique a troca de CPF.
-- =========================================================================

CREATE OR REPLACE FUNCTION public.conectea_confirm_cpf_change_request_v1(
  p_request_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $$
DECLARE
  v_caller_id uuid;
  v_status public.account_change_status;
  v_type public.account_change_type;
  v_user_id uuid;
  v_deadline timestamptz;
  v_now timestamptz;
  v_old_cpf_clear text;
  v_new_cpf_clear text;
  v_current_cpf text;
BEGIN
  -- 1. Validar autenticacao
  v_caller_id := auth.uid();
  IF v_caller_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'unauthenticated');
  END IF;

  IF p_request_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_parameters');
  END IF;

  v_now := transaction_timestamp();

  -- 2. Buscar e bloquear a requisicao para evitar concorrencia (FOR UPDATE)
  SELECT status, type, user_id, holder_deadline_exclusive_at
  INTO v_status, v_type, v_user_id, v_deadline
  FROM public.account_change_requests
  WHERE id = p_request_id
  FOR UPDATE;

  -- 3. Validar existencia
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'not_found');
  END IF;

  -- 4. Validar tipo
  IF v_type <> 'cpf'::public.account_change_type THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_type');
  END IF;

  -- 5. Validar titularidade
  IF v_user_id <> v_caller_id THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'forbidden');
  END IF;

  -- 6. Validar status da maquina de estados
  IF v_status <> 'waiting_holder_confirmation'::public.account_change_status THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_status');
  END IF;

  -- 7. Validar prazo de confirmacao
  IF v_deadline IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'internal_error');
  END IF;

  IF v_now >= v_deadline THEN
    -- Prazo expirou: abortar alteracao
    UPDATE public.account_change_requests
    SET status = 'expired'::public.account_change_status,
        resolution_reason = 'holder_confirmation_deadline'::public.account_change_resolution_reason,
        closed_at = v_now,
        status_changed_at = v_now,
        updated_at = v_now,
        admin_deadline_started_at = NULL,
        admin_deadline_exclusive_at = NULL,
        holder_deadline_started_at = NULL,
        holder_deadline_exclusive_at = NULL
    WHERE id = p_request_id;
    
    RETURN jsonb_build_object('success', false, 'error_code', 'expired');
  END IF;

  -- 8. Ler dados puros e sensiveis da tabela de auditoria privada
  SELECT old_cpf_clear, new_cpf_clear
  INTO v_old_cpf_clear, v_new_cpf_clear
  FROM private.account_change_review_data
  WHERE request_id = p_request_id;

  IF NOT FOUND OR v_old_cpf_clear IS NULL OR v_new_cpf_clear IS NULL THEN
    -- Falha na estrutura de dados de auditoria
    UPDATE public.account_change_requests
    SET status = 'application_failed'::public.account_change_status,
        failure_code = 'missing_review_data',
        status_changed_at = transaction_timestamp(),
        updated_at = transaction_timestamp(),
        admin_deadline_started_at = NULL,
        admin_deadline_exclusive_at = NULL,
        holder_deadline_started_at = NULL,
        holder_deadline_exclusive_at = NULL
    WHERE id = p_request_id;
    RETURN jsonb_build_object('success', false, 'error_code', 'missing_review_data');
  END IF;

  -- Validacao adicional de formato numerico (Sanity Check)
  IF length(v_old_cpf_clear) <> 11 OR v_old_cpf_clear !~ '^[0-9]+$' OR
     length(v_new_cpf_clear) <> 11 OR v_new_cpf_clear !~ '^[0-9]+$' THEN
    UPDATE public.account_change_requests
    SET status = 'application_failed'::public.account_change_status,
        failure_code = 'invalid_cpf_data',
        status_changed_at = transaction_timestamp(),
        updated_at = transaction_timestamp(),
        admin_deadline_started_at = NULL,
        admin_deadline_exclusive_at = NULL,
        holder_deadline_started_at = NULL,
        holder_deadline_exclusive_at = NULL
    WHERE id = p_request_id;
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_cpf_data');
  END IF;

  -- 9. Iniciar aplicacao
  -- Muda status para applying para garantir logs transacionais
  UPDATE public.account_change_requests
  SET status = 'applying'::public.account_change_status,
      status_changed_at = v_now,
      application_started_at = v_now,
      holder_confirmed_at = v_now,
      updated_at = v_now,
      admin_deadline_started_at = NULL,
      admin_deadline_exclusive_at = NULL,
      holder_deadline_started_at = NULL,
      holder_deadline_exclusive_at = NULL
  WHERE id = p_request_id;

  -- 10. Bloquear e validar CPF atual no profile do usuario
  SELECT cpf INTO v_current_cpf
  FROM public.profiles
  WHERE id = v_user_id
  FOR UPDATE;

  IF COALESCE(v_current_cpf, '') IS DISTINCT FROM v_old_cpf_clear THEN
    -- Mismatch: o CPF no banco mudou inesperadamente durante o ciclo de revisao
    UPDATE public.account_change_requests
    SET status = 'application_failed'::public.account_change_status,
        failure_code = 'current_cpf_mismatch',
        status_changed_at = transaction_timestamp(),
        updated_at = transaction_timestamp()
    WHERE id = p_request_id;
    RETURN jsonb_build_object('success', false, 'error_code', 'current_cpf_mismatch');
  END IF;

  -- 11. Aplicacao Transacional do Novo CPF
  BEGIN
    -- Atualiza Profiles (Base)
    UPDATE public.profiles
    SET cpf = v_new_cpf_clear
    WHERE id = v_user_id;

    -- Atualiza Members vinculados ao titular (user_id forte como garantia de propriedade)
    UPDATE public.members
    SET cpf = v_new_cpf_clear
    WHERE user_id = v_user_id AND cpf = v_old_cpf_clear;

    -- Concluir requisicao
    UPDATE public.account_change_requests
    SET status = 'completed'::public.account_change_status,
        closed_at = transaction_timestamp(),
        status_changed_at = transaction_timestamp(),
        application_completed_at = transaction_timestamp(),
        updated_at = transaction_timestamp()
    WHERE id = p_request_id;

    RETURN jsonb_build_object('success', true, 'request_id', p_request_id, 'status', 'completed');

  EXCEPTION WHEN unique_violation THEN
    -- Conflito de CPF (Constraint Unique de CPF foi acionada)
    UPDATE public.account_change_requests
    SET status = 'application_failed'::public.account_change_status,
        failure_code = 'cpf_conflict',
        status_changed_at = transaction_timestamp(),
        updated_at = transaction_timestamp()
    WHERE id = p_request_id;
    
    RETURN jsonb_build_object('success', false, 'error_code', 'cpf_conflict');
  WHEN OTHERS THEN
    -- Falha transacional interna e imprevista
    UPDATE public.account_change_requests
    SET status = 'application_failed'::public.account_change_status,
        failure_code = 'internal_error',
        status_changed_at = transaction_timestamp(),
        updated_at = transaction_timestamp()
    WHERE id = p_request_id;
    
    RETURN jsonb_build_object('success', false, 'error_code', 'internal_error');
  END;
END;
$$;

COMMENT ON FUNCTION public.conectea_confirm_cpf_change_request_v1(uuid) IS
  'RPC para o titular confirmar e aplicar definitivamente a troca de CPF. Altera o CPF em profiles e members associados de forma transacional.';

REVOKE ALL ON FUNCTION public.conectea_confirm_cpf_change_request_v1(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_confirm_cpf_change_request_v1(uuid) TO authenticated;
