-- =========================================================================
-- ConeCTEA — RPC Administrativa para Aprovação de CPF de Dependente
--
-- MIGRATION: 20260703113500_create_admin_approve_dependent_cpf_change_request_v1.sql
-- OBJETIVO:
--   - Alterar a constraint chk_gc_drive_source_table na tabela de descarte
--     para suportar solicitações de CPF de dependentes.
--   - Criar a RPC segura public.conectea_admin_approve_dependent_cpf_change_request_v1
--     que realiza a aprovação, atualiza public.members, enfileira o descarte 
--     do documento no Drive, limpa a tabela de review e zera o secure payload 
--     de forma atômica e transacional.
-- =========================================================================

-- 1. ATUALIZAÇÃO DA CONSTRAINT DE ORIGEM NA FILA DE DESCARTE DO DRIVE
ALTER TABLE private.gc_drive_files_to_delete
  DROP CONSTRAINT IF EXISTS chk_gc_drive_source_table;

ALTER TABLE private.gc_drive_files_to_delete
  ADD CONSTRAINT chk_gc_drive_source_table CHECK (
    source_table IN ('account_change_requests', 'dependent_cpf_change_requests')
  );

-- 2. CRIAÇÃO DA RPC DE APROVAÇÃO
CREATE OR REPLACE FUNCTION public.conectea_admin_approve_dependent_cpf_change_request_v1(
  p_request_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private, pg_temp
AS $$
DECLARE
  v_uid uuid;
  v_role text;
  v_request record;
  v_member record;
  v_review record;
  v_reservation record;
  v_new_cpf_normalized text;
  v_old_cpf_normalized text;
  v_member_cpf_normalized text;
  v_cpf_in_use boolean;
  v_account_cpf_conflict boolean;
  v_now timestamptz;
BEGIN
  -- A. Validar usuário autenticado
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'unauthorized',
      'message', 'Usuário não autenticado.'
    );
  END IF;

  -- B. Validar role de admin (Master ou Dev)
  SELECT role INTO v_role
  FROM public.profiles
  WHERE id = v_uid;

  IF v_role IS NULL OR v_role NOT IN ('admin_master', 'admin_dev') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'forbidden',
      'message', 'Acesso negado: privilégios insuficientes.'
    );
  END IF;

  -- C. Validar parâmetros
  IF p_request_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_parameters',
      'message', 'ID da solicitação inválido.'
    );
  END IF;

  v_now := transaction_timestamp();

  -- D. Buscar e bloquear a solicitação (FOR UPDATE)
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

  -- E. Buscar e bloquear o dependente correspondente (FOR UPDATE)
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

  -- F. Buscar e bloquear os dados sensíveis da revisão (FOR UPDATE)
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

  -- G. Normalizar e validar o novo CPF solicitado
  v_new_cpf_normalized := regexp_replace(v_review.new_cpf_clear, '[^0-9]', '', 'g');
  IF length(v_new_cpf_normalized) <> 11 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_cpf',
      'message', 'O formato do CPF solicitado é inválido.'
    );
  END IF;

  -- G2. Validar se old_cpf_clear confere com o CPF atual do member (blindagem de concorrência)
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

  -- H. Checar conflitos de duplicidade do CPF solicitado
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

  -- 2. Validar conflito com qualquer CPF de conta em public.profiles (Global)
  SELECT EXISTS (
    SELECT 1 
    FROM public.profiles
    WHERE cpf IS NOT NULL 
      AND regexp_replace(cpf, '[^0-9]', '', 'g') = v_new_cpf_normalized
  ) INTO v_account_cpf_conflict;

  IF v_account_cpf_conflict THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'account_cpf_conflict',
      'message', 'O CPF do dependente não pode ser igual ao CPF de uma conta.'
    );
  END IF;

  -- I. Buscar e bloquear a reserva por HMAC
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
  -- APLICAÇÃO EFETIVA DAS MUDANÇAS (TRANSAÇÃO GARANTIDA POR POSTGRESQL)
  -- =========================================================================

  -- 1. Atualizar o cadastro do dependente em public.members
  UPDATE public.members
  SET cpf = v_new_cpf_normalized,
      updated_at = v_now
  WHERE id = v_request.member_id;

  -- 2. Sincronização de public.digital_cards [REMOVIDA DESTA RPC]
  -- A sincronização do novo CPF com a tabela public.digital_cards foi removida desta RPC
  -- de forma preventiva, devido à ausência de informações de schema definitivas sobre
  -- carteirinhas históricas, inativas ou múltiplas. Esta sincronização será implementada
  -- em uma microfrente futura dedicada após auditoria completa do schema de carteirinhas.

  -- 3. Enfileirar descarte físico do documento no Drive
  INSERT INTO private.gc_drive_files_to_delete (
    file_id,
    source_table,
    source_id,
    reason,
    status,
    created_at,
    updated_at
  ) VALUES (
    v_review.document_file_id,
    'dependent_cpf_change_requests',
    p_request_id,
    'request_approved',
    'pending',
    v_now,
    v_now
  );

  -- 4. Expurgar dados sensíveis de auditoria limpos (Review Data)
  UPDATE private.dependent_cpf_change_review_data
  SET old_cpf_clear = NULL,
      new_cpf_clear = NULL,
      document_file_id = NULL,
      document_state = 'discarded',
      cleared_at = v_now,
      clear_reason = 'approval_completed',
      updated_at = v_now
  WHERE request_id = p_request_id;

  -- 5. Excluir secure payloads sensíveis associados
  DELETE FROM private.dependent_cpf_change_secure_payloads
  WHERE request_id = p_request_id;

  -- 6. Liberar a reserva de CPF ativa
  UPDATE private.dependent_cpf_change_reservations
  SET reservation_state = 'released',
      released_at = v_now,
      updated_at = v_now
  WHERE request_id = p_request_id;

  -- 7. Concluir a solicitação pública
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
  -- Em caso de erro inesperado, reverte tudo automaticamente e retorna erro genérico
  RETURN jsonb_build_object(
    'success', false,
    'error_code', 'internal_error',
    'message', 'Erro operacional interno ao aplicar a alteração.'
  );
END;
$$;

-- Restrição de execução
REVOKE ALL ON FUNCTION public.conectea_admin_approve_dependent_cpf_change_request_v1(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_admin_approve_dependent_cpf_change_request_v1(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_approve_dependent_cpf_change_request_v1(uuid) TO service_role;

COMMENT ON FUNCTION public.conectea_admin_approve_dependent_cpf_change_request_v1(uuid)
  IS 'RPC administrativa segura que aprova transacionalmente a alteração de CPF de dependente, atualizando public.members, enfileirando o expurgo do documento, liberando a reserva e limpando dados sensíveis.';
