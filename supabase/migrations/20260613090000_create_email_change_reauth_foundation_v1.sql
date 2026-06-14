-- =========================================================================
-- ConeCTEA — Fundação da Prova Recente e Throttle de Senha (Corrigida)
--
-- MIGRATION: 20260613090000_create_email_change_reauth_foundation_v1.sql
-- OBJETIVO:
--   1. Vincular cada ciclo de alteração de e-mail à sessão que comprovou a senha.
--   2. Registrar o momento da prova recente (reauthenticated_at).
--   3. Criar throttle por sessão para tentativas incorretas de senha.
--   4. Criar throttle global por conta para impedir múltiplas sessões burlarem os limites.
--
-- STATUS: Criação local da migration para auditoria. Não aplicada remotamente.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. PRÉ-CONDIÇÃO FAIL-FAST
-- ─────────────────────────────────────────────────────────────────────────
-- A migration deve interromper antes de qualquer DDL se existirem ciclos.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM private.account_change_challenge_cycles LIMIT 1) THEN
    RAISE EXCEPTION 'Pre-condicao violada: A tabela private.account_change_challenge_cycles nao deve conter registros.';
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. ALTERAÇÕES NA TABELA DE CICLOS (PROVA RECENTE)
-- ─────────────────────────────────────────────────────────────────────────

-- Adiciona os campos de prova recente na tabela de ciclos
ALTER TABLE private.account_change_challenge_cycles
  ADD COLUMN reauth_session_hmac text NOT NULL,
  ADD COLUMN reauth_session_hmac_key_version integer NOT NULL,
  ADD COLUMN reauthenticated_at timestamptz NOT NULL,
  ADD COLUMN reauth_method text NOT NULL;

-- Constraints para os campos de reautenticação
ALTER TABLE private.account_change_challenge_cycles
  ADD CONSTRAINT chk_conectea_cycle_reauth_session_hmac CHECK (
    trim(both from reauth_session_hmac) <> ''
    AND reauth_session_hmac = trim(both from reauth_session_hmac)
    AND reauth_session_hmac !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    AND reauth_session_hmac !~ '^eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$'
  ),
  ADD CONSTRAINT chk_conectea_cycle_reauth_version CHECK (
    reauth_session_hmac_key_version = 1
  ),
  ADD CONSTRAINT chk_conectea_cycle_reauth_method CHECK (
    reauth_method = 'password'
  ),
  ADD CONSTRAINT chk_conectea_cycle_reauth_time CHECK (
    reauthenticated_at >= created_at
    AND reauthenticated_at <= updated_at
  );

-- Comentários documentais obrigatórios sobre a prova de senha no ciclo
COMMENT ON COLUMN private.account_change_challenge_cycles.reauth_session_hmac IS
  'HMAC seguro da session_id do Supabase Auth que realizou a prova recente de senha. Gerado na Edge Function usando chave privada secreta e versionada. session_id puro nunca e persistido no banco de dados para evitar vazamentos e rastreamentos cruzados. A prova pertence somente a sessao original. Refresh do JWT preserva a sessao logica, mas logout ou nova sessao nao herdam a prova. Validade conceitual de 30 minutos regida pelo relogio oficial do PostgreSQL: now() < reauthenticated_at + interval ''30 minutes''. Nova prova na mesma sessao atualiza somente reauthenticated_at. Outra sessao nao pode substituir o HMAC do ciclo.';

COMMENT ON COLUMN private.account_change_challenge_cycles.reauth_session_hmac_key_version IS
  'Versao da chave de hash HMAC da sessao de reautenticaçao. Canonicamente restrita a versao 1 para esta fundaçao.';

COMMENT ON COLUMN private.account_change_challenge_cycles.reauthenticated_at IS
  'Instante da ultima reautenticaçao por senha bem-sucedida associada ao ciclo de alteraçao.';

COMMENT ON COLUMN private.account_change_challenge_cycles.reauth_method IS
  'Metodo de reautenticaçao utilizado. Restrito ao valor ''password'' nesta fundaçao.';

-- ─────────────────────────────────────────────────────────────────────────
-- 3. CRIAÇÃO DA TABELA PRIVADA DE THROTTLE POR SESSÃO
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS private.account_change_reauth_throttles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  purpose text NOT NULL,
  session_hmac text NOT NULL,
  session_hmac_key_version integer NOT NULL,
  failed_attempts integer NOT NULL,
  window_started_at timestamptz NOT NULL,
  window_expires_at timestamptz NOT NULL,
  last_failed_at timestamptz NOT NULL,
  blocked_until timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  -- Contrato do Throttle por Sessão
  CONSTRAINT chk_conectea_throttle_purpose CHECK (
    purpose = 'email_change_reauth'
  ),

  CONSTRAINT chk_conectea_throttle_session_hmac CHECK (
    trim(both from session_hmac) <> ''
    AND session_hmac = trim(both from session_hmac)
    AND session_hmac !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    AND session_hmac !~ '^eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$'
  ),

  CONSTRAINT chk_conectea_throttle_session_version CHECK (
    session_hmac_key_version = 1
  ),

  CONSTRAINT chk_conectea_throttle_failed_attempts CHECK (
    failed_attempts >= 1 AND failed_attempts <= 5
  ),

  CONSTRAINT chk_conectea_throttle_window CHECK (
    window_expires_at = window_started_at + interval '15 minutes'
    AND last_failed_at >= window_started_at
    AND last_failed_at < window_expires_at
    AND updated_at >= created_at
  ),

  -- Bloqueio: Tentativas 1 a 4 exigem blocked_until NULL. Quinta tentativa exige failed_attempts = 5 e blocked_until = last_failed_at + 1 hora
  CONSTRAINT chk_conectea_throttle_lockout CHECK (
    (
      (failed_attempts < 5 AND blocked_until IS NULL)
      OR
      (failed_attempts = 5 AND blocked_until = last_failed_at + interval '1 hour')
    ) IS TRUE
  )
);

-- Comentários documentais obrigatórios sobre a tabela de throttle por sessão
COMMENT ON TABLE private.account_change_reauth_throttles IS
  'Tabela privada de controle de throttle de tentativas sucessivas de validaçao de senha para alteraçao de e-mail. Armazena apenas estatisticas e timestamps anonimizados da sessao. E expressamente proibido armazenar senhas, e-mails, session_id em texto claro, tokens, JWTs, IPs, user-agents ou motivos tecnicos brutos de falha nesta tabela para conformidade com privacidade e LGPD.';

COMMENT ON COLUMN private.account_change_reauth_throttles.session_hmac IS
  'HMAC seguro e anonimizado do session_id do Supabase Auth que realizou as tentativas. Nao contem session_id puro ou JWT.';

COMMENT ON COLUMN private.account_change_reauth_throttles.failed_attempts IS
  'Numero de tentativas incorretas consecutivas registradas na janela atual. Varia de 1 a 5.';

COMMENT ON COLUMN private.account_change_reauth_throttles.window_started_at IS
  'Inicio da janela de monitoramento de 15 minutos.';

COMMENT ON COLUMN private.account_change_reauth_throttles.window_expires_at IS
  'Fim da janela de monitoramento de 15 minutos (window_started_at + 15 minutos).';

COMMENT ON COLUMN private.account_change_reauth_throttles.blocked_until IS
  'Timestamp ate o qual a sessao esta bloqueada para novas tentativas de reautenticaçao (nulo para tentativas 1-4, last_failed_at + 1 hora para a 5ª tentativa).';

-- ─────────────────────────────────────────────────────────────────────────
-- 4. ÍNDICES DA TABELA DE THROTTLE POR SESSÃO
-- ─────────────────────────────────────────────────────────────────────────

-- Unicidade: Garante um throttle por conta, finalidade e sessao
CREATE UNIQUE INDEX IF NOT EXISTS account_change_reauth_throttles_session_uniq_idx
ON private.account_change_reauth_throttles (user_id, purpose, session_hmac, session_hmac_key_version);

-- Busca de bloqueios ativos por blocked_until
CREATE INDEX IF NOT EXISTS account_change_reauth_throttles_blocked_idx
ON private.account_change_reauth_throttles (blocked_until)
WHERE blocked_until IS NOT NULL;

-- Busca de janelas expiradas por window_expires_at (somente quando nao bloqueado)
CREATE INDEX IF NOT EXISTS account_change_reauth_throttles_expired_idx
ON private.account_change_reauth_throttles (window_expires_at)
WHERE blocked_until IS NULL;

-- ─────────────────────────────────────────────────────────────────────────
-- 5. TRIGGER E FUNÇÃO DE UPDATED_AT DO THROTTLE POR SESSÃO
-- ─────────────────────────────────────────────────────────────────────────

-- Função de atualização de timestamp dedicada ao domínio de throttle por sessão
CREATE OR REPLACE FUNCTION private.handle_account_change_reauth_throttles_updated_at()
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
REVOKE ALL ON FUNCTION private.handle_account_change_reauth_throttles_updated_at() FROM PUBLIC, anon, authenticated;

-- Trigger da tabela de throttles por sessão
CREATE TRIGGER tr_account_change_reauth_throttles_updated_at
  BEFORE UPDATE ON private.account_change_reauth_throttles
  FOR EACH ROW
  EXECUTE FUNCTION private.handle_account_change_reauth_throttles_updated_at();

-- Habilita RLS na tabela de throttle por sessão
ALTER TABLE private.account_change_reauth_throttles ENABLE ROW LEVEL SECURITY;

-- Revoga todos os privilégios padrão para anon, authenticated e PUBLIC
REVOKE ALL ON TABLE private.account_change_reauth_throttles FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 6. CRIAÇÃO DA TABELA PRIVADA DE THROTTLE GLOBAL POR CONTA
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS private.account_change_reauth_account_throttles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  purpose text NOT NULL,
  failed_attempts integer NOT NULL,
  window_started_at timestamptz NOT NULL,
  window_expires_at timestamptz NOT NULL,
  last_failed_at timestamptz NOT NULL,
  blocked_until timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  -- Contrato do Throttle Global por Conta
  CONSTRAINT chk_conectea_account_throttle_purpose CHECK (
    purpose = 'email_change_reauth'
  ),

  CONSTRAINT chk_conectea_account_throttle_failed_attempts CHECK (
    failed_attempts >= 1 AND failed_attempts <= 5
  ),

  CONSTRAINT chk_conectea_account_throttle_window CHECK (
    window_expires_at = window_started_at + interval '15 minutes'
    AND last_failed_at >= window_started_at
    AND last_failed_at < window_expires_at
    AND updated_at >= created_at
  ),

  -- Bloqueio: Tentativas 1 a 4 exigem blocked_until NULL. Quinta tentativa exige failed_attempts = 5 e blocked_until = last_failed_at + 1 hora
  CONSTRAINT chk_conectea_account_throttle_lockout CHECK (
    (
      (failed_attempts < 5 AND blocked_until IS NULL)
      OR
      (failed_attempts = 5 AND blocked_until = last_failed_at + interval '1 hour')
    ) IS TRUE
  )
);

-- Comentários documentais obrigatórios sobre a tabela de throttle global
COMMENT ON TABLE private.account_change_reauth_account_throttles IS
  'Tabela privada de controle de throttle global por conta para tentativas sucessivas de validaçao de senha. Impede que multiplas sessoes da mesma conta burlem o limite de falhas. E expressamente proibido armazenar senhas, e-mails, session_hmac, session_id, tokens, JWTs, IPs ou user-agents nesta tabela para conformidade com privacidade e LGPD.';

COMMENT ON COLUMN private.account_change_reauth_account_throttles.failed_attempts IS
  'Numero de tentativas incorretas consecutivas registradas na janela atual para a conta. Varia de 1 a 5.';

COMMENT ON COLUMN private.account_change_reauth_account_throttles.window_started_at IS
  'Inicio da janela de monitoramento de 15 minutos para a conta.';

COMMENT ON COLUMN private.account_change_reauth_account_throttles.window_expires_at IS
  'Fim da janela de monitoramento de 15 minutos (window_started_at + 15 minutos) para a conta.';

COMMENT ON COLUMN private.account_change_reauth_account_throttles.blocked_until IS
  'Timestamp ate o qual a conta esta bloqueada globalmente para novas tentativas (nulo para tentativas 1-4, last_failed_at + 1 hora para a 5ª tentativa).';

-- ─────────────────────────────────────────────────────────────────────────
-- 7. ÍNDICES DA TABELA DE THROTTLE GLOBAL POR CONTA
-- ─────────────────────────────────────────────────────────────────────────

-- Unicidade: Garante um throttle por conta e finalidade
CREATE UNIQUE INDEX IF NOT EXISTS account_change_reauth_account_throttles_uniq_idx
ON private.account_change_reauth_account_throttles (user_id, purpose);

-- Busca de bloqueios ativos por blocked_until
CREATE INDEX IF NOT EXISTS account_change_reauth_account_throttles_blocked_idx
ON private.account_change_reauth_account_throttles (blocked_until)
WHERE blocked_until IS NOT NULL;

-- Busca de janelas expiradas por window_expires_at (somente quando nao bloqueado)
CREATE INDEX IF NOT EXISTS account_change_reauth_account_throttles_expired_idx
ON private.account_change_reauth_account_throttles (window_expires_at)
WHERE blocked_until IS NULL;

-- ─────────────────────────────────────────────────────────────────────────
-- 8. TRIGGER E FUNÇÃO DE UPDATED_AT DO THROTTLE GLOBAL POR CONTA
-- ─────────────────────────────────────────────────────────────────────────

-- Função de atualização de timestamp dedicada ao domínio de throttle por conta
CREATE OR REPLACE FUNCTION private.handle_account_change_reauth_account_throttles_updated_at()
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
REVOKE ALL ON FUNCTION private.handle_account_change_reauth_account_throttles_updated_at() FROM PUBLIC, anon, authenticated;

-- Trigger da tabela de throttles por conta
CREATE TRIGGER tr_account_change_reauth_account_throttles_updated_at
  BEFORE UPDATE ON private.account_change_reauth_account_throttles
  FOR EACH ROW
  EXECUTE FUNCTION private.handle_account_change_reauth_account_throttles_updated_at();

-- Habilita RLS na tabela de throttle por conta
ALTER TABLE private.account_change_reauth_account_throttles ENABLE ROW LEVEL SECURITY;

-- Revoga todos os privilégios padrão para anon, authenticated e PUBLIC
REVOKE ALL ON TABLE private.account_change_reauth_account_throttles FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 9. CONTRATOS ARQUITETURAIS FUTUROS (APENAS DOCUMENTAÇÃO)
-- ─────────────────────────────────────────────────────────────────────────
/*
   A. ORDEM FUTURA DE LOCK PARA EVITAR DEADLOCKS:
   ---------------------------------------------
   Em todas as operaçoes de validaçao de senha, a futura funçao do backend DEVE seguir rigorosamente esta ordem:
   1. Obter e bloquear a linha correspondente ao throttle global da conta (private.account_change_reauth_account_throttles)
      filtrando por user_id e purpose usando SELECT FOR UPDATE.
   2. Obter e bloquear a linha correspondente ao throttle da sessao (private.account_change_reauth_throttles)
      filtrando por user_id, purpose, session_hmac e session_hmac_key_version usando SELECT FOR UPDATE.
   3. Verificar blocked_until da conta.
   4. Verificar blocked_until da sessao.
   5. Somente se nenhuma das tabelas possuir bloqueio ativo, prosseguir com a chamada a signInWithPassword.

   B. COMPORTAMENTO EM CASO DE SENHA INCORRETA:
   -------------------------------------------
   1. Incrementar atomicamente: Uma falha de login incrementa failed_attempts em ambos os throttles (da conta e da sessao).
   2. Bloqueio de uma hora: A 5ª falha em qualquer uma das tabelas define blocked_until = last_failed_at + 1 hora.
   3. Bloqueios e Acesso:
      - Se a conta estiver bloqueada globalmente, nenhuma outra sessao da mesma conta pode tentar.
      - Se apenas a sessao atual estiver bloqueada, aquela sessao nao pode tentar.
   4. Seguranca: Nenhuma falha cria ciclo, reserva, OTP ou dispara chamadas de e-mail ao GAS.

   C. COMPORTAMENTO EM CASO DE SENHA CORRETA:
   -----------------------------------------
   1. Limpeza Global da Conta: Apagar sumariamente a linha correspondente na tabela private.account_change_reauth_account_throttles.
   2. Limpeza do Throttle da Sessao: Apagar sumariamente a linha correspondente a sessao atual em private.account_change_reauth_throttles.
   3. Preservacao de outras sessoes: Nao apagar automaticamente os registros de throttle de outras sessoes da mesma conta.
   4. Criar Ciclo: Criar o ciclo com a prova recente preenchida em private.account_change_challenge_cycles.
   5. Seguranca: A senha nunca entra no PostgreSQL.

   D. COMPORTAMENTO DE JANELA EXPIRADA E BLOQUEIO:
   ----------------------------------------------
   1. Verificar bloqueio: Primeiro verificar se blocked_until esta definido e no futuro.
   2. Se o bloqueio ainda estiver ativo: Nao apagar nem reiniciar a linha, mesmo que window_expires_at <= now().
   3. Expiracao da janela: Se nao houver bloqueio ativo e window_expires_at <= now(), apagar transacionalmente a linha expirada
      (da conta ou da sessao).
   4. Proxima tentativa: A proxima falha criara uma nova janela iniciando failed_attempts em 1. Nunca persistir failed_attempts = 0.
*/
