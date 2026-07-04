-- =========================================================================
-- ConeCTEA — Correção de escopo de conflito de CPF na aprovação direta de dependente
--
-- MIGRATION: 20260704154000_fix_dependent_cpf_approval_account_conflict_scope_v1.sql
-- =========================================================================

CREATE OR REPLACE FUNCTION public.conectea_admin_prepare_dependent_cpf_change_direct_v1(
  p_request_id uuid,
  p_admin_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private, pg_temp
AS $$
DECLARE
  v_role text;
  v_request record;
  v_member record;
  v_review record;
  v_reservation record;
  v_new_cpf_normalized text;
  v_old_cpf_normalized text;
  v_member_cpf_normalized text;
  v_cpf_in_use boolean;
  v_parent_cpf text;
  v_parent_cpf_normalized text;
  v_now timestamptz;
BEGIN
  -- A. Validar nulos
  IF p_request_id IS NULL OR p_admin_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_parameters',
      'message', 'Parâmetros de entrada inválidos.'
    );
  END IF;

  v_now := transaction_timestamp();

  -- B. Validar role de admin (Master ou Dev)
  SELECT role INTO v_role
  FROM public.profiles
  WHERE id = p_admin_user_id;

  IF v_role IS NULL OR v_role NOT IN ('admin_master', 'admin_dev') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'forbidden',
      'message', 'Acesso negado: privilégios insuficientes.'
    );
  END IF;

  -- C. Buscar e bloquear a solicitação (FOR UPDATE)
  SELECT id, user_id, member_id, status, expires_at
  INTO v_request
  FROM public.dependent_cpf_change_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'not_found',
      'message', 'Solicitação administrativa não encontrada.'
    );
  END IF;

  -- Validar status
  IF v_request.status <> 'under_review' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status',
      'message', 'Esta solicitação não está aguardando análise.'
    );
  END IF;

  -- Validar expiração
  IF v_request.expires_at IS NOT NULL AND v_now >= v_request.expires_at THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'expired',
      'message', 'Esta solicitação já expirou.'
    );
  END IF;

  -- D. Buscar e bloquear o dependente correspondente (FOR UPDATE)
  SELECT id, status, user_id, cpf
  INTO v_member
  FROM public.members
  WHERE id = v_request.member_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'member_not_found',
      'message', 'Beneficiário dependente não cadastrado ou removido.'
    );
  END IF;

  -- Validar se o dependente pertence ao titular correto da solicitação
  IF v_member.user_id <> v_request.user_id THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'forbidden',
      'message', 'O dependente não pertence ao titular desta solicitação.'
    );
  END IF;

  -- Validar se o dependente está em status operacional válido
  IF v_member.status NOT IN ('active', 'approved') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request',
      'message', 'O cadastro do dependente não está ativo.'
    );
  END IF;

  -- E. Buscar e bloquear os dados sensíveis da revisão (FOR UPDATE)
  SELECT old_cpf_clear, new_cpf_clear, document_file_id, document_state
  INTO v_review
  FROM private.dependent_cpf_change_review_data
  WHERE request_id = p_request_id
  FOR UPDATE;

  IF NOT FOUND OR v_review.new_cpf_clear IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'missing_review_data',
      'message', 'Dados confidenciais de revisão indisponíveis.'
    );
  END IF;

  -- Validar estado do documento anexado
  IF v_review.document_state <> 'available' OR v_review.document_file_id IS NULL OR btrim(v_review.document_file_id) = '' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'document_unavailable',
      'message', 'Documento sob auditoria indisponível ou já descartado.'
    );
  END IF;

  -- F. Normalizar e validar o novo CPF solicitado
  v_new_cpf_normalized := regexp_replace(v_review.new_cpf_clear, '[^0-9]', '', 'g');
  IF length(v_new_cpf_normalized) <> 11 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_cpf',
      'message', 'O formato do CPF solicitado é inválido.'
    );
  END IF;

  -- F2. Validar se old_cpf_clear confere com o CPF atual do member (blindagem de concorrência)
  IF v_review.old_cpf_clear IS NULL OR btrim(v_review.old_cpf_clear) = '' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'missing_review_data',
      'message', 'Dados de CPF anterior indisponíveis na revisão.'
    );
  END IF;

  v_old_cpf_normalized := regexp_replace(v_review.old_cpf_clear, '[^0-9]', '', 'g');
  v_member_cpf_normalized := COALESCE(regexp_replace(v_member.cpf, '[^0-9]', '', 'g'), '');

  IF v_member_cpf_normalized <> v_old_cpf_normalized THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'member_cpf_changed',
      'message', 'O CPF atual do dependente mudou desde a abertura da solicitação.'
    );
  END IF;

  -- G. Checar conflitos de duplicidade do CPF solicitado
  -- 1. Em outros dependentes (members)
  SELECT EXISTS (
    SELECT 1 
    FROM public.members 
    WHERE id <> v_request.member_id
      AND cpf IS NOT NULL 
      AND regexp_replace(cpf, '[^0-9]', '', 'g') = v_new_cpf_normalized
  ) INTO v_cpf_in_use;

  IF v_cpf_in_use THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'cpf_in_use',
      'message', 'O CPF solicitado já está cadastrado em outro dependente.'
    );
  END IF;

  -- 2. Validar conflito restrito com o CPF do titular daquela conta (pai do dependente)
  SELECT cpf INTO v_parent_cpf
  FROM public.profiles
  WHERE id = v_request.user_id;

  v_parent_cpf_normalized := COALESCE(regexp_replace(v_parent_cpf, '[^0-9]', '', 'g'), '');

  IF v_new_cpf_normalized = v_parent_cpf_normalized OR v_old_cpf_normalized = v_parent_cpf_normalized THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'account_cpf_conflict',
      'message', 'O CPF do dependente não pode ser igual ao CPF do titular da conta.'
    );
  END IF;

  -- H. Buscar e bloquear a reserva por HMAC
  SELECT id, reservation_state
  INTO v_reservation
  FROM private.dependent_cpf_change_reservations
  WHERE request_id = p_request_id
  FOR UPDATE;

  IF NOT FOUND OR v_reservation.reservation_state <> 'attached' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'reservation_unavailable',
      'message', 'Reserva exclusiva de CPF inativa ou corrompida.'
    );
  END IF;

  -- I. Marcar status como 'applying'
  UPDATE public.dependent_cpf_change_requests
  SET status = 'applying',
      updated_at = v_now
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'status', 'applying',
    'document_file_id', v_review.document_file_id
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error_code', 'internal_error',
    'message', 'Erro operacional interno ao preparar a alteração.'
  );
END;
$$;

-- Restrição de privilégios de execução
REVOKE ALL ON FUNCTION public.conectea_admin_prepare_dependent_cpf_change_direct_v1(uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_prepare_dependent_cpf_change_direct_v1(uuid, uuid) TO service_role;


-- ─────────────────────────────────────────────────────────────────────────
-- FUNÇÃO 2: EFETIVAR A APROVAÇÃO (COMMIT)
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_admin_commit_dependent_cpf_change_direct_v1(
  p_request_id uuid,
  p_admin_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private, pg_temp
AS $$
DECLARE
  v_role text;
  v_request record;
  v_member record;
  v_review record;
  v_reservation record;
  v_new_cpf_normalized text;
  v_old_cpf_normalized text;
  v_member_cpf_normalized text;
  v_cpf_in_use boolean;
  v_parent_cpf text;
  v_parent_cpf_normalized text;
  v_now timestamptz;
BEGIN
  -- A. Validar nulos
  IF p_request_id IS NULL OR p_admin_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_parameters',
      'message', 'Parâmetros de entrada inválidos.'
    );
  END IF;

  v_now := transaction_timestamp();

  -- B. Validar role de admin (Master ou Dev)
  SELECT role INTO v_role
  FROM public.profiles
  WHERE id = p_admin_user_id;

  IF v_role IS NULL OR v_role NOT IN ('admin_master', 'admin_dev') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'forbidden',
      'message', 'Acesso negado: privilégios insuficientes.'
    );
  END IF;

  -- C. Buscar e bloquear a solicitação (FOR UPDATE)
  SELECT id, user_id, member_id, status
  INTO v_request
  FROM public.dependent_cpf_change_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'not_found',
      'message', 'Solicitação administrativa não encontrada.'
    );
  END IF;

  -- Validar status: só pode finalizar se estiver em 'applying'
  IF v_request.status <> 'applying' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status',
      'message', 'Esta solicitação não está no estágio de aplicação.'
    );
  END IF;

  -- D. Buscar e bloquear o dependente correspondente (FOR UPDATE)
  SELECT id, status, user_id, cpf
  INTO v_member
  FROM public.members
  WHERE id = v_request.member_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'member_not_found',
      'message', 'Beneficiário dependente não cadastrado ou removido.'
    );
  END IF;

  -- Validar se o dependente pertence ao titular correto da solicitação
  IF v_member.user_id <> v_request.user_id THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'forbidden',
      'message', 'O dependente não pertence ao titular desta solicitação.'
    );
  END IF;

  -- Validar se o dependente está em status operacional válido
  IF v_member.status NOT IN ('active', 'approved') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request',
      'message', 'O cadastro do dependente não está ativo.'
    );
  END IF;

  -- E. Buscar e bloquear os dados sensíveis da revisão (FOR UPDATE)
  SELECT old_cpf_clear, new_cpf_clear
  INTO v_review
  FROM private.dependent_cpf_change_review_data
  WHERE request_id = p_request_id
  FOR UPDATE;

  IF NOT FOUND OR v_review.new_cpf_clear IS NULL OR v_review.old_cpf_clear IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'missing_review_data',
      'message', 'Dados confidenciais de revisão indisponíveis.'
    );
  END IF;

  -- F. Normalizar e validar o novo CPF solicitado
  v_new_cpf_normalized := regexp_replace(v_review.new_cpf_clear, '[^0-9]', '', 'g');
  IF length(v_new_cpf_normalized) <> 11 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_cpf',
      'message', 'O formato do CPF solicitado é inválido.'
    );
  END IF;

  -- F2. Validar se old_cpf_clear confere com o CPF atual do member (blindagem de concorrência)
  v_old_cpf_normalized := regexp_replace(v_review.old_cpf_clear, '[^0-9]', '', 'g');
  v_member_cpf_normalized := COALESCE(regexp_replace(v_member.cpf, '[^0-9]', '', 'g'), '');

  IF v_member_cpf_normalized <> v_old_cpf_normalized THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'member_cpf_changed',
      'message', 'O CPF atual do dependente mudou desde a abertura da solicitação.'
    );
  END IF;

  -- G. Checar conflitos de duplicidade do CPF solicitado
  -- 1. Em outros dependentes (members)
  SELECT EXISTS (
    SELECT 1 
    FROM public.members 
    WHERE id <> v_request.member_id
      AND cpf IS NOT NULL 
      AND regexp_replace(cpf, '[^0-9]', '', 'g') = v_new_cpf_normalized
  ) INTO v_cpf_in_use;

  IF v_cpf_in_use THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'cpf_in_use',
      'message', 'O CPF solicitado já está cadastrado em outro dependente.'
    );
  END IF;

  -- 2. Validar conflito restrito com o CPF do titular daquela conta (pai do dependente)
  SELECT cpf INTO v_parent_cpf
  FROM public.profiles
  WHERE id = v_request.user_id;

  v_parent_cpf_normalized := COALESCE(regexp_replace(v_parent_cpf, '[^0-9]', '', 'g'), '');

  IF v_new_cpf_normalized = v_parent_cpf_normalized OR v_old_cpf_normalized = v_parent_cpf_normalized THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'account_cpf_conflict',
      'message', 'O CPF do dependente não pode ser igual ao CPF do titular da conta.'
    );
  END IF;

  -- H. Buscar e bloquear a reserva por HMAC
  SELECT id, reservation_state
  INTO v_reservation
  FROM private.dependent_cpf_change_reservations
  WHERE request_id = p_request_id
  FOR UPDATE;

  IF NOT FOUND OR v_reservation.reservation_state <> 'attached' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'reservation_unavailable',
      'message', 'Reserva exclusiva de CPF inativa ou corrompida.'
    );
  END IF;

  -- =========================================================================
  -- APLICAR ALTERAÇÕES (COMMIT EFETIVO NO BANCO)
  -- =========================================================================

  -- 1. Atualizar o cadastro do dependente em public.members
  UPDATE public.members
  SET cpf = v_new_cpf_normalized,
      updated_at = v_now
  WHERE id = v_request.member_id;

  -- 2. Expurgar dados sensíveis de auditoria limpos (Review Data)
  UPDATE private.dependent_cpf_change_review_data
  SET old_cpf_clear = NULL,
      new_cpf_clear = NULL,
      document_file_id = NULL,
      document_state = 'discarded',
      cleared_at = v_now,
      clear_reason = 'approval_completed',
      updated_at = v_now
  WHERE request_id = p_request_id;

  -- 3. Excluir secure payloads sensíveis associados
  DELETE FROM private.dependent_cpf_change_secure_payloads
  WHERE request_id = p_request_id;

  -- 4. Liberar a reserva de CPF ativa
  UPDATE private.dependent_cpf_change_reservations
  SET reservation_state = 'released',
      released_at = v_now,
      updated_at = v_now
  WHERE request_id = p_request_id;

  -- 5. Concluir a solicitação pública
  UPDATE public.dependent_cpf_change_requests
  SET status = 'completed',
      completed_at = v_now,
      updated_at = v_now
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'status', 'completed'
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error_code', 'internal_error',
    'message', 'Erro operacional interno ao consolidar a aprovação.'
  );
END;
$$;

-- Restrição de privilégios de execução
REVOKE ALL ON FUNCTION public.conectea_admin_commit_dependent_cpf_change_direct_v1(uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_commit_dependent_cpf_change_direct_v1(uuid, uuid) TO service_role;
