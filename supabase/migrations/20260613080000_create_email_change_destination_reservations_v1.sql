-- =========================================================================
-- ConeCTEA — Reserva Exclusiva de Novo E-mail em Alterações de Conta
--
-- MIGRATION: 20260613080000_create_email_change_destination_reservations_v1.sql
-- OBJETIVO:
--   1. Criar a tabela privada de reservas private.account_change_email_reservations.
--   2. Enforçar chaves e integridade relacional forte com ciclos e solicitações.
--   3. Garantir exclusividade global do email reservado em estado ativo ou anexado.
--   4. Implementar integridade rigorosa de estados de ciclo de vida e prazos.
--   5. Documentar fluxo transacional futuro para início e aplicação final.
--
-- STATUS: Criação local da migration para auditoria. Não aplicada remotamente.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. PRÉ-CONDIÇÃO FAIL-FAST
-- ─────────────────────────────────────────────────────────────────────────
-- A migration deve interromper antes de qualquer DDL se existirem registros.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM private.account_change_challenges LIMIT 1) THEN
    RAISE EXCEPTION 'Pre-condicao violada: A tabela private.account_change_challenges nao deve conter registros.';
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. ALTERAÇÕES DE SUPORTE EM TABELAS EXISTENTES (CONSTRAINTS UNIQUES)
-- ─────────────────────────────────────────────────────────────────────────

-- Adiciona UNIQUE de suporte para ciclo de vida na reserva em private.account_change_challenge_cycles
ALTER TABLE private.account_change_challenge_cycles
  ADD CONSTRAINT uq_conectea_cycle_reservation_support UNIQUE (id, user_id, purpose, destination_hmac, destination_hmac_key_version);

-- Adiciona UNIQUE de suporte para fechamento real do ciclo em private.account_change_challenge_cycles
ALTER TABLE private.account_change_challenge_cycles
  ADD CONSTRAINT uq_conectea_cycle_closed_support UNIQUE (id, closed_at);

-- Adiciona UNIQUE de suporte em public.account_change_requests
ALTER TABLE public.account_change_requests
  ADD CONSTRAINT uq_conectea_request_reservation_support UNIQUE (id, user_id, type);

-- ─────────────────────────────────────────────────────────────────────────
-- 3. CRIAÇÃO DA TABELA PRIVADA DE RESERVA DE E-MAIL
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS private.account_change_email_reservations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  purpose text NOT NULL,
  destination_hmac text NOT NULL,
  destination_hmac_key_version integer NOT NULL,
  cycle_id uuid NOT NULL,
  request_id uuid NULL,
  request_type public.account_change_type NOT NULL,
  reservation_state text NOT NULL DEFAULT 'active',
  reserved_at timestamptz NOT NULL DEFAULT now(),
  cycle_hold_until timestamptz NULL,
  cycle_closed_at timestamptz NULL,
  released_at timestamptz NULL,
  release_reason text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  -- Restrição do tipo de requisição ao domínio de e-mail
  CONSTRAINT chk_conectea_reservation_request_type CHECK (
    request_type = 'email'::public.account_change_type
  ),

  -- Coerência do HMAC do destino
  CONSTRAINT chk_conectea_reservation_hmac CHECK (
    trim(both from destination_hmac) <> ''
    AND destination_hmac = trim(both from destination_hmac)
    AND purpose = 'email_change'
  ),

  -- Versão canônica obrigatória do HMAC
  CONSTRAINT chk_conectea_reservation_hmac_version CHECK (
    destination_hmac_key_version = 1
  ),

  -- Estados da reserva permitidos (active, attached, released, expired)
  CONSTRAINT chk_conectea_reservation_state CHECK (
    reservation_state IN ('active', 'attached', 'released', 'expired')
  ),

  -- Coerência temporal dos timestamps
  CONSTRAINT chk_conectea_reservation_timestamps CHECK (
    (cycle_hold_until IS NULL OR cycle_hold_until > reserved_at)
    AND updated_at >= created_at
    AND (released_at IS NULL OR released_at >= reserved_at)
  ),

  -- Coerência lógica dos estados com o vinculo do protocolo, hold e timestamps
  CONSTRAINT chk_conectea_reservation_state_coherence CHECK (
    (
      reservation_state = 'active'
      AND request_id IS NULL
      AND cycle_closed_at IS NULL
      AND released_at IS NULL
      AND release_reason IS NULL
    ) OR (
      reservation_state = 'attached'
      AND request_id IS NOT NULL
      AND cycle_closed_at IS NOT NULL
      AND cycle_hold_until IS NOT NULL
      AND released_at IS NULL
      AND release_reason IS NULL
    ) OR (
      reservation_state = 'released'
      AND cycle_closed_at IS NOT NULL
      AND released_at IS NOT NULL
      AND release_reason IS NOT NULL AND trim(both from release_reason) <> '' AND release_reason = trim(both from release_reason) AND length(release_reason) <= 100
    ) OR (
      reservation_state = 'expired'
      AND request_id IS NULL
      AND cycle_hold_until IS NOT NULL
      AND cycle_closed_at IS NOT NULL
      AND released_at IS NOT NULL
      AND released_at >= cycle_hold_until
      AND cycle_closed_at >= cycle_hold_until
      AND release_reason IS NOT NULL AND trim(both from release_reason) <> '' AND release_reason = trim(both from release_reason) AND length(release_reason) <= 100
    )
  ),

  -- Vínculo composto forte com o ciclo de alteração (ON DELETE RESTRICT)
  CONSTRAINT fk_conectea_reservation_cycle FOREIGN KEY (cycle_id, user_id, purpose, destination_hmac, destination_hmac_key_version)
    REFERENCES private.account_change_challenge_cycles (id, user_id, purpose, destination_hmac, destination_hmac_key_version)
    ON DELETE RESTRICT,

  -- Vínculo composto forte com o fechamento real do ciclo (ON DELETE RESTRICT)
  CONSTRAINT fk_conectea_reservation_cycle_closed FOREIGN KEY (cycle_id, cycle_closed_at)
    REFERENCES private.account_change_challenge_cycles (id, closed_at)
    ON DELETE RESTRICT,

  -- Vínculo composto forte com o protocolo de alteração (ON DELETE RESTRICT)
  CONSTRAINT fk_conectea_reservation_request FOREIGN KEY (request_id, user_id, request_type)
    REFERENCES public.account_change_requests (id, user_id, type)
    ON DELETE RESTRICT
);

-- ─────────────────────────────────────────────────────────────────────────
-- 4. CRIAÇÃO DE ÍNDICES E EXCLUSIVIDADE
-- ─────────────────────────────────────────────────────────────────────────

-- 1. Exclusividade global do destino ativo/anexado (impede concorrência de reservas ativas entre contas)
CREATE UNIQUE INDEX IF NOT EXISTS account_change_email_reservations_active_uniq_idx
ON private.account_change_email_reservations (destination_hmac)
WHERE reservation_state IN ('active', 'attached') AND released_at IS NULL;

-- 2. Busca por usuário (para listagem ou depuração histórica)
CREATE INDEX IF NOT EXISTS account_change_email_reservations_user_idx
ON private.account_change_email_reservations (user_id, purpose, created_at DESC);

-- 3. Busca e exclusividade por ciclo (um ciclo possui no máximo uma reserva)
CREATE UNIQUE INDEX IF NOT EXISTS account_change_email_reservations_cycle_uniq_idx
ON private.account_change_email_reservations (cycle_id);

-- 4. Busca por protocolo (uma solicitação possui no máximo uma reserva vinculada)
CREATE UNIQUE INDEX IF NOT EXISTS account_change_email_reservations_request_uniq_idx
ON private.account_change_email_reservations (request_id)
WHERE request_id IS NOT NULL;

-- 5. Busca de reservas a expirar (apenas no estado active com hold conhecido)
CREATE INDEX IF NOT EXISTS account_change_email_reservations_expiration_idx
ON private.account_change_email_reservations (cycle_hold_until)
WHERE reservation_state = 'active' AND released_at IS NULL AND cycle_hold_until IS NOT NULL;

-- ─────────────────────────────────────────────────────────────────────────
-- 5. TRIGGER E FUNÇÃO DE UPDATED_AT
-- ─────────────────────────────────────────────────────────────────────────

-- Função de atualização de timestamp dedicada ao domínio de reservas
CREATE OR REPLACE FUNCTION private.handle_account_change_email_reservations_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

-- Revoga execução pública
REVOKE ALL ON FUNCTION private.handle_account_change_email_reservations_updated_at() FROM PUBLIC, anon, authenticated;

-- Trigger da tabela de reservas
CREATE TRIGGER tr_account_change_email_reservations_updated_at
  BEFORE UPDATE ON private.account_change_email_reservations
  FOR EACH ROW
  EXECUTE FUNCTION private.handle_account_change_email_reservations_updated_at();

-- ─────────────────────────────────────────────────────────────────────────
-- 6. SEGURANÇA E GERENCIAMENTO DE GRANTS (RLS)
-- ─────────────────────────────────────────────────────────────────────────

-- Habilita RLS
ALTER TABLE private.account_change_email_reservations ENABLE ROW LEVEL SECURITY;

-- Revoga todos os privilégios padrão para anon, authenticated e PUBLIC
REVOKE ALL ON TABLE private.account_change_email_reservations FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 7. DOCUMENTAÇÃO E COMENTÁRIOS DE SEGURANÇA
-- ─────────────────────────────────────────────────────────────────────────

COMMENT ON TABLE private.account_change_email_reservations IS
  'Tabela privada de reserva exclusiva de emails destinos durante o fluxo de alteracao cadastral. Impede concorrencia de emails destinos entre contas diferentes. Nao expor ao Flutter.';

COMMENT ON COLUMN private.account_change_email_reservations.destination_hmac IS
  'Identificador privado e anonimizado do email normalizado reservado. Nenhum email em texto puro ou mascarado e armazenado nesta tabela. Nao exposto ao Flutter.';

COMMENT ON COLUMN private.account_change_email_reservations.cycle_id IS
  'Vinculo composto forte com o ciclo de alteracao que originou a reserva. A reserva nasce ligada ao ciclo.';

COMMENT ON COLUMN private.account_change_email_reservations.request_id IS
  'Vinculo composto com o protocolo gerado apos a validade do OTP. Nulo em estado active, preenchido quando attached. Pode ser mantido em caso de finalizacao (released/expired).';

COMMENT ON COLUMN private.account_change_email_reservations.reservation_state IS
  'Estado da reserva: active (pre-protocolo durante OTP), attached (vinculado ao request_id), released (liberada por cancelamento/conclusao), expired (vencida sem conclusao).';

COMMENT ON COLUMN private.account_change_email_reservations.cycle_hold_until IS
  'Prazo de retencao do ciclo completo na reserva. Impede a expiracao prematura por OTP individual. Nulo ate que o primeiro envio seja confirmado.';

COMMENT ON COLUMN private.account_change_email_reservations.cycle_closed_at IS
  'Data de fechamento real do ciclo. Vinculado via chave estrangeira com closed_at do ciclo.';

COMMENT ON COLUMN private.account_change_email_reservations.destination_hmac_key_version IS
  'Versao da chave de hash. Restrita ao valor 1 nesta versao para novas reservas.';

-- ─────────────────────────────────────────────────────────────────────────
-- 8. REGRAS ARQUITETURAIS FUTURAS (APENAS DOCUMENTAÇÃO)
-- ─────────────────────────────────────────────────────────────────────────
/*
   A. COMPORTAMENTO INTEGRADO DA FUNÇÃO DE INÍCIO (Lógica do Backend):
   ------------------------------------------------------------------
   1. Validar sessão: Extrair o uid do titular a partir do token JWT recebido.
   2. Obter e-mail atual canônico: Buscar o e-mail cadastrado na tabela de autenticação.
   3. Normalizar e-mail: Executar btrim e lowercase no novo endereço.
   4. Bloquear se igual: Rejeitar a alteração se o novo e-mail for idêntico ao atual.
   5. Detectar divergência: Garantir que auth.users.email e profiles.email estejam sincronizados.
   6. Validar senha atual: Realizar teste de login seguro.
   7. Verificar duplicidade em auth.users: Rejeitar se o e-mail de destino já estiver em uso por outra conta.
   8. Expiração de reserva anterior: Localizar e marcar reservas active antigas e vencidas como expired (sendo que now() >= cycle_hold_until
      apenas as torna candidatas à avaliação, não alterando automaticamente o reservation_state nem liberando o destination_hmac.
      A expiração real depende cumulativamente das condições descritas no item D.6, executadas sob lock e em transação:
      ciclo fechado, ausência de protocolo, ausência de desafio ativo relevante, ausência de OTP válido, ausência de reenvio
      disponível, cooldown final de uma hora encerrado e now() >= cycle_hold_until). Reservas com cycle_hold_until NULL são ignoradas.
   9. Adquirir reserva exclusiva: Tentar inserir a reserva em private.account_change_email_reservations.
      Caso haja violação de exclusividade em destination_hmac ativo/anexado, a transação aborta de imediato.
   10. Criar ciclo e desafio: Registrar o ciclo e desafio na mesma transação atômica após a validação da senha.

   B. COMPORTAMENTO INTEGRADO NA CONFIRMAÇÃO E APLICAÇÃO FINAL (Lógica do Backend):
   --------------------------------------------------------------------------------
   1. Verificar novamente duplicidade de auth.users.email imediatamente antes da gravação do protocolo.
   2. Criar o protocolo em public.account_change_requests.
   3. Mudar a reserva para o estado attached e preencher o request_id na mesma transação.
   4. Manter a reserva ativa e exclusiva (attached) durante toda a tramitação do protocolo.
   5. Liberar a reserva (mudando para released com motivo apropriado) somente quando o protocolo for finalizado
      de forma definitiva (concluído, rejeitado pelo admin ou cancelado).

   C. SEGURANÇA E ROTAÇÃO DA CHAVE HMAC:
   -------------------------------------
   1. O campo destination_hmac_key_version = 1 é a única versão canônica aceita para reservas ativas nesta fundação.
   2. Não podem coexistir versões diferentes para novas reservas.
   3. Rotação futura exige migration controlada.
   4. Antes de aceitar uma nova versão, reservas active/attached da versão anterior devem ser encerradas ou migradas transacionalmente.
   5. A aplicação deve ser temporariamente impedida de criar reservas durante a troca de versão.
   6. O número da versão não é segredo.

   D. DETALHES DE RETENÇÃO DO CICLO E COOLDOWN:
   --------------------------------------------
   1. Criação: A reserva nasce active, cycle_hold_until nasce NULL, o desafio nasce pending.
      Nenhuma expiração temporal ocorre antes de um envio confirmado.
   2. Pending e sending: A reserva permanece exclusiva. cycle_hold_until permanece NULL.
      O timeout mantém o desafio como sending e não libera a reserva.
   3. Primeiro ou segundo envio sent: Na transação que atualiza para sent, calcular o expires_at do desafio.
      Atualizar cycle_hold_until para: GREATEST(COALESCE(cycle_hold_until, expires_at), expires_at).
   4. Terceiro envio sent: Atualizar cycle_hold_until para cobrir: expires_at do terceiro OTP + 1 hora de cooldown.
      Usar GREATEST para nunca reduzir o hold existente.
   5. Falha ou cancelamento antes de sent: Fechar o ciclo e marcar a reserva como released.
      cycle_hold_until pode permanecer NULL. Nunca usar expired nesse caso.
   6. Expiração: A reserva somente pode virar expired quando, sob lock e na mesma transação:
      - não existe protocolo;
      - cycle_hold_until está preenchido (IS NOT NULL) e o ciclo foi fechado (cycle_closed_at IS NOT NULL);
      - não existe desafio active válido, nem OTP válido, nem reenvio pendente;
      - o cooldown final terminou e now() >= cycle_hold_until.
*/
