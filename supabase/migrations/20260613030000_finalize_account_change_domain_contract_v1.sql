-- =========================================================================
-- ConeCTEA — Consolidação do Contrato Final do Domínio de Alterações de Conta
--
-- MIGRATION: 20260613030000_finalize_account_change_domain_contract_v1.sql
-- OBJETIVO:
--   1. Interromper aplicação se a tabela pública possuir qualquer registro (fail-fast).
--   2. Remover status obsoleto waiting_proof e recriar public.account_change_status com status finais.
--   3. Criar os novos enums de motivos: public.account_change_resolution_reason e public.account_change_admin_reason.
--   4. Adicionar campos de prazo, encerramento e motivos à tabela public.account_change_requests.
--   5. Criar constraints robustas de integridade para tipo/status, prazos, encerramento e decisões.
--   6. Recriar as RPCs seguras de listagem e detalhe de protocolos sem quebra do contrato de leitura atual.
--
-- STATUS: Criação local da migration para auditoria. Não aplicada remotamente.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. PRÉ-CONDIÇÃO FAIL-FAST
-- ─────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.account_change_requests) THEN
    RAISE EXCEPTION 'A migration nao pode ser executada: a tabela public.account_change_requests ja possui registros.'
      USING ERRCODE = '23505';
  END IF;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. DESACOPLAR ASSINATURAS DO ENUM ANTIGO (DROP TEMP)
-- ─────────────────────────────────────────────────────────────────────────

-- Remover as RPCs que retornam ou dependem do tipo enum atual
DROP FUNCTION IF EXISTS public.conectea_list_my_account_changes_v1(integer, integer);
DROP FUNCTION IF EXISTS public.conectea_get_my_account_change_v1(uuid);

-- Remover índices que dependem do enum antigo ou da coluna status
DROP INDEX IF EXISTS public.account_change_requests_active_idx;
DROP INDEX IF EXISTS public.account_change_requests_status_idx;

-- Alterar temporariamente a coluna status para text para desvincular do enum antigo
ALTER TABLE public.account_change_requests ALTER COLUMN status TYPE text;

-- Dropar o enum antigo contendo o status obsoleto waiting_proof
DROP TYPE public.account_change_status;

-- ─────────────────────────────────────────────────────────────────────────
-- 3. CRIAÇÃO DOS ENUMS FINAIS DO DOMÍNIO
-- ─────────────────────────────────────────────────────────────────────────

-- Novo enum de status sem waiting_proof e com expired
CREATE TYPE public.account_change_status AS ENUM (
  'under_review',
  'waiting_document_replacement',
  'waiting_holder_confirmation',
  'applying',
  'application_failed',
  'completed',
  'rejected_by_admin',
  'cancelled_by_holder',
  'expired'
);

COMMENT ON TYPE public.account_change_status IS 'Status operacionais do ciclo de vida de alterações de e-mail e CPF.';

-- Novo enum de motivos de encerramento/resolução do protocolo
CREATE TYPE public.account_change_resolution_reason AS ENUM (
  'cancelled_during_review',
  'cancelled_while_waiting_document',
  'declined_final_confirmation',
  'document_replacement_deadline',
  'holder_confirmation_deadline'
);

COMMENT ON TYPE public.account_change_resolution_reason IS 'Motivos de encerramento do protocolo por cancelamento ou expiracao de prazo.';

-- Novo enum de motivos administrativos de rejeição ou substituição documental
CREATE TYPE public.account_change_admin_reason AS ENUM (
  'wrong_document',
  'unreadable_document',
  'cpf_not_visible',
  'name_mismatch',
  'birth_date_mismatch',
  'cpf_mismatch',
  'other'
);

COMMENT ON TYPE public.account_change_admin_reason IS 'Motivos administrativos de recusa documental ou rejeicao do protocolo.';

-- ─────────────────────────────────────────────────────────────────────────
-- 4. ATUALIZAR COLUNA DE STATUS E RECONSTRUIR ÍNDICES
-- ─────────────────────────────────────────────────────────────────────────

-- Converter a coluna de status para o novo tipo enum
ALTER TABLE public.account_change_requests
  ALTER COLUMN status TYPE public.account_change_status USING status::public.account_change_status;

-- Recriar o índice padrão de status
CREATE INDEX account_change_requests_status_idx ON public.account_change_requests (status);

-- Recriar o índice único parcial de protocolos ativos por usuário/tipo (allowlist de status ativos)
CREATE UNIQUE INDEX account_change_requests_active_idx
ON public.account_change_requests (user_id, type)
WHERE status IN (
  'under_review',
  'waiting_document_replacement',
  'waiting_holder_confirmation',
  'applying',
  'application_failed'
);

-- ─────────────────────────────────────────────────────────────────────────
-- 5. CRIAÇÃO DE NOVOS CAMPOS OPERACIONAIS
-- ─────────────────────────────────────────────────────────────────────────

ALTER TABLE public.account_change_requests
  ADD COLUMN status_changed_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN admin_deadline_started_at timestamptz NULL,
  ADD COLUMN admin_deadline_exclusive_at timestamptz NULL,
  ADD COLUMN holder_deadline_started_at timestamptz NULL,
  ADD COLUMN holder_deadline_exclusive_at timestamptz NULL,
  ADD COLUMN resolution_reason public.account_change_resolution_reason NULL,
  ADD COLUMN admin_reason public.account_change_admin_reason NULL,
  ADD COLUMN closed_at timestamptz NULL;

-- ─────────────────────────────────────────────────────────────────────────
-- 6. CONSTRAINTS DE INTEGRIDADE DO DOMÍNIO
-- ─────────────────────────────────────────────────────────────────────────

-- A. Combinações permitidas entre Tipo e Status
ALTER TABLE public.account_change_requests
  ADD CONSTRAINT chk_conectea_change_type_status CHECK (
    (type = 'email' AND status IN (
      'waiting_holder_confirmation',
      'applying',
      'application_failed',
      'completed',
      'cancelled_by_holder',
      'expired'
    )) OR
    (type = 'cpf' AND status IN (
      'under_review',
      'waiting_document_replacement',
      'waiting_holder_confirmation',
      'applying',
      'application_failed',
      'completed',
      'rejected_by_admin',
      'cancelled_by_holder',
      'expired'
    ))
  );

-- B. Regras de Prazos (Início/Fim e relação com Status)
ALTER TABLE public.account_change_requests
  ADD CONSTRAINT chk_conectea_change_deadlines CHECK (
    -- Garante consistência lógica temporal dos limites exclusivos quando preenchidos
    (admin_deadline_exclusive_at IS NULL OR admin_deadline_exclusive_at > admin_deadline_started_at) AND
    (holder_deadline_exclusive_at IS NULL OR holder_deadline_exclusive_at > holder_deadline_started_at) AND

    -- Garante preenchimento completo (paridade) dos campos de prazos
    ((admin_deadline_started_at IS NULL AND admin_deadline_exclusive_at IS NULL) OR (admin_deadline_started_at IS NOT NULL AND admin_deadline_exclusive_at IS NOT NULL)) AND
    ((holder_deadline_started_at IS NULL AND holder_deadline_exclusive_at IS NULL) OR (holder_deadline_started_at IS NOT NULL AND holder_deadline_exclusive_at IS NOT NULL)) AND

    -- Restrições de prazos mapeadas por status operacional
    CASE
      WHEN status = 'under_review' THEN
        type = 'cpf' AND
        admin_deadline_started_at IS NOT NULL AND
        holder_deadline_started_at IS NULL

      WHEN status = 'waiting_document_replacement' THEN
        type = 'cpf' AND
        holder_deadline_started_at IS NOT NULL AND
        admin_deadline_started_at IS NULL

      WHEN status = 'waiting_holder_confirmation' THEN
        holder_deadline_started_at IS NOT NULL AND
        admin_deadline_started_at IS NULL

      ELSE -- applying, application_failed, completed, rejected_by_admin, cancelled_by_holder, expired
        admin_deadline_started_at IS NULL AND
        holder_deadline_started_at IS NULL
    END
  );

-- C. Regras de Encerramento (closed_at)
ALTER TABLE public.account_change_requests
  ADD CONSTRAINT chk_conectea_change_closure CHECK (
    (status IN ('completed', 'rejected_by_admin', 'cancelled_by_holder', 'expired') AND closed_at IS NOT NULL) OR
    (status IN ('under_review', 'waiting_document_replacement', 'waiting_holder_confirmation', 'applying', 'application_failed') AND closed_at IS NULL)
  );

-- D. Regras de Resolução (resolution_reason em cancelamentos e expirações)
ALTER TABLE public.account_change_requests
  ADD CONSTRAINT chk_conectea_change_resolutions CHECK (
    CASE
      WHEN status = 'cancelled_by_holder' THEN
        (type = 'email' AND resolution_reason = 'declined_final_confirmation') OR
        (type = 'cpf' AND resolution_reason IN ('cancelled_during_review', 'cancelled_while_waiting_document', 'declined_final_confirmation'))

      WHEN status = 'expired' THEN
        (type = 'email' AND resolution_reason = 'holder_confirmation_deadline') OR
        (type = 'cpf' AND resolution_reason IN ('document_replacement_deadline', 'holder_confirmation_deadline'))

      ELSE
        resolution_reason IS NULL
    END
  );

-- E. Regras para Decisão Administrativa (documental)
ALTER TABLE public.account_change_requests
  ADD CONSTRAINT chk_conectea_change_admin_decision CHECK (
    (status NOT IN ('waiting_document_replacement', 'rejected_by_admin')) OR
    (
      type = 'cpf' AND
      admin_id IS NOT NULL AND
      admin_reason IS NOT NULL AND
      admin_feedback IS NOT NULL AND
      trim(admin_feedback) <> ''
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- 7. RECOMPOSIÇÃO DAS RPCs SEGURAS DE LEITURA
-- ─────────────────────────────────────────────────────────────────────────

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
-- 8. RECONFIGURAÇÃO DE PRIVILÉGIOS (MODELO DE MÍNIMOS PRIVILÉGIOS)
-- ─────────────────────────────────────────────────────────────────────────

-- A. Revogar acesso SELECT direto à tabela para authenticated (PostgREST)
REVOKE SELECT ON TABLE public.account_change_requests FROM authenticated;

-- B. Restringir execução das RPCs aos usuários logados (authenticated)
REVOKE ALL ON FUNCTION public.conectea_list_my_account_changes_v1(integer, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_list_my_account_changes_v1(integer, integer) TO authenticated;

REVOKE ALL ON FUNCTION public.conectea_get_my_account_change_v1(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_get_my_account_change_v1(uuid) TO authenticated;
