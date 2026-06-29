-- =========================================================================
-- ConeCTEA — Correção Transacional da Carteirinha Digital (Troca de CPF)
--
-- MIGRATION: 20260628205000_sync_digital_card_cpf_on_account_cpf_confirm_v1.sql
-- OBJETIVO:
--   Recriar a RPC conectea_confirm_cpf_change_request_v1 garantindo que a carteirinha
--   digital (tabela public.digital_cards) também receba o novo CPF, mantendo
--   atomicidade com a atualização das tabelas profiles e members.
--   A atualização na carteirinha deve preservar o formato visual original e
--   ser restrita a carteirinhas cujo CPF (normalizado) coincida com o CPF antigo
--   (blindagem contra substituição indevida em carteirinhas de dependentes).
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
  v_new_cpf_formatted text;
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

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'not_found');
  END IF;

  IF v_type <> 'cpf'::public.account_change_type THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_type');
  END IF;

  IF v_user_id <> v_caller_id THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'forbidden');
  END IF;

  IF v_status <> 'waiting_holder_confirmation'::public.account_change_status THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_status');
  END IF;

  IF v_deadline IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'internal_error');
  END IF;

  IF v_now >= v_deadline THEN
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

  -- Ler dados puros e sensiveis da tabela de auditoria privada
  SELECT old_cpf_clear, new_cpf_clear
  INTO v_old_cpf_clear, v_new_cpf_clear
  FROM private.account_change_review_data
  WHERE request_id = p_request_id;

  IF NOT FOUND OR v_old_cpf_clear IS NULL OR v_new_cpf_clear IS NULL THEN
    UPDATE public.account_change_requests
    SET status = 'application_failed'::public.account_change_status,
        failure_code = 'missing_review_data',
        closed_at = transaction_timestamp(),
        status_changed_at = transaction_timestamp(),
        updated_at = transaction_timestamp(),
        admin_deadline_started_at = NULL,
        admin_deadline_exclusive_at = NULL,
        holder_deadline_started_at = NULL,
        holder_deadline_exclusive_at = NULL
    WHERE id = p_request_id;
    RETURN jsonb_build_object('success', false, 'error_code', 'missing_review_data');
  END IF;

  IF length(v_old_cpf_clear) <> 11 OR v_old_cpf_clear !~ '^[0-9]+$' OR
     length(v_new_cpf_clear) <> 11 OR v_new_cpf_clear !~ '^[0-9]+$' THEN
    UPDATE public.account_change_requests
    SET status = 'application_failed'::public.account_change_status,
        failure_code = 'invalid_cpf_data',
        closed_at = transaction_timestamp(),
        status_changed_at = transaction_timestamp(),
        updated_at = transaction_timestamp(),
        admin_deadline_started_at = NULL,
        admin_deadline_exclusive_at = NULL,
        holder_deadline_started_at = NULL,
        holder_deadline_exclusive_at = NULL
    WHERE id = p_request_id;
    RETURN jsonb_build_object('success', false, 'error_code', 'invalid_cpf_data');
  END IF;

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

  -- Bloquear e validar CPF atual no profile do usuario
  SELECT regexp_replace(coalesce(cpf, ''), '[^0-9]', '', 'g') INTO v_current_cpf
  FROM public.profiles
  WHERE id = v_user_id
  FOR UPDATE;

  IF v_current_cpf IS DISTINCT FROM v_old_cpf_clear THEN
    UPDATE public.account_change_requests
    SET status = 'application_failed'::public.account_change_status,
        failure_code = 'current_cpf_mismatch',
        closed_at = transaction_timestamp(),
        status_changed_at = transaction_timestamp(),
        updated_at = transaction_timestamp()
    WHERE id = p_request_id;
    RETURN jsonb_build_object('success', false, 'error_code', 'current_cpf_mismatch');
  END IF;

  -- Formatação auxiliar do CPF para inserção visual na carteirinha
  v_new_cpf_formatted := substr(v_new_cpf_clear, 1, 3) || '.' ||
                         substr(v_new_cpf_clear, 4, 3) || '.' ||
                         substr(v_new_cpf_clear, 7, 3) || '-' ||
                         substr(v_new_cpf_clear, 10, 2);

  BEGIN
    -- Permitir o bypass da protecao do perfil localmente
    PERFORM set_config('conectea.bypass_cpf_protection', 'true', true);

    -- 1. Atualiza Profiles (Base)
    UPDATE public.profiles
    SET cpf = v_new_cpf_clear
    WHERE id = v_user_id;

    -- 2. Atualiza Members vinculados ao titular (uso de expressao regular compativel com null-safety)
    UPDATE public.members
    SET cpf = v_new_cpf_clear
    WHERE user_id = v_user_id AND regexp_replace(coalesce(cpf, ''), '[^0-9]', '', 'g') = v_old_cpf_clear;

    -- 3. Atualiza Carteirinha (digital_cards) mantendo formato visual e protegendo dependentes
    UPDATE public.digital_cards
    SET front_data = jsonb_set(
          coalesce(front_data, '{}'::jsonb),
          '{cpf}',
          CASE 
            WHEN (front_data->>'cpf') LIKE '%-%' THEN to_jsonb(v_new_cpf_formatted)
            ELSE to_jsonb(v_new_cpf_clear)
          END
        ),
        updated_at = transaction_timestamp()
    WHERE user_id = v_user_id
      AND regexp_replace(coalesce(front_data->>'cpf', ''), '[^0-9]', '', 'g') = v_old_cpf_clear;

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
    UPDATE public.account_change_requests
    SET status = 'application_failed'::public.account_change_status,
        failure_code = 'cpf_conflict',
        closed_at = transaction_timestamp(),
        status_changed_at = transaction_timestamp(),
        updated_at = transaction_timestamp()
    WHERE id = p_request_id;
    RETURN jsonb_build_object('success', false, 'error_code', 'cpf_conflict');
  WHEN OTHERS THEN
    UPDATE public.account_change_requests
    SET status = 'application_failed'::public.account_change_status,
        failure_code = 'internal_error',
        closed_at = transaction_timestamp(),
        status_changed_at = transaction_timestamp(),
        updated_at = transaction_timestamp()
    WHERE id = p_request_id;
    RETURN jsonb_build_object('success', false, 'error_code', 'internal_error');
  END;
END;
$$;
