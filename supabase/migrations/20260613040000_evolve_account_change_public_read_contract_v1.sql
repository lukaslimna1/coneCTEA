-- =========================================================================
-- ConeCTEA — Evolução do Contrato Público Seguro de Leitura para Alterações de Conta
--
-- MIGRATION: 20260613040000_evolve_account_change_public_read_contract_v1.sql
-- OBJETIVO:
--   1. Pré-condição fail-fast antes de qualquer DDL para interromper se existirem
--      solicitações legadas em waiting_document_replacement ou rejected_by_admin.
--   2. Adicionar o campo public_admin_feedback text NULL.
--   3. Criar constraint de formato chk_conectea_public_admin_feedback_format
--      (máximo 500 caracteres, não vazio após trim).
--   4. Endurecer a constraint chk_conectea_change_admin_decision exigindo
--      public_admin_feedback.
--   5. Recriar a RPC public.conectea_list_my_account_changes_v1() para retornar
--      novos campos públicos (status_changed_at, holder_deadline_due_date, closed_at).
--   6. Recriar a RPC public.conectea_get_my_account_change_v1() para retornar
--      novos campos públicos (status_changed_at, holder_deadline_started_at,
--      holder_deadline_due_date, resolution_reason, public_admin_reason_code,
--      public_admin_feedback normalizado, closed_at).
--   7. Reconfigurar os privilégios garantindo execute somente para authenticated.
--
-- STATUS: Criação local da migration para auditoria. Não aplicada remotamente.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. PRÉ-CONDIÇÃO FAIL-FAST (ANTES DE QUALQUER DDL)
-- ─────────────────────────────────────────────────────────────────────────

-- Verificar se existem registros legados que impedem a evolução do contrato
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 
    FROM public.account_change_requests
    WHERE status IN ('waiting_document_replacement'::public.account_change_status, 'rejected_by_admin'::public.account_change_status)
  ) THEN
    RAISE EXCEPTION 'A migracao nao pode ser executada: Existem decisoes administrativas que exigem preparacao antes da evolucao do contrato publico.'
      USING ERRCODE = '23502';
  END IF;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. ADIÇÃO DE CAMPOS OPERACIONAIS E PÚBLICOS
-- ─────────────────────────────────────────────────────────────────────────

ALTER TABLE public.account_change_requests
  ADD COLUMN public_admin_feedback text NULL;

COMMENT ON COLUMN public.account_change_requests.public_admin_feedback IS 'Feedback administrativo destinado de forma clara e publica ao titular.';

-- ─────────────────────────────────────────────────────────────────────────
-- 3. CONSTRAINT DE INTEGRIDADE DO TEXTO PÚBLICO (FORMATO E COMPRIMENTO)
-- ─────────────────────────────────────────────────────────────────────────

ALTER TABLE public.account_change_requests
  ADD CONSTRAINT chk_conectea_public_admin_feedback_format CHECK (
    public_admin_feedback IS NULL OR (
      TRIM(BOTH FROM public_admin_feedback) <> '' AND
      length(TRIM(BOTH FROM public_admin_feedback)) <= 500
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- 4. ENDURECIMENTO DA CONSTRAINT ADMINISTRATIVA
-- ─────────────────────────────────────────────────────────────────────────

-- Remover antiga constraint administrativa
ALTER TABLE public.account_change_requests
  DROP CONSTRAINT IF EXISTS chk_conectea_change_admin_decision;

-- Adicionar nova constraint exigindo campos obrigatórios de decisão administrativa, incluindo o feedback público válido
ALTER TABLE public.account_change_requests
  ADD CONSTRAINT chk_conectea_change_admin_decision CHECK (
    (status NOT IN ('waiting_document_replacement'::public.account_change_status, 'rejected_by_admin'::public.account_change_status)) OR
    (
      type = 'cpf'::public.account_change_type AND
      admin_id IS NOT NULL AND
      admin_reason IS NOT NULL AND
      admin_feedback IS NOT NULL AND
      TRIM(BOTH FROM admin_feedback) <> '' AND
      public_admin_feedback IS NOT NULL
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- 5. RECOMPOSIÇÃO DAS RPCs SEGURAS DE LEITURA
-- ─────────────────────────────────────────────────────────────────────────

-- Dropar funções antigas para redefinição do tipo de retorno
DROP FUNCTION IF EXISTS public.conectea_list_my_account_changes_v1(integer, integer);
DROP FUNCTION IF EXISTS public.conectea_get_my_account_change_v1(uuid);

-- RPC 1 — LISTAGEM SEGURA DE PROTOCOLOS DO TITULAR (PAGINADA)
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
  application_completed_at timestamp with time zone,
  status_changed_at timestamp with time zone,
  holder_deadline_due_date date,
  closed_at timestamp with time zone
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

  -- 4. Filtrar por user_id = auth.uid() e retornar com campos públicos extras
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
  ORDER BY cr.created_at DESC, cr.id DESC
  LIMIT v_limit
  OFFSET v_offset;
END;
$$;

COMMENT ON FUNCTION public.conectea_list_my_account_changes_v1(integer, integer)
  IS 'Lista os protocolos do titular logado, enriquecida com prazos de vencimento e datas de mudanca/fechamento.';

-- RPC 2 — CONSULTA DE DETALHE DE PROTOCOLO DO TITULAR
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
  updated_at timestamp with time zone,
  status_changed_at timestamp with time zone,
  holder_deadline_started_at timestamp with time zone,
  holder_deadline_due_date date,
  resolution_reason public.account_change_resolution_reason,
  public_admin_reason_code text,
  public_admin_feedback text,
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

  -- 2. Validar parâmetro de entrada
  IF p_request_id IS NULL THEN
    RETURN;
  END IF;

  -- 3. Filtrar simultaneamente por ID e user_id do titular logado
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
    cr.updated_at,
    cr.status_changed_at,
    cr.holder_deadline_started_at,
    CASE 
      WHEN cr.holder_deadline_exclusive_at IS NULL THEN NULL
      ELSE (cr.holder_deadline_exclusive_at AT TIME ZONE 'America/Sao_Paulo')::date - 1
    END AS holder_deadline_due_date,
    cr.resolution_reason,
    CASE cr.admin_reason
      WHEN 'wrong_document'::public.account_change_admin_reason THEN 'document_not_accepted'
      WHEN 'unreadable_document'::public.account_change_admin_reason THEN 'unreadable_document'
      WHEN 'cpf_not_visible'::public.account_change_admin_reason THEN 'cpf_not_visible'
      WHEN 'name_mismatch'::public.account_change_admin_reason THEN 'name_mismatch'
      WHEN 'birth_date_mismatch'::public.account_change_admin_reason THEN 'birth_date_mismatch'
      WHEN 'cpf_mismatch'::public.account_change_admin_reason THEN 'cpf_mismatch'
      WHEN 'other'::public.account_change_admin_reason THEN 'other'
      ELSE NULL
    END AS public_admin_reason_code,
    btrim(cr.public_admin_feedback) AS public_admin_feedback,
    cr.closed_at
  FROM public.account_change_requests cr
  WHERE cr.id = p_request_id
    AND cr.user_id = auth.uid();
END;
$$;

COMMENT ON FUNCTION public.conectea_get_my_account_change_v1(uuid)
  IS 'Obtem detalhes do protocolo do titular com motivos publicos explicados, prazos e datas de fechamento.';

-- ─────────────────────────────────────────────────────────────────────────
-- 6. RECONFIGURAÇÃO DE PRIVILÉGIOS (MODELO DE MÍNIMOS PRIVILÉGIOS)
-- ─────────────────────────────────────────────────────────────────────────

-- A. Revogar acesso SELECT direto à tabela para authenticated (PostgREST)
REVOKE SELECT ON TABLE public.account_change_requests FROM authenticated;

-- B. Restringir execução das RPCs aos usuários logados (authenticated)
REVOKE ALL ON FUNCTION public.conectea_list_my_account_changes_v1(integer, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_list_my_account_changes_v1(integer, integer) TO authenticated;

REVOKE ALL ON FUNCTION public.conectea_get_my_account_change_v1(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_get_my_account_change_v1(uuid) TO authenticated;
