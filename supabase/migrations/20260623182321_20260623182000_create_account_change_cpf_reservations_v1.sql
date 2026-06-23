-- =========================================================================
-- ConeCTEA — Tabela Privada de Reserva de CPF por HMAC
--
-- MIGRATION: 20260623182321_20260623182000_create_account_change_cpf_reservations_v1.sql
-- OBJETIVO:
--   - Criar a tabela privada de reservas private.account_change_cpf_reservations.
--   - Garantir exclusividade global do CPF solicitado enquanto o ciclo estiver ativo.
--   - Assegurar integridade relacional forte com a tabela pública de solicitações.
--
-- PRIVACIDADE E SEGURANÇA:
--   - Dados Pessoais: A tabela não armazena CPF puro, CPF mascarado, URL de documento,
--     nome, ou qualquer dado pessoal direto. O CPF solicitado é representado unicamente
--     por um hash irreversível (HMAC-SHA256).
--   - Proteção de Schema: A tabela reside no schema 'private', invisível para a API REST pública.
--   - Hardening: O Row Level Security (RLS) é habilitado e todos os grants são revogados para anon,
--     authenticated e PUBLIC. O risco de vazamento de dados é fortemente mitigado por este design.
--   - Origem do HMAC: O cálculo do HMAC não é realizado no Flutter, nem nesta migration. O hash
--     deve ser fornecido à base em lowercase normalizado por fluxos server-side futuros.
--     A normalização em lowercase impede duplicidade lógica por diferença de maiúsculas e minúsculas.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. CRIAÇÃO DA TABELA DE RESERVAS
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS private.account_change_cpf_reservations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NOT NULL,
  user_id uuid NOT NULL,
  request_type public.account_change_type NOT NULL DEFAULT 'cpf'::public.account_change_type,
  new_cpf_hmac text NOT NULL,
  new_cpf_hmac_key_version integer NOT NULL DEFAULT 1,
  reservation_state text NOT NULL DEFAULT 'attached',
  released_at timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  -- O campo updated_at será mantido/atualizado explicitamente por RPCs e fluxos server-side futuros ao liberar a reserva.
  updated_at timestamptz NOT NULL DEFAULT now(),

  -- Restrição para garantir que esta tabela serve apenas ao domínio de CPF
  CONSTRAINT chk_cpf_reservation_request_type CHECK (request_type = 'cpf'::public.account_change_type),

  -- Formato esperado do hash HMAC (hexadecimal de 64 caracteres em lowercase para evitar duplicidade lógica por casing)
  CONSTRAINT chk_cpf_reservation_hmac_format CHECK (new_cpf_hmac ~ '^[a-f0-9]{64}$'),

  -- Versão canônica obrigatória do HMAC
  CONSTRAINT chk_cpf_reservation_hmac_version CHECK (new_cpf_hmac_key_version = 1),

  -- Estados válidos da reserva (attached -> ativa no request, released -> liberada/encerrada)
  CONSTRAINT chk_cpf_reservation_state CHECK (reservation_state IN ('attached', 'released')),

  -- Coerência do estado com a data de liberação
  CONSTRAINT chk_cpf_reservation_state_coherence CHECK (
    (reservation_state = 'attached' AND released_at IS NULL) OR
    (reservation_state = 'released' AND released_at IS NOT NULL)
  ),

  -- Vínculo composto forte com a solicitação pública, limitando a tipo e usuário
  CONSTRAINT fk_cpf_reservation_request FOREIGN KEY (request_id, user_id, request_type)
    REFERENCES public.account_change_requests (id, user_id, type)
    ON DELETE CASCADE,

  -- Vínculo com a tabela de perfis
  CONSTRAINT fk_cpf_reservation_user FOREIGN KEY (user_id)
    REFERENCES public.profiles(id)
    ON DELETE CASCADE,

  -- Garante que uma solicitação tenha no máximo uma reserva
  CONSTRAINT uq_cpf_reservation_request UNIQUE (request_id)
);

-- ─────────────────────────────────────────────────────────────────────────
-- 2. CRIAÇÃO DE ÍNDICES E EXCLUSIVIDADE
-- ─────────────────────────────────────────────────────────────────────────

-- Impedir concorrência de reservas de CPF ativas entre contas diferentes
CREATE UNIQUE INDEX IF NOT EXISTS account_change_cpf_reservations_active_uniq_idx
  ON private.account_change_cpf_reservations (new_cpf_hmac)
  WHERE reservation_state = 'attached';

-- Busca rápida por usuário e data de criação (para listagem histórica interna)
CREATE INDEX IF NOT EXISTS account_change_cpf_reservations_user_idx
  ON private.account_change_cpf_reservations (user_id, created_at DESC);

-- ─────────────────────────────────────────────────────────────────────────
-- 3. SEGURANÇA E HARDENING DE GRANTS (RLS)
-- ─────────────────────────────────────────────────────────────────────────

-- Habilita Row Level Security (RLS)
ALTER TABLE private.account_change_cpf_reservations ENABLE ROW LEVEL SECURITY;

-- Revoga explicitamente todos os privilégios padrão
REVOKE ALL ON TABLE private.account_change_cpf_reservations FROM PUBLIC;
REVOKE ALL ON TABLE private.account_change_cpf_reservations FROM anon;
REVOKE ALL ON TABLE private.account_change_cpf_reservations FROM authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 4. DOCUMENTAÇÃO E COMENTÁRIOS DE SEGURANÇA
-- ─────────────────────────────────────────────────────────────────────────

COMMENT ON TABLE private.account_change_cpf_reservations IS
  'Tabela privada de reserva exclusiva de CPFs (representados por HMAC) em solicitações de alteração cadastral ativas.';

COMMENT ON COLUMN private.account_change_cpf_reservations.new_cpf_hmac IS
  'Identificador privado e anonimizado do CPF reservado. Não armazena CPF puro ou mascarado. O hash deve ser normalizado em lowercase.';

COMMENT ON COLUMN private.account_change_cpf_reservations.reservation_state IS
  'Estado da reserva: attached (anexado à solicitação ativa), released (liberada por cancelamento, rejeição, expiração ou sucesso final).';
