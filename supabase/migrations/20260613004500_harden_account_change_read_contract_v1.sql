-- =========================================================================
-- ConeCTEA — Fundação do Contrato Seguro de Leitura para Alterações de Conta
-- 
-- MIGRATION: 20260613004500_harden_account_change_read_contract_v1.sql
-- OBJETIVO:
--   1. Revogar o privilégio SELECT direto da role authenticated sobre 
--      public.account_change_requests.
--   2. Criar a RPC public.conectea_list_my_account_changes_v1() para listagem 
--      segura e paginada de protocolos do próprio usuário.
--   3. Criar a RPC public.conectea_get_my_account_change_v1() para consulta 
--      detalhada de um protocolo específico do próprio titular.
--
-- STATUS: Criação local da migration para auditoria. Não aplicada remotamente.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. RPC 1 — LISTAGEM SEGURA DE PROTOCOLOS DO TITULAR (PAGINADA)
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_list_my_account_changes_v1(
  p_limit integer DEFAULT 10,
  p_offset integer DEFAULT 0
)
RETURNS TABLE (
  id uuid,
  protocol_number text,
  type public.account_change_type,
  status public.account_change_status,
  old_value_masked text,
  new_value_masked text,
  created_at timestamp with time zone,
  updated_at timestamp with time zone,
  application_completed_at timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_limit integer;
  v_offset integer;
BEGIN
  -- 1. Exigir auth.uid() não nulo
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Acesso negado: usuário não autenticado.'
      USING ERRCODE = '42501';
  END IF;

  -- 2. Limitar p_limit server-side entre 1 e 20
  IF p_limit IS NULL OR p_limit < 1 THEN
    v_limit := 10;
  ELSIF p_limit > 20 THEN
    v_limit := 20;
  ELSE
    v_limit := p_limit;
  END IF;

  -- 3. Impedir offset negativo
  IF p_offset IS NULL OR p_offset < 0 THEN
    v_offset := 0;
  ELSE
    v_offset := p_offset;
  END IF;

  -- 4. Filtrar obrigatoriamente por user_id = auth.uid() e retornar
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
    cr.application_completed_at
  FROM public.account_change_requests cr
  WHERE cr.user_id = auth.uid()
  ORDER BY cr.created_at DESC, cr.id DESC
  LIMIT v_limit
  OFFSET v_offset;
END;
$$;

COMMENT ON FUNCTION public.conectea_list_my_account_changes_v1(integer, integer) 
  IS 'Lista de forma segura e paginada os protocolos de alteração de conta do titular logado.';

-- ─────────────────────────────────────────────────────────────────────────
-- 2. RPC 2 — CONSULTA DE DETALHE DE PROTOCOLO DO TITULAR
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_get_my_account_change_v1(
  p_request_id uuid
)
RETURNS TABLE (
  id uuid,
  protocol_number text,
  type public.account_change_type,
  status public.account_change_status,
  old_value_masked text,
  new_value_masked text,
  justification text,
  holder_confirmed_at timestamp with time zone,
  application_started_at timestamp with time zone,
  application_completed_at timestamp with time zone,
  created_at timestamp with time zone,
  updated_at timestamp with time zone
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

  -- 2. Validar parâmetro de entrada
  IF p_request_id IS NULL THEN
    RETURN;
  END IF;

  -- 3. Filtrar simultaneamente por ID da requisição e por user_id do titular
  RETURN QUERY
  SELECT 
    cr.id,
    cr.protocol_number,
    cr.type,
    cr.status,
    cr.old_value_masked,
    cr.new_value_masked,
    cr.justification,
    cr.holder_confirmed_at,
    cr.application_started_at,
    cr.application_completed_at,
    cr.created_at,
    cr.updated_at
  FROM public.account_change_requests cr
  WHERE cr.id = p_request_id
    AND cr.user_id = auth.uid();
END;
$$;

COMMENT ON FUNCTION public.conectea_get_my_account_change_v1(uuid) 
  IS 'Obtém detalhes de um protocolo de alteração de conta do titular logado, retornando zero linhas se pertencer a terceiros.';

-- ─────────────────────────────────────────────────────────────────────────
-- 3. RECONFIGURAÇÃO DE PRIVILÉGIOS (MODELO DE MÍNIMOS PRIVILÉGIOS)
-- ─────────────────────────────────────────────────────────────────────────

-- A. Revogar acesso SELECT direto à tabela para authenticated (PostgREST)
REVOKE SELECT ON TABLE public.account_change_requests FROM authenticated;

-- B. Restringir execução das RPCs aos usuários logados (authenticated)
REVOKE ALL ON FUNCTION public.conectea_list_my_account_changes_v1(integer, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_list_my_account_changes_v1(integer, integer) TO authenticated;

REVOKE ALL ON FUNCTION public.conectea_get_my_account_change_v1(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_get_my_account_change_v1(uuid) TO authenticated;
