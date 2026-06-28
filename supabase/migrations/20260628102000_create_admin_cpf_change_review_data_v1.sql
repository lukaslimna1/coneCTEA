-- =========================================================================
-- ConeCTEA — Estrutura Privada Transitória de Análise Admin CPF
--
-- MIGRATION: 20260628102000_create_admin_cpf_change_review_data_v1.sql
-- OBJETIVO:
--   1. Criar a tabela privada private.account_change_review_data para dados transitórios.
--   2. Criar a RPC segura public.conectea_admin_get_cpf_change_sensitive_review_v1() para análise.
--   3. Criar a função private.conectea_clear_account_change_review_data_v1() para expurgo de PII.
--
-- STATUS: Criação local da migration para auditoria. Não aplicada remotamente.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. CRIAÇÃO PREVENTIVA E HARDENING DO SCHEMA PRIVADO
-- ─────────────────────────────────────────────────────────────────────────

CREATE SCHEMA IF NOT EXISTS private;

-- Hardening de segurança do Schema privado: restringe totalmente o uso via PostgREST
REVOKE USAGE ON SCHEMA private FROM PUBLIC, anon, authenticated;

-- Permite uso do schema pela role administrativa para execuções e RPCs do servidor
GRANT USAGE ON SCHEMA private TO service_role;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. CRIAÇÃO DA TABELA TRANSITÓRIA DE AUDITORIA
-- ─────────────────────────────────────────────────────────────────────────

-- Nota de Segurança: CPF claro (old_cpf_clear, new_cpf_clear) é dado PII transitório
-- e sensível, armazenado apenas temporariamente para auditoria. O user_id associado
-- foi removido desta tabela para evitar redundâncias, sendo resolvido em tempo
-- de consulta (JOIN) na requisição pública correspondente.
CREATE TABLE IF NOT EXISTS private.account_change_review_data (
  request_id uuid PRIMARY KEY REFERENCES public.account_change_requests(id) ON DELETE CASCADE,
  old_cpf_clear text NULL,
  new_cpf_clear text NULL,
  document_file_id text NULL,
  document_state text NOT NULL DEFAULT 'unknown',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  cleared_at timestamptz NULL,
  clear_reason text NULL,
  
  -- A. Restrição de domínio de estados de documento
  CONSTRAINT chk_account_change_review_document_state CHECK (
    document_state IN ('unknown', 'none', 'available', 'replaced', 'discarded', 'unavailable')
  ),

  -- B. Restrição estrutural para identificador do Google Drive (document_file_id)
  CONSTRAINT chk_review_document_file_id CHECK (
    document_file_id IS NULL OR document_file_id ~ '^[A-Za-z0-9_-]{10,256}$'
  ),

  -- C. Restrição estrutural para CPFs limpos (devem conter exatamente 11 caracteres numéricos)
  CONSTRAINT chk_review_old_cpf_clear CHECK (
    old_cpf_clear IS NULL OR length(regexp_replace(old_cpf_clear, '[^0-9]', '', 'g')) = 11
  ),
  CONSTRAINT chk_review_new_cpf_clear CHECK (
    new_cpf_clear IS NULL OR length(regexp_replace(new_cpf_clear, '[^0-9]', '', 'g')) = 11
  ),

  -- D. Restrição de coerência lógica pós-expurgo: se limpo, apaga dados sensíveis
  CONSTRAINT chk_review_coherence_after_clear CHECK (
    (cleared_at IS NULL) OR (
      old_cpf_clear IS NULL AND
      new_cpf_clear IS NULL AND
      document_file_id IS NULL
    )
  ),

  -- E. Restrição para motivo da limpeza: impede strings vazias e exige se cleared_at estiver preenchido
  CONSTRAINT chk_review_clear_reason CHECK (
    (clear_reason IS NULL OR btrim(clear_reason) <> '') AND
    (cleared_at IS NULL OR clear_reason IS NOT NULL)
  )
);

COMMENT ON TABLE private.account_change_review_data IS 'Tabela privada transitória contendo dados PII de CPF em formato limpo para auditoria do administrador.';

-- ─────────────────────────────────────────────────────────────────────────
-- 3. TRIGGER AUTOMÁTICO PARA UPDATED_AT
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION private.handle_account_change_review_data_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_account_change_review_data_updated_at ON private.account_change_review_data;
CREATE TRIGGER tr_account_change_review_data_updated_at
  BEFORE UPDATE ON private.account_change_review_data
  FOR EACH ROW
  EXECUTE FUNCTION private.handle_account_change_review_data_updated_at();

-- ─────────────────────────────────────────────────────────────────────────
-- 4. SEGURANÇA E POLÍTICAS DE RLS (TABELA PRIVADA)
-- ─────────────────────────────────────────────────────────────────────────

ALTER TABLE private.account_change_review_data ENABLE ROW LEVEL SECURITY;

-- Revoga explicitamente qualquer privilégio herdado por authenticated/anon nesta tabela
REVOKE ALL ON TABLE private.account_change_review_data FROM public, anon, authenticated;

-- RLS rígido: Acesso direto não é permitido a nenhum usuário comum.
-- Apenas service_role ou postgres possuem acesso a esta tabela privada.

-- ─────────────────────────────────────────────────────────────────────────
-- 5. RPC DE LEITURA SENSÍVEL PARA ADMINISTRADORES (SECURITY DEFINER)
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_admin_get_cpf_change_sensitive_review_v1(
  p_request_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private, pg_temp
AS $$
DECLARE
  v_caller_id uuid;
  v_caller_role text;
  v_request_exists boolean;
  v_request_type public.account_change_type;
  v_request_status public.account_change_status;
  v_review_record record;
  v_can_view boolean;
  v_review_found boolean := false;
  v_safe_document_state text := 'unavailable';
  v_can_view_document boolean := false;
  v_review_is_active boolean := false;
  
  -- Nota de Segurança: document_file_id é extremamente sensível, não deve ser logado pelo
  -- servidor de aplicação e não deve ser renderizado diretamente na UI. O seu retorno é
  -- restrito a esta RPC Security Definer sob demanda de admin dev/master autenticado para
  -- abertura de documento e auditoria.
  -- Dados sensíveis devem ser expurgados ao sair dos status analisáveis por fluxo backend específico.
BEGIN
  -- A. Validar caller autenticado
  v_caller_id := auth.uid();
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Acesso negado: usuario nao autenticado.' USING ERRCODE = '42501';
  END IF;

  -- B. Validar role do caller (Somente admin_master ou admin_dev possuem permissão)
  SELECT role INTO v_caller_role
  FROM public.profiles
  WHERE id = v_caller_id;

  IF v_caller_role IS NULL OR v_caller_role NOT IN ('admin_master', 'admin_dev') THEN
    RAISE EXCEPTION 'Acesso negado: privilegios insuficientes.' USING ERRCODE = '42501';
  END IF;

  -- C. Validar existência da solicitação
  SELECT EXISTS (
    SELECT 1 FROM public.account_change_requests WHERE id = p_request_id
  ) INTO v_request_exists;

  IF NOT v_request_exists THEN
    RAISE EXCEPTION 'Solicitacao nao encontrada.' USING ERRCODE = 'P0002';
  END IF;

  -- D. Validar tipo da solicitação (Deve ser CPF)
  SELECT type, status INTO v_request_type, v_request_status
  FROM public.account_change_requests
  WHERE id = p_request_id;

  IF v_request_type <> 'cpf'::public.account_change_type THEN
    RAISE EXCEPTION 'Operacao invalida: tipo de solicitacao incorreto.' USING ERRCODE = '42809';
  END IF;

  -- E. Determinar se o status permite leitura completa dos dados limpos
  -- Permitido apenas em: under_review, waiting_document_replacement, waiting_cpf_correction
  IF v_request_status IN (
    'under_review'::public.account_change_status,
    'waiting_document_replacement'::public.account_change_status,
    'waiting_cpf_correction'::public.account_change_status
  ) THEN
    v_can_view := true;
  ELSE
    v_can_view := false;
  END IF;

  -- F. Consultar tabela de review privada (vínculo de consistência e user_id resolvido no JOIN público)
  SELECT rd.* INTO v_review_record
  FROM private.account_change_review_data rd
  JOIN public.account_change_requests cr ON rd.request_id = cr.id
  WHERE rd.request_id = p_request_id;

  v_review_found := FOUND;

  -- G. Atribuir e calcular de forma segura o estado do documento e expurgo
  IF v_review_found THEN
    v_safe_document_state := COALESCE(v_review_record.document_state, 'unavailable');
    v_review_is_active := v_review_record.cleared_at IS NULL;

    v_can_view_document :=
      v_review_is_active
      AND v_safe_document_state = 'available'
      AND v_review_record.document_file_id IS NOT NULL
      AND v_review_record.document_file_id <> '';
  END IF;

  -- H. Montar retorno condicional baseado no status e expurgo
  IF v_can_view AND v_review_found AND v_review_is_active THEN
    RETURN jsonb_build_object(
      'can_view', true,
      'request_id', p_request_id,
      'status', v_request_status,
      'old_cpf_clear', v_review_record.old_cpf_clear,
      'new_cpf_clear', v_review_record.new_cpf_clear,
      'document_state', v_safe_document_state,
      'can_view_document', v_can_view_document,
      'document_file_id', CASE WHEN v_can_view_document THEN v_review_record.document_file_id ELSE NULL END,
      'server_now', now()
    );
  ELSE
    RETURN jsonb_build_object(
      'can_view', false,
      'request_id', p_request_id,
      'status', v_request_status,
      'old_cpf_clear', null,
      'new_cpf_clear', null,
      'document_state', v_safe_document_state,
      'can_view_document', false,
      'document_file_id', null,
      'server_now', now()
    );
  END IF;
END;
$$;

COMMENT ON FUNCTION public.conectea_admin_get_cpf_change_sensitive_review_v1(uuid)
  IS 'Obtém dados confidenciais e limpos da solicitação de CPF para admins dev/master, mascarando o PII se o status da solicitação estiver fechado ou inativo.';

-- Grants rígidos de execução
REVOKE ALL ON FUNCTION public.conectea_admin_get_cpf_change_sensitive_review_v1(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_admin_get_cpf_change_sensitive_review_v1(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_get_cpf_change_sensitive_review_v1(uuid) TO service_role;

-- ─────────────────────────────────────────────────────────────────────────
-- 6. FUNÇÃO DE LIMPEZA E EXPURGO LÓGICO DE DADOS SENSÍVEIS (PII)
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION private.conectea_clear_account_change_review_data_v1(
  p_request_id uuid,
  p_reason text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private, pg_temp
AS $$
DECLARE
  v_exists boolean;
  v_state text;
  v_reason_trimmed text;
  v_current_cleared_at timestamptz;
  v_current_clear_reason text;
  v_current_document_state text;
BEGIN
  -- A. Validar e sanitizar motivo de limpeza (não pode ser nulo ou vazio)
  -- Valores logicos esperados para clear_reason (documentado para auditoria):
  --   'status_completed', 'status_rejected', 'status_cancelled', 'status_expired', 'document_replaced', 'manual_cleanup', 'unavailable'
  v_reason_trimmed := trim(COALESCE(p_reason, ''));
  IF v_reason_trimmed = '' THEN
    RAISE EXCEPTION 'Motivo de limpeza invalido: clear_reason nao pode ser nulo ou vazio.' USING ERRCODE = '22004';
  END IF;

  -- B. Obter status de expurgo e estado do documento atual para garantir a idempotência perfeita
  SELECT cleared_at, clear_reason, document_state 
  INTO v_current_cleared_at, v_current_clear_reason, v_current_document_state
  FROM private.account_change_review_data
  WHERE request_id = p_request_id;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  -- C. Mapear estado do documento baseado no motivo do expurgo
  IF v_reason_trimmed IN ('status_completed', 'status_rejected', 'status_cancelled', 'status_expired', 'document_replaced', 'manual_cleanup') THEN
    v_state := 'discarded';
  ELSE
    v_state := 'unavailable';
  END IF;

  -- D. Executar expurgo dos dados sensíveis mantendo registro de auditoria anônimo (idempotente)
  -- Nota: Se o document_state atual já for terminal (discarded ou unavailable), ele é preservado.
  UPDATE private.account_change_review_data
  SET
    old_cpf_clear = null,
    new_cpf_clear = null,
    document_file_id = null,
    document_state = CASE
      WHEN v_current_document_state IN ('discarded', 'unavailable') THEN v_current_document_state
      ELSE v_state
    END,
    cleared_at = COALESCE(v_current_cleared_at, now()),
    clear_reason = COALESCE(v_current_clear_reason, v_reason_trimmed),
    updated_at = now()
  WHERE request_id = p_request_id;
END;
$$;

COMMENT ON FUNCTION private.conectea_clear_account_change_review_data_v1(uuid, text)
  IS 'Realiza a limpeza física dos dados PII de CPF e documento no banco privado, mantendo apenas metadados de auditoria.';

-- Apenas o banco de dados interno ou service_role podem executar o expurgo
REVOKE ALL ON FUNCTION private.conectea_clear_account_change_review_data_v1(uuid, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.conectea_clear_account_change_review_data_v1(uuid, text) TO service_role;
