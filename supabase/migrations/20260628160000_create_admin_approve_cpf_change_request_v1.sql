-- =========================================================================
-- ConeCTEA — RPC Administrativa para Aprovação de CPF para Confirmação Final
-- 
-- MIGRATION: 20260628160000_create_admin_approve_cpf_change_request_v1.sql
-- OBJETIVO: Criar RPC segura para admin aprovar a solicitação de CPF.
-- =========================================================================

CREATE OR REPLACE FUNCTION public.conectea_admin_approve_cpf_change_request_v1(
  p_request_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid uuid;
  v_role text;
  v_request record;
  v_holder_deadline_exclusive_at timestamptz;
  v_now timestamptz;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'unauthorized'
    );
  END IF;

  -- 1. Validar admin_master/admin_dev
  SELECT role INTO v_role
  FROM public.profiles
  WHERE id = v_uid;

  IF v_role NOT IN ('admin_master', 'admin_dev') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'forbidden'
    );
  END IF;

  IF p_request_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  -- 2. Buscar a solicitação (apenas campos operacionais não sensíveis)
  SELECT id, type, status 
  INTO v_request
  FROM public.account_change_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND OR v_request.type <> 'cpf'::public.account_change_type THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'not_found'
    );
  END IF;

  IF v_request.status <> 'under_review'::public.account_change_status THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_status'
    );
  END IF;

  -- Fixar now()
  v_now := now();

  -- 3. Calcular prazo de 10 dias úteis para o titular responder
  -- conectea_account_change_holder_deadline_v1 usa a data do servidor e fuso de SP
  v_holder_deadline_exclusive_at := public.conectea_account_change_holder_deadline_v1(v_now);

  -- 4. Atualizar o protocolo
  UPDATE public.account_change_requests
  SET 
    status = 'waiting_holder_confirmation'::public.account_change_status,
    admin_id = v_uid,
    holder_deadline_started_at = v_now,
    holder_deadline_exclusive_at = v_holder_deadline_exclusive_at,
    status_changed_at = v_now,
    updated_at = v_now,
    resolution_reason = NULL -- garante que reseta caso venha preenchido (constraints)
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'status', 'waiting_holder_confirmation',
    'holder_deadline_started_at', v_now,
    'holder_deadline_exclusive_at', v_holder_deadline_exclusive_at
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error_code', 'internal_error'
  );
END;
$$;

COMMENT ON FUNCTION public.conectea_admin_approve_cpf_change_request_v1(uuid)
  IS 'RPC segura para administradores (master/dev) aprovarem a troca de CPF, enviando-a para a etapa de confirmação do titular com prazo de 10 dias úteis.';

-- Mínimo privilégio
REVOKE ALL ON FUNCTION public.conectea_admin_approve_cpf_change_request_v1(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_admin_approve_cpf_change_request_v1(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_approve_cpf_change_request_v1(uuid) TO service_role;
