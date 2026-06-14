-- =========================================================================
-- ConeCTEA — Fundação das Tentativas de Reautenticação
--
-- MIGRATION: 20260613110000_create_email_change_reauth_attempts_v1.sql
-- OBJETIVO:
--   1. Criar tabela privada de tentativas individuais de reautenticação por senha.
--   2. Garantir segurança robusta por meio de RLS, revogações e restrições.
--   3. Criar constraints de integridade e coerência de estados de tentativas.
--
-- STATUS: Criação local da migration para validação. Não aplicada neste turno.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. CRIAÇÃO DA TABELA DE TENTATIVAS DE REAUTENTICAÇÃO
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS private.account_change_reauth_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  purpose text NOT NULL,
  session_hmac text NOT NULL,
  session_hmac_key_version integer NOT NULL,
  idempotency_key uuid NOT NULL,
  attempt_state text NOT NULL DEFAULT 'processing',
  processing_expires_at timestamptz NOT NULL,
  finalized_at timestamptz NULL,
  failed_technical_code_private text NULL,
  result_cycle_id uuid NULL,
  result_cycle_purpose text NULL,
  purge_after timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  -- 4. Finalidade restrita a reautenticação de email
  CONSTRAINT chk_conectea_attempt_purpose CHECK (
    purpose = 'email_change_reauth'
  ),

  -- 5. Validação estrutural do HMAC da sessão
  CONSTRAINT chk_conectea_attempt_session_hmac CHECK (
    trim(both from session_hmac) <> ''
    AND session_hmac = trim(both from session_hmac)
    AND session_hmac !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    AND session_hmac !~ '^eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$'
  ),

  CONSTRAINT chk_conectea_attempt_session_version CHECK (
    session_hmac_key_version = 1
  ),

  -- 6. Estados aceitos para a tentativa
  CONSTRAINT chk_conectea_attempt_state_values CHECK (
    attempt_state IN ('processing', 'succeeded', 'failed_credentials', 'failed_technical', 'expired')
  ),

  -- 7. TTL de Processamento de 60 segundos exatos
  CONSTRAINT chk_conectea_attempt_ttl CHECK (
    processing_expires_at = created_at + interval '60 seconds'
  ),

  -- 8. Validação estrutural do código técnico privado
  CONSTRAINT chk_conectea_attempt_failed_technical_code CHECK (
    failed_technical_code_private IS NULL
    OR (
      trim(both from failed_technical_code_private) <> ''
      AND failed_technical_code_private = trim(both from failed_technical_code_private)
      AND length(failed_technical_code_private) <= 64
      AND failed_technical_code_private ~ '^[a-z0-9_]+$'
    )
  ),

  -- 8. Coerência Transicional dos Estados (Blindada por IS TRUE)
  CONSTRAINT chk_conectea_attempt_state_coherence CHECK (
    (
      -- Estado: processing
      (
        attempt_state = 'processing'
        AND finalized_at IS NULL
        AND failed_technical_code_private IS NULL
        AND result_cycle_id IS NULL
        AND result_cycle_purpose IS NULL
        AND purge_after IS NULL
      )
      OR
      -- Estado: succeeded
      (
        attempt_state = 'succeeded'
        AND finalized_at IS NOT NULL
        AND finalized_at >= created_at
        AND finalized_at < processing_expires_at
        AND failed_technical_code_private IS NULL
        AND result_cycle_id IS NOT NULL
        AND result_cycle_purpose = 'email_change'
        AND purge_after = finalized_at + interval '10 minutes'
      )
      OR
      -- Estado: failed_credentials
      (
        attempt_state = 'failed_credentials'
        AND finalized_at IS NOT NULL
        AND finalized_at >= created_at
        AND finalized_at < processing_expires_at
        AND failed_technical_code_private IS NULL
        AND result_cycle_id IS NULL
        AND result_cycle_purpose IS NULL
        AND purge_after = finalized_at + interval '10 minutes'
      )
      OR
      -- Estado: failed_technical
      (
        attempt_state = 'failed_technical'
        AND finalized_at IS NOT NULL
        AND finalized_at >= created_at
        AND finalized_at < processing_expires_at
        AND failed_technical_code_private IS NOT NULL
        AND result_cycle_id IS NULL
        AND result_cycle_purpose IS NULL
        AND purge_after = finalized_at + interval '10 minutes'
      )
      OR
      -- Estado: expired
      (
        attempt_state = 'expired'
        AND finalized_at IS NOT NULL
        AND finalized_at >= processing_expires_at
        AND failed_technical_code_private IS NULL
        AND result_cycle_id IS NULL
        AND result_cycle_purpose IS NULL
        AND purge_after = finalized_at + interval '10 minutes'
      )
    ) IS TRUE
  ),

  -- 9. Vínculo Composto Declarativo de Ciclo Resultante
  CONSTRAINT fk_conectea_attempt_cycle_result FOREIGN KEY (result_cycle_id, user_id, result_cycle_purpose)
    REFERENCES private.account_change_challenge_cycles(id, user_id, purpose)
    ON DELETE RESTRICT
);


-- ─────────────────────────────────────────────────────────────────────────
-- 2. CRIAÇÃO DOS ÍNDICES OPERACIONAIS
-- ─────────────────────────────────────────────────────────────────────────

-- 12.1 Idempotência: Mesma chave, mesmo usuário e finalidade retorna a tentativa existente
CREATE UNIQUE INDEX IF NOT EXISTS account_change_reauth_attempts_idempotency_idx
ON private.account_change_reauth_attempts (user_id, purpose, idempotency_key);

-- 12.2 Processamento único: Garante no máximo uma tentativa ativa ('processing') por usuário
CREATE UNIQUE INDEX IF NOT EXISTS account_change_reauth_attempts_processing_uniq_idx
ON private.account_change_reauth_attempts (user_id, purpose)
WHERE attempt_state = 'processing';

-- 12.3 Ciclo resultante único: Impede que duas tentativas distintas reivindiquem o mesmo ciclo
CREATE UNIQUE INDEX IF NOT EXISTS account_change_reauth_attempts_result_cycle_uniq_idx
ON private.account_change_reauth_attempts (result_cycle_id)
WHERE result_cycle_id IS NOT NULL;

-- 12.4 Expiração: Permite monitoramento rápido de tentativas vencidas em aberto
CREATE INDEX IF NOT EXISTS account_change_reauth_attempts_expiring_idx
ON private.account_change_reauth_attempts (processing_expires_at)
WHERE attempt_state = 'processing';

-- 12.5 Limpeza: Permite exclusão célere de registros terminais expirados
CREATE INDEX IF NOT EXISTS account_change_reauth_attempts_purge_idx
ON private.account_change_reauth_attempts (purge_after)
WHERE purge_after IS NOT NULL;


-- ─────────────────────────────────────────────────────────────────────────
-- 3. TRIGGER E FUNÇÃO DE UPDATED_AT DEDICADOS
-- ─────────────────────────────────────────────────────────────────────────

-- Função de trigger dedicada ao domínio de tentativas
CREATE OR REPLACE FUNCTION private.handle_account_change_reauth_attempts_updated_at()
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

-- Revoga a execução pública da função do trigger
REVOKE ALL ON FUNCTION private.handle_account_change_reauth_attempts_updated_at() FROM PUBLIC, anon, authenticated;

-- Associa o trigger à tabela
CREATE TRIGGER tr_account_change_reauth_attempts_updated_at
  BEFORE UPDATE ON private.account_change_reauth_attempts
  FOR EACH ROW
  EXECUTE FUNCTION private.handle_account_change_reauth_attempts_updated_at();


-- ─────────────────────────────────────────────────────────────────────────
-- 4. SEGURANÇA E CONTROLE DE ACESSO (RLS E REVOKES)
-- ─────────────────────────────────────────────────────────────────────────

-- Habilita RLS na tabela
ALTER TABLE private.account_change_reauth_attempts ENABLE ROW LEVEL SECURITY;

-- Revoga todos os privilégios das roles comuns e públicas
REVOKE ALL ON TABLE private.account_change_reauth_attempts FROM PUBLIC, anon, authenticated;


-- ─────────────────────────────────────────────────────────────────────────
-- 5. DOCUMENTAÇÃO E COMENTÁRIOS OPERACIONAIS OBRIGATÓRIOS
-- ─────────────────────────────────────────────────────────────────────────

COMMENT ON TABLE private.account_change_reauth_attempts IS
  'Tabela privada para controle de tentativas individuais e isoladas de reautenticaçao por senha. Oferece idempotencia, impede concorrência paralela e monitora o ciclo de vida (TTL) de cada requisiçao antes do envio ao Supabase Auth. E terminantemente proibido gravar senhas, emails, JWTs, tokens ou dados de navegaçao como IP/user-agent nesta tabela.';

COMMENT ON COLUMN private.account_change_reauth_attempts.idempotency_key IS
  'Chave gerada pelo backend que identifica univocamente a requisiçao de reautenticaçao. Se a mesma chave, usuario e finalidade forem fornecidos na mesma sessao, a tentativa em andamento e retornada de forma idempotente, impedindo duplicidade.';

COMMENT ON COLUMN private.account_change_reauth_attempts.attempt_state IS
  'Estado atual da tentativa. processing: em validaçao; succeeded: autenticado e vinculado a um ciclo; failed_credentials: senha incorreta; failed_technical: timeout ou erro tecnico de infraestrutura; expired: processamento expirou.';

COMMENT ON COLUMN private.account_change_reauth_attempts.processing_expires_at IS
  'Instante limite calculado no Postgres no qual a tentativa expira caso a Edge Function nao retorne (created_at + 60 segundos).';

COMMENT ON COLUMN private.account_change_reauth_attempts.purge_after IS
  'Instante a partir do qual o registro terminal esta apto para purga automatica (finalized_at + 10 minutos).';

/*
   A. ORDEM OBRIGATÓRIA DE LOCKS PARA EVITAR DEADLOCKS:
   ---------------------------------------------------
   Qualquer rotina de validaçao de credenciais no banco de dados deve bloquear os registros sequencialmente:
   1. public.profiles (SELECT FOR UPDATE) -> Necessario porque as linhas de throttle podem nao existir.
   2. private.account_change_reauth_account_throttles (SELECT FOR UPDATE).
   3. private.account_change_reauth_throttles (SELECT FOR UPDATE).
   4. private.account_change_reauth_attempts (SELECT FOR UPDATE).

   B. CONTRATO FUTURO DE INÍCIO DA TENTATIVA (Sem implementar):
   ------------------------------------------------------------
   - Validar sessao ativa via public.conectea_validate_active_session_v1.
   - Adquirir lock sequencial conforme item A.
   - Verificar se há bloqueio ativo (failed_attempts = 5 em janela de 15m) e rejeitar se sim, sem limpar.
   - Se nao houver bloqueio e a janela de 15m expirou, apagar o throttle correspondente.
   - Verificar se ja existe tentativa ativa ('processing') concorrente e rejeitar se sim.
   - Expirar qualquer tentativa processing cujo processing_expires_at <= now() (muda para expired, define finalized_at).
   - Inserir a nova tentativa com estado 'processing', idempotency_key e processing_expires_at exato.
   - Retornar o attempt_id sintético criado (Flutter nunca recebe o attempt_id).

   C. CONTRATO FUTURO DE FINALIZAÇÃO DA TENTATIVA (Sem implementar):
   ---------------------------------------------------------------
   1. Credencial invalida (failed_credentials):
      - Validar attempt_id, sessao e usuario. Garantir estado 'processing' e validade do TTL.
      - Mudar estado para failed_credentials e definir finalized_at e purge_after.
      - Incrementar failed_attempts nos throttles de sessao e global.
      - Aplicar bloqueio de 1 hora caso atinja 5 falhas.
      - Impedir qualquer replay posterior.
   2. Sucesso (succeeded):
      - Validar attempt_id, sessao e usuario. Garantir estado 'processing' e validade do TTL.
      - Criar o ciclo de alteraçao em private.account_change_challenge_cycles.
      - Criar a reserva de destino em private.account_change_email_reservations.
      - Criar o desafio OTP em private.account_change_challenges.
      - Atualizar a tentativa para succeeded, vinculando-a ao result_cycle_id e result_cycle_purpose.
      - Apagar transacionalmente o throttle global da conta e o throttle da sessao atual do usuario.
      - Preservar os throttles de outras sessoes ativas.
   3. Falha tecnica (failed_technical):
      - Definir estado como failed_technical, gravando apenas o codigo tecnico sanitizado (ex: auth_timeout).
      - Nao incrementar throttles de falha, nao criar ciclos ou reservas.
   4. Expiracao (expired):
      - Caso a Edge tente finalizar uma tentativa vencida (now() >= processing_expires_at), ela muda para expired.
      - Nao altera throttles, nao permite criar ciclos ou reservas.
*/
