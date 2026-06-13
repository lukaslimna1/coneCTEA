-- =========================================================================
-- ConeCTEA — Fundação de Desafios Temporários para Alteração de Conta (Ciclos e Desafios)
--
-- MIGRATION: 20260613050000_create_email_change_challenge_foundation_v1.sql
-- OBJETIVO:
--   1. Criar a tabela privada de ciclos private.account_change_challenge_cycles.
--   2. Criar a tabela privada de desafios private.account_change_challenges vinculada ao ciclo.
--   3. Implementar restrições severas de integridade para estados de entrega.
--   4. Habilitar RLS e revogar privilégios públicos em ambas as tabelas.
--   5. Configurar índices de expiração, rate-limit, cooldown e chaves de idempotência.
--
-- STATUS: Criação local da migration para auditoria. Não aplicada remotamente.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. CRIAÇÃO DA TABELA PRIVADA DE CICLOS (MÃE)
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS private.account_change_challenge_cycles (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  purpose text NOT NULL,
  
  -- Destino protegido
  destination_hmac text NOT NULL,
  destination_hmac_key_version integer NOT NULL,
  destination_ciphertext text NOT NULL,
  destination_nonce text NOT NULL,
  destination_auth_tag text NOT NULL,
  encryption_algorithm text NOT NULL,
  encryption_key_version integer NOT NULL,
  
  -- Controle de cooldown e encerramento do ciclo
  cooldown_until timestamptz NULL,
  closed_at timestamptz NULL,
  
  -- Timestamps gerais
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  -- Chave única composta para possibilitar o vínculo de chave estrangeira com a tabela filha
  CONSTRAINT uq_conectea_cycle_user_purpose UNIQUE (id, user_id, purpose)
);

-- ─────────────────────────────────────────────────────────────────────────
-- 1.A. CONSTRAINTS DE INTEGRIDADE DA TABELA DE CICLOS
-- ─────────────────────────────────────────────────────────────────────────

-- Finalidade restrita nesta versão
ALTER TABLE private.account_change_challenge_cycles
  ADD CONSTRAINT chk_conectea_cycle_purpose CHECK (
    purpose = 'email_change'
  );

-- Campos criptográficos e HMAC não vazios
ALTER TABLE private.account_change_challenge_cycles
  ADD CONSTRAINT chk_conectea_cycle_crypto_non_empty CHECK (
    trim(both from destination_hmac) <> '' AND
    trim(both from destination_ciphertext) <> '' AND
    trim(both from destination_nonce) <> '' AND
    trim(both from destination_auth_tag) <> '' AND
    trim(both from encryption_algorithm) <> ''
  );

-- Algoritmo de criptografia de destino simétrico restrito
ALTER TABLE private.account_change_challenge_cycles
  ADD CONSTRAINT chk_conectea_cycle_encryption_algo CHECK (
    encryption_algorithm = 'aes-256-gcm'
  );

-- Versões das chaves e HMAC positivas
ALTER TABLE private.account_change_challenge_cycles
  ADD CONSTRAINT chk_conectea_cycle_key_versions CHECK (
    encryption_key_version > 0 AND 
    destination_hmac_key_version > 0
  );

-- Coerência de prazos temporais se definidos
ALTER TABLE private.account_change_challenge_cycles
  ADD CONSTRAINT chk_conectea_cycle_dates CHECK (
    (cooldown_until IS NULL OR cooldown_until > created_at) AND
    (closed_at IS NULL OR closed_at >= created_at) AND
    (updated_at >= created_at)
  );

-- ─────────────────────────────────────────────────────────────────────────
-- 2. CRIAÇÃO DA TABELA PRIVADA DE DESAFIOS (FILHA)
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS private.account_change_challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cycle_id uuid NOT NULL,
  user_id uuid NOT NULL,
  purpose text NOT NULL,
  idempotency_key uuid NOT NULL,
  
  -- Ciclo de vida do desafio
  challenge_state text NOT NULL DEFAULT 'active',
  consumed_at timestamptz NULL,
  expired_at timestamptz NULL,
  cancelled_at timestamptz NULL,
  blocked_at timestamptz NULL,

  -- Estado de entrega do e-mail
  delivery_status text NOT NULL DEFAULT 'pending',
  delivery_attempts integer NOT NULL DEFAULT 0,
  last_delivery_attempt_at timestamptz NULL,
  sent_at timestamptz NULL,
  failed_at timestamptz NULL,
  delivery_failure_reason_private text NULL,

  -- Posição do código no ciclo
  send_sequence integer NOT NULL,

  -- Código de verificação protegido
  code_hmac text NOT NULL,
  code_hmac_key_version integer NOT NULL,

  -- Prazos e tentativas
  expires_at timestamptz NULL,
  attempts integer NOT NULL DEFAULT 0,
  max_attempts integer NOT NULL DEFAULT 3,
  resend_available_at timestamptz NULL,

  -- Timestamps gerais
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  -- Vínculo forte com o ciclo de alteração (impede ciclo de outro usuário ou propósito)
  CONSTRAINT fk_conectea_challenge_cycle FOREIGN KEY (cycle_id, user_id, purpose)
    REFERENCES private.account_change_challenge_cycles (id, user_id, purpose)
    ON DELETE CASCADE
);

-- ─────────────────────────────────────────────────────────────────────────
-- 2.A. CONSTRAINTS DE INTEGRIDADE DA TABELA DE DESAFIOS
-- ─────────────────────────────────────────────────────────────────────────

-- Finalidade restrita nesta versão
ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_purpose CHECK (
    purpose = 'email_change'
  );

-- Estados permitidos para o ciclo de vida lógico do desafio
ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_state CHECK (
    challenge_state IN ('active', 'consumed', 'expired', 'cancelled', 'blocked')
  );

-- Coerência e exclusividade mútua dos estados do ciclo de vida
ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_state_timestamps CHECK (
    (challenge_state = 'active' AND consumed_at IS NULL AND expired_at IS NULL AND cancelled_at IS NULL AND blocked_at IS NULL) OR
    (challenge_state = 'consumed' AND consumed_at IS NOT NULL AND expired_at IS NULL AND cancelled_at IS NULL AND blocked_at IS NULL) OR
    (challenge_state = 'expired' AND expired_at IS NOT NULL AND consumed_at IS NULL AND cancelled_at IS NULL AND blocked_at IS NULL) OR
    (challenge_state = 'cancelled' AND cancelled_at IS NOT NULL AND consumed_at IS NULL AND expired_at IS NULL AND blocked_at IS NULL) OR
    (challenge_state = 'blocked' AND blocked_at IS NOT NULL AND consumed_at IS NULL AND expired_at IS NULL AND cancelled_at IS NULL)
  );

-- Estado de entrega do e-mail
ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_delivery_status CHECK (
    delivery_status IN ('pending', 'sending', 'sent', 'failed')
  );

-- Sequência de envios limitada a no máximo 3 tentativas efetivas por ciclo
ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_send_sequence CHECK (
    send_sequence BETWEEN 1 AND 3
  );

-- Endurecimento das regras e timestamps de entrega pelo GAS (cooldown_until movido para a tabela de ciclos)
ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_delivery_rules CHECK (
    -- Estado pending: nada enviado, prazos nulos
    (delivery_status = 'pending' AND 
     delivery_attempts = 0 AND 
     last_delivery_attempt_at IS NULL AND 
     sent_at IS NULL AND 
     failed_at IS NULL AND 
     delivery_failure_reason_private IS NULL AND
     expires_at IS NULL AND
     resend_available_at IS NULL) OR
     
    -- Estado sending: em processo de envio, prazos nulos
    (delivery_status = 'sending' AND 
     delivery_attempts > 0 AND 
     last_delivery_attempt_at IS NOT NULL AND 
     sent_at IS NULL AND 
     failed_at IS NULL AND 
     delivery_failure_reason_private IS NULL AND
     expires_at IS NULL AND
     resend_available_at IS NULL) OR
     
    -- Estado sent: envio aceito/concluído pelo MailApp/GAS (não significa entrega na caixa de entrada)
    --   - prazo de expiração de exatamente 15 minutos a partir de sent_at
    --   - reenvio liberado somente após a expiração
    (delivery_status = 'sent' AND 
     delivery_attempts > 0 AND 
     last_delivery_attempt_at IS NOT NULL AND 
     sent_at IS NOT NULL AND 
     failed_at IS NULL AND 
     delivery_failure_reason_private IS NULL AND
     expires_at = sent_at + interval '15 minutes' AND
     resend_available_at = expires_at) OR
     
    -- Estado failed: e-mail falhou definitivamente, cancelado atômico
    (delivery_status = 'failed' AND 
     delivery_attempts > 0 AND 
     last_delivery_attempt_at IS NOT NULL AND 
     failed_at IS NOT NULL AND 
     sent_at IS NULL AND 
     delivery_failure_reason_private IS NOT NULL AND 
     trim(both from delivery_failure_reason_private) <> '' AND 
     length(delivery_failure_reason_private) <= 250 AND
     expires_at IS NULL AND
     resend_available_at IS NULL)
  );

-- Coerência dos timestamps em relação ao momento de criação do desafio (created_at)
-- e limites dos prazos terminais em relação à expiração (expires_at) se definidos
ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_timestamps_coherence CHECK (
    -- Nenhum timestamp operacional pode ser anterior à data de criação
    (consumed_at IS NULL OR consumed_at >= created_at) AND
    (expired_at IS NULL OR expired_at >= created_at) AND
    (cancelled_at IS NULL OR cancelled_at >= created_at) AND
    (blocked_at IS NULL OR blocked_at >= created_at) AND
    (last_delivery_attempt_at IS NULL OR last_delivery_attempt_at >= created_at) AND
    (sent_at IS NULL OR sent_at >= created_at) AND
    (failed_at IS NULL OR failed_at >= created_at) AND
    (updated_at >= created_at) AND

    -- Timestamps terminais lógicos condicionados ao prazo limite de expiração se definidos
    (expires_at IS NULL OR (
      (consumed_at IS NULL OR consumed_at < expires_at) AND
      (expired_at IS NULL OR expired_at >= expires_at) AND
      (blocked_at IS NULL OR blocked_at < expires_at)
    ))
  );

-- Semântica de Falha Definida: se o e-mail falhou definitivamente, exige cancelamento e coerência de timestamps
ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_failed_delivery CHECK (
    delivery_status <> 'failed' OR (
      challenge_state = 'cancelled' AND 
      failed_at IS NOT NULL AND
      cancelled_at IS NOT NULL AND
      cancelled_at = failed_at
    )
  );

-- Estado bloqueado exige esgotamento das tentativas do OTP
ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_blocked_state CHECK (
    challenge_state <> 'blocked' OR 
    attempts = max_attempts
  );

-- Estado expired exige e-mail enviado com sucesso e prazos definidos e coerentes
ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_expired_state CHECK (
    challenge_state <> 'expired' OR (
      delivery_status = 'sent' AND
      expires_at IS NOT NULL AND
      expired_at IS NOT NULL AND
      expired_at >= expires_at
    )
  );

-- Invariante de validação do desafio: consumed ou blocked exigem e-mail enviado com sucesso
ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_state_delivery_invariant CHECK (
    challenge_state NOT IN ('consumed', 'blocked') OR 
    delivery_status = 'sent'
  );

-- Campos criptográficos obrigatórios e não vazios
ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_crypto_non_empty CHECK (
    trim(both from code_hmac) <> ''
  );

-- Versão da chave do código OTP positiva
ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_key_versions CHECK (
    code_hmac_key_version > 0
  );

-- Controle de tentativas de digitação do OTP
ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_attempts CHECK (
    attempts >= 0 AND 
    attempts <= max_attempts
  );

-- Faixa defensiva razoável de tentativas máximas
ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_max_attempts CHECK (
    max_attempts >= 1 AND 
    max_attempts <= 10
  );

-- Coerência de prazos temporais se definidos
ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_dates CHECK (
    expires_at IS NULL OR (
      expires_at > created_at AND
      resend_available_at >= created_at AND
      resend_available_at <= expires_at
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- 3. CRIAÇÃO DE ÍNDICES OPERACIONAIS E UNICIDADE
-- ─────────────────────────────────────────────────────────────────────────

-- --- ÍNDICES DA TABELA DE CICLOS ---

-- Rate limit por e-mail de destino
CREATE INDEX IF NOT EXISTS account_change_challenge_cycles_rate_limit_idx 
ON private.account_change_challenge_cycles (destination_hmac, purpose, created_at DESC);

-- Ciclo aberto único por usuário e finalidade (impede concorrência de ciclos ativos)
CREATE UNIQUE INDEX IF NOT EXISTS account_change_challenge_cycles_open_idx 
ON private.account_change_challenge_cycles (user_id, purpose) 
WHERE (closed_at IS NULL);

-- Busca rápida de ciclos em cooldown ativo
CREATE INDEX IF NOT EXISTS account_change_challenge_cycles_cooldown_idx 
ON private.account_change_challenge_cycles (user_id, purpose, cooldown_until DESC) 
WHERE (closed_at IS NULL AND cooldown_until IS NOT NULL);


-- --- ÍNDICES DA TABELA DE DESAFIOS ---

-- Idempotência: impede a mesma chave de idempotência para o mesmo usuário e finalidade
CREATE UNIQUE INDEX IF NOT EXISTS account_change_challenges_idempotency_idx 
ON private.account_change_challenges (user_id, purpose, idempotency_key);

-- Desafio ativo único por usuário e finalidade (garante concorrência serializada de OTPs ativos)
CREATE UNIQUE INDEX IF NOT EXISTS account_change_challenges_active_uid_purpose_idx 
ON private.account_change_challenges (user_id, purpose) 
WHERE (challenge_state = 'active');

-- Unicidade parcial: impede dois envios aceitos na mesma posição do mesmo ciclo (failed podem repetir)
CREATE UNIQUE INDEX IF NOT EXISTS account_change_challenges_cycle_sequence_sent_idx 
ON private.account_change_challenges (cycle_id, send_sequence) 
WHERE (delivery_status = 'sent');

-- Consulta rápida de desafios de um ciclo específico por ordem cronológica
CREATE INDEX IF NOT EXISTS account_change_challenges_cycle_lookup_idx 
ON private.account_change_challenges (cycle_id, created_at DESC);

-- Monitoramento de expiração de desafios ativos
CREATE INDEX IF NOT EXISTS account_change_challenges_expiration_idx 
ON private.account_change_challenges (expires_at) 
WHERE (challenge_state = 'active');

-- Acompanhamento do status de entrega
CREATE INDEX IF NOT EXISTS account_change_challenges_delivery_status_idx 
ON private.account_change_challenges (delivery_status);

-- Busca operacional de desafios históricos por usuário
CREATE INDEX IF NOT EXISTS account_change_challenges_search_idx 
ON private.account_change_challenges (user_id, purpose, created_at DESC);

-- ─────────────────────────────────────────────────────────────────────────
-- 4. TRIGGERS PRIVADOS DE UPDATED_AT
-- ─────────────────────────────────────────────────────────────────────────

-- Função de atualização da tabela de ciclos
CREATE OR REPLACE FUNCTION private.handle_account_change_challenge_cycles_updated_at()
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
REVOKE ALL ON FUNCTION private.handle_account_change_challenge_cycles_updated_at() FROM PUBLIC, anon, authenticated;

-- Trigger para ciclos
CREATE TRIGGER tr_account_change_challenge_cycles_updated_at
  BEFORE UPDATE ON private.account_change_challenge_cycles
  FOR EACH ROW
  EXECUTE FUNCTION private.handle_account_change_challenge_cycles_updated_at();


-- Função de atualização da tabela de desafios
CREATE OR REPLACE FUNCTION private.handle_account_change_challenges_updated_at()
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
REVOKE ALL ON FUNCTION private.handle_account_change_challenges_updated_at() FROM PUBLIC, anon, authenticated;

-- Trigger para desafios
CREATE TRIGGER tr_account_change_challenges_updated_at
  BEFORE UPDATE ON private.account_change_challenges
  FOR EACH ROW
  EXECUTE FUNCTION private.handle_account_change_challenges_updated_at();

-- ─────────────────────────────────────────────────────────────────────────
-- 5. SEGURANÇA E GERENCIAMENTO DE GRANTS (RLS)
-- ─────────────────────────────────────────────────────────────────────────

-- Habilita RLS em ambas as tabelas
ALTER TABLE private.account_change_challenge_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.account_change_challenges ENABLE ROW LEVEL SECURITY;

-- Revoga todos os privilégios padrão para anon, authenticated e PUBLIC
REVOKE ALL ON TABLE private.account_change_challenge_cycles FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE private.account_change_challenges FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 6. DOCUMENTAÇÃO E COMENTÁRIOS DE SEGURANÇA
-- ─────────────────────────────────────────────────────────────────────────

-- Comentários da tabela de ciclos
COMMENT ON TABLE private.account_change_challenge_cycles 
  IS 'Tabela privada de ciclos de desafios temporarios pre-protocolo para alteracoes de conta. Nao expor ao Flutter.';

COMMENT ON COLUMN private.account_change_challenge_cycles.destination_hmac 
  IS 'Fingerprint do novo email destino usando HMAC-SHA256 para rate limit e idempotencia.';

COMMENT ON COLUMN private.account_change_challenge_cycles.destination_hmac_key_version 
  IS 'Versao da chave de HMAC do destino.';

COMMENT ON COLUMN private.account_change_challenge_cycles.destination_ciphertext 
  IS 'Valor criptografado do novo email destino para posterior recuperacao no backend.';

COMMENT ON COLUMN private.account_change_challenge_cycles.destination_nonce 
  IS 'Nonce utilizado na criptografia simetrica (AES-GCM) do novo email destino.';

COMMENT ON COLUMN private.account_change_challenge_cycles.destination_auth_tag 
  IS 'Tag de autenticacao da criptografia simetrica do novo email destino.';

COMMENT ON COLUMN private.account_change_challenge_cycles.encryption_algorithm 
  IS 'Algoritmo de criptografia do destino simetrico restrito (aes-256-gcm).';

COMMENT ON COLUMN private.account_change_challenge_cycles.encryption_key_version 
  IS 'Versao da chave de criptografia do destino simetrico.';

COMMENT ON COLUMN private.account_change_challenge_cycles.cooldown_until 
  IS 'Data de desbloqueio do titular apos atingir o limite de 3 codigos enviados no ciclo (1 hora de bloqueio apos a expiracao do terceiro codigo).';

COMMENT ON COLUMN private.account_change_challenge_cycles.closed_at 
  IS 'Data de encerramento do ciclo. Ciclos abertos possuem closed_at IS NULL.';

-- Comentários da tabela de desafios
COMMENT ON TABLE private.account_change_challenges 
  IS 'Tabela privada de desafios temporarios pre-protocolo associados a um ciclo de envio. Nao expor ao Flutter.';

COMMENT ON COLUMN private.account_change_challenges.cycle_id 
  IS 'Chave estrangeira vinculando o desafio ao seu ciclo de envio correspondente.';

COMMENT ON COLUMN private.account_change_challenges.code_hmac 
  IS 'HMAC-SHA256 do codigo OTP gerado. O codigo puro nunca e armazenado.';

COMMENT ON COLUMN private.account_change_challenges.code_hmac_key_version 
  IS 'Versao da chave de HMAC usada para gerar o code_hmac.';

COMMENT ON COLUMN private.account_change_challenges.idempotency_key 
  IS 'Chave de idempotencia enviada pelo cliente Flutter para evitar duplicacoes.';

COMMENT ON COLUMN private.account_change_challenges.challenge_state 
  IS 'Estado do ciclo de vida do desafio: active, consumed, expired, cancelled, blocked.';

COMMENT ON COLUMN private.account_change_challenges.delivery_status 
  IS 'Estado de envio do email pelo GAS: pending, sending, sent (envio aceito pelo MailApp, nao garante recebimento), failed.';

COMMENT ON COLUMN private.account_change_challenges.delivery_failure_reason_private 
  IS 'Mensagem de erro privada e sanitizada em caso de falha de envio.';

COMMENT ON COLUMN private.account_change_challenges.send_sequence 
  IS 'Posicao do codigo dentro do ciclo atual (1 para envio inicial, 2 para o primeiro reenvio, 3 para o segundo e ultimo reenvio).';

-- ─────────────────────────────────────────────────────────────────────────
-- 7. RECOMENDAÇÕES E DIRETRIZES FUTURAS (NÃO IMPLEMENTAR NA MIGRATION)
-- ─────────────────────────────────────────────────────────────────────────

/*
   A. CONTRATO FUTURO, EXPIRAÇÃO E CONCORRÊNCIA DO CICLO (Lógica do Backend):
   -------------------------------------------------------------------------
   A futura função interna privilegiada (RPC / Edge Function), executada sob lock 
   e transação atômica, deverá:
     1. Encontrar o desafio atual e ativo do usuário e finalidade específicos.
     2. Preservar o cycle_id nos reenvios (send_sequence = 2 ou 3) pertencentes ao mesmo ciclo.
     3. Incrementar a send_sequence somente depois de um envio aceito pelo MailApp (delivery_status = 'sent').
     4. Reutilizar o mesmo cycle_id e a mesma posição send_sequence após uma falha de envio 
        (delivery_status = 'failed' ou challenge_state = 'cancelled'), pois registros failed/cancelled 
        não consomem a oportunidade na sequência do ciclo.
     5. Consultar o cooldown_until do terceiro envio aceito anterior (send_sequence = 3, delivery_status = 'sent') 
        do usuário ou do destino hmac na tabela de ciclos.
     6. Iniciar um novo cycle_id (gerando um novo UUID) apenas quando now() >= cooldown_until do ciclo anterior.
     7. Impedir de forma estrita a existência de dois ciclos concorrentes ativos ou em andamento 
        (com closed_at IS NULL) para o mesmo usuário e finalidade.
     8. Aplicar limites rigorosos tanto por usuário quanto por destino (destination_hmac) para evitar 
        que a troca de e-mail seja utilizada como forma de burlar as cotas e o cooldown estabelecido.
     9. Localizar e marcar qualquer desafio ativo vencido (now() >= expires_at) como challenge_state = 'expired'
        e preencher expired_at = expires_at antes de criar outro.
     10. Nenhuma tentativa de envio de e-mail (GAS) deve ser iniciada quando now() >= expires_at (validação atômica).
         Uma entrega iniciada antes do vencimento pode terminar após ele, mas novos envios são proibidos.
     11. Validar e consumir o desafio somente se:
         - challenge_state = 'active';
         - delivery_status = 'sent';
         - now() < expires_at;
         - attempts < max_attempts;
         - consumed_at IS NULL.
     12. Utilizar bloqueio pessimista (SELECT ... FOR UPDATE) ou cláusulas condicionais no UPDATE 
         para impedir race conditions e consumo duplo do OTP.
     13. Sequência do ciclo e cooldown:
         - Sequência 1 = envio inicial;
         - Sequência 2 = primeiro reenvio;
         - Sequência 3 = segundo e último reenvio;
         - Depois do terceiro código expirar (ou seja, expires_at do desafio correspondente a send_sequence = 3),
           inicia-se a contagem de 1 hora de cooldown, o qual é persistido em cycle.cooldown_until (expires_at + 1h).
         - Um novo ciclo só pode ser criado quando now() >= cooldown_until e o ciclo anterior for fechado
           (definindo closed_at = now() ou outro timestamp apropriado) na mesma transação.

   B. CRIPTOGRAFIA E SEGURANÇA DOS DADOS (Parâmetros da Edge Function):
   -------------------------------------------------------------------------
     1. Algoritmo de Criptografia do e-mail destino:
         - AES-256-GCM (WebCrypto API).
         - Nonce recomendado: exatamente 12 bytes.
         - Auth Tag recomendada: exatamente 16 bytes (128 bits).
         - Armazenamento em strings base64url sem padding no banco de dados.
         - A Edge Function deve separar fisicamente o ciphertext e a tag 
           ao serializar/desserializar a chave usando a WebCrypto.
     2. Proteção dos Hashes:
         - destination_hmac e code_hmac devem usar domain separation (separação de domínios)
           para evitar ataques de reutilização de hash (re-keying / cross-protocol reuse).
         - Nunca calcular o HMAC de dados brutos sem aplicar um prefixo do escopo
           específico (ex: 'conectea:email_change:code:' + code).

   C. RESTAURAÇÃO DE SESSÃO DO TITULAR APÓS FECHAR O APP:
   -------------------------------------------------------------------------
   A futura API de consulta do Flutter deverá retornar:
     - challenge_state;
     - delivery_status (público transformado);
     - server_now (timestamp oficial do servidor);
     - expires_at;
     - resend_available_at;
     - cooldown_until; (obtido a partir do ciclo ativo associado)
     - send_sequence;
     - quantidade conceitual de envios restantes.
   Não expor em hipótese alguma destination_hmac, code_hmac, ciphertext, 
   nonce, auth_tag, user_id ou o motivo de falha privado.
   O controle visual do contador de reenvios do Flutter é apenas estético;
   a integridade e validação temporal permanecem rígidas no lado do servidor.
*/
