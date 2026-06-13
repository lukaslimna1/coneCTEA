-- =========================================================================
-- ConeCTEA — Fundação do Domínio, Schema e RLS para Alterações de Conta
-- 
-- MIGRATION: 20260612184500_create_account_change_domain_v1.sql
-- OBJETIVO: Criar os tipos, tabelas, RLS, índices e triggers de auditoria
--           para o fluxo de alteração de e-mail e CPF.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. CRIAÇÃO DE TIPOS E ENUMS DO DOMÍNIO
-- ─────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'account_change_type') THEN
    CREATE TYPE public.account_change_type AS ENUM ('email', 'cpf');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'account_change_status') THEN
    CREATE TYPE public.account_change_status AS ENUM (
      'applying',
      'completed',
      'application_failed',
      'waiting_proof',
      'under_review',
      'waiting_holder_confirmation',
      'rejected_by_admin',
      'cancelled_by_holder'
    );
  END IF;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. CRIAÇÃO DA TABELA PÚBLICA DE PROTOCOLOS
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.account_change_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type public.account_change_type NOT NULL,
  status public.account_change_status NOT NULL,
  protocol_number text UNIQUE NOT NULL,
  old_value_masked text,
  new_value_masked text NOT NULL,
  new_value_hmac text,
  justification text,
  document_state text,
  document_reference text,
  admin_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  admin_feedback text,
  holder_confirmed_at timestamptz,
  application_started_at timestamptz,
  application_completed_at timestamptz,
  failure_code text,
  idempotency_key uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────
-- 3. CRIAÇÃO DA TABELA PRIVADA DE PAYLOAD
-- ─────────────────────────────────────────────────────────────────────────

CREATE SCHEMA IF NOT EXISTS private;

CREATE TABLE IF NOT EXISTS private.account_change_secure_payloads (
  request_id uuid PRIMARY KEY REFERENCES public.account_change_requests(id) ON DELETE CASCADE,
  ciphertext text NOT NULL,
  nonce text NOT NULL,
  auth_tag text,
  algorithm text NOT NULL,
  key_version integer NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────
-- 4. CRIAÇÃO DE ÍNDICES OPERACIONAIS E FILTROS DE UNICIDADE
-- ─────────────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS account_change_requests_user_id_idx ON public.account_change_requests (user_id);
CREATE INDEX IF NOT EXISTS account_change_requests_status_idx ON public.account_change_requests (status);
CREATE INDEX IF NOT EXISTS account_change_requests_type_idx ON public.account_change_requests (type);
CREATE INDEX IF NOT EXISTS account_change_requests_created_at_idx ON public.account_change_requests (created_at);
CREATE INDEX IF NOT EXISTS account_change_requests_protocol_number_idx ON public.account_change_requests (protocol_number);
CREATE INDEX IF NOT EXISTS account_change_requests_new_value_hmac_idx ON public.account_change_requests (new_value_hmac) WHERE new_value_hmac IS NOT NULL;

-- Índice único parcial: impede mais de uma solicitação ativa do mesmo tipo para o mesmo usuário
CREATE UNIQUE INDEX IF NOT EXISTS account_change_requests_active_idx
ON public.account_change_requests (user_id, type)
WHERE status IN (
  'waiting_proof',
  'under_review',
  'waiting_holder_confirmation',
  'applying',
  'application_failed'
);

-- ─────────────────────────────────────────────────────────────────────────
-- 5. FUNÇÃO E TRIGGER PARA GERAR PROTOCOLO SERVER-SIDE
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.generate_account_change_protocol_v1()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  v_date_str text;
  v_random_num int;
  v_protocol text;
  v_exists boolean;
BEGIN
  v_date_str := to_char(timezone('America/Sao_Paulo', now()), 'YYYYMMDD');
  LOOP
    v_random_num := floor(random() * (9999 - 1000 + 1) + 1000)::int;
    v_protocol := 'AC-' || v_date_str || '-' || v_random_num::text;
    
    -- Defesa robusta contra colisões
    SELECT EXISTS (
      SELECT 1 FROM public.account_change_requests WHERE protocol_number = v_protocol
    ) INTO v_exists;
    
    IF NOT v_exists THEN
      EXIT;
    END IF;
  END LOOP;
  RETURN v_protocol;
END;
$$;

-- Trigger para definir protocol_number antes de inserir
CREATE OR REPLACE FUNCTION public.handle_account_change_requests_protocol()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.protocol_number IS NULL OR NEW.protocol_number = '' THEN
    NEW.protocol_number := public.generate_account_change_protocol_v1();
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER tr_account_change_requests_protocol
  BEFORE INSERT ON public.account_change_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_account_change_requests_protocol();

-- ─────────────────────────────────────────────────────────────────────────
-- 6. TRIGGER PARA ATUALIZAR UPDATED_AT AUTOMATICAMENTE
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.handle_account_change_requests_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER tr_account_change_requests_updated_at
  BEFORE UPDATE ON public.account_change_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_account_change_requests_updated_at();

-- Trigger de updated_at para a tabela privada
CREATE OR REPLACE FUNCTION private.handle_account_change_secure_payloads_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER tr_account_change_secure_payloads_updated_at
  BEFORE UPDATE ON private.account_change_secure_payloads
  FOR EACH ROW
  EXECUTE FUNCTION private.handle_account_change_secure_payloads_updated_at();

-- ─────────────────────────────────────────────────────────────────────────
-- 7. ATIVAÇÃO DE RLS E POLÍTICAS DE SEGURANÇA
-- ─────────────────────────────────────────────────────────────────────────

ALTER TABLE public.account_change_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.account_change_secure_payloads ENABLE ROW LEVEL SECURITY;

-- Usuários authenticated comuns: visualizam apenas seus próprios pedidos
CREATE POLICY "Permitir que usuários leiam os próprios protocolos"
ON public.account_change_requests
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Admins Master/Dev: visualizam todos os protocolos
CREATE POLICY "Permitir que admin_master e admin_dev leiam todos os protocolos"
ON public.account_change_requests
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 
    FROM public.profiles p 
    WHERE p.id = auth.uid() 
      AND p.role IN ('admin_master', 'admin_dev')
  )
);

-- RLS para a tabela privada: nenhuma política concede acesso a authenticated comuns.
-- Apenas service_role ou postgres podem acessá-la por padrão (sem políticas públicas).

-- ─────────────────────────────────────────────────────────────────────────
-- 8. GERENCIAMENTO DE GRANTS (PRIVILÉGIOS MÍNIMOS)
-- ─────────────────────────────────────────────────────────────────────────

-- Revoga privilégios herdados por padrão na tabela pública
REVOKE ALL ON TABLE public.account_change_requests FROM public, anon, authenticated;

-- authenticated comuns e admins podem executar apenas SELECT na tabela pública
GRANT SELECT ON TABLE public.account_change_requests TO authenticated;

-- Anon não possui absolutamente nenhum privilégio
REVOKE ALL ON TABLE public.account_change_requests FROM anon;

-- Tabela privada: revogação explícita de qualquer herança para anon/authenticated
REVOKE ALL ON TABLE private.account_change_secure_payloads FROM public, anon, authenticated;
