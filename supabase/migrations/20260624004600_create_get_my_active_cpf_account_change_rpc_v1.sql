-- =========================================================================
-- ConeCTEA — Obter Solicitação de Alteração de CPF Ativa
--
-- MIGRATION: 20260624004600_create_get_my_active_cpf_account_change_rpc_v1.sql
-- OBJETIVO:
--   1. Criar RPC public.conectea_get_my_active_cpf_account_change_v1() para buscar
--      a solicitação de CPF ativa do titular logado.
--   2. Garantir segurança estrita com SECURITY DEFINER e Grants adequados.
-- =========================================================================

CREATE OR REPLACE FUNCTION public.conectea_get_my_active_cpf_account_change_v1()
RETURNS TABLE (
  id uuid,
  protocol_number text,
  type public.account_change_type,
  status public.account_change_status,
  old_value_masked text,
  new_value_masked text,
  created_at timestamp with time zone,
  updated_at timestamp with time zone,
  application_completed_at timestamp with time zone,
  status_changed_at timestamp with time zone,
  holder_deadline_due_date date,
  closed_at timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- 1. Exigir auth.uid() não nulo
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Acesso negado: usuário não autenticado.'
      USING ERRCODE = '42501';
  END IF;

  -- 2. Filtrar pela solicitação ativa de CPF do titular
  RETURN QUERY
  SELECT
    cr.id,
    cr.protocol_number,
    cr.type,
    cr.status,
    cr.old_value_masked,
    cr.new_value_masked,
    cr.created_at,
    cr.updated_at,
    cr.application_completed_at,
    cr.status_changed_at,
    CASE 
      WHEN cr.holder_deadline_exclusive_at IS NULL THEN NULL
      ELSE (cr.holder_deadline_exclusive_at AT TIME ZONE 'America/Sao_Paulo')::date - 1
    END AS holder_deadline_due_date,
    cr.closed_at
  FROM public.account_change_requests cr
  WHERE cr.user_id = auth.uid()
    AND cr.type = 'cpf'::public.account_change_type
    AND cr.status IN (
      'under_review'::public.account_change_status,
      'waiting_document_replacement'::public.account_change_status,
      'waiting_cpf_correction'::public.account_change_status,
      'waiting_holder_confirmation'::public.account_change_status,
      'applying'::public.account_change_status,
      'application_failed'::public.account_change_status
    )
  ORDER BY cr.created_at DESC, cr.id DESC
  LIMIT 1;
END;
$$;

COMMENT ON FUNCTION public.conectea_get_my_active_cpf_account_change_v1()
  IS 'Obtém a solicitação de revisão de CPF ativa do titular autenticado, se houver.';

-- 3. Configurar Grants (segurança)
REVOKE ALL ON FUNCTION public.conectea_get_my_active_cpf_account_change_v1() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_get_my_active_cpf_account_change_v1() TO authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_get_my_active_cpf_account_change_v1() TO service_role;
