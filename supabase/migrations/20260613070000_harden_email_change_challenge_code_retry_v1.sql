-- =========================================================================
-- ConeCTEA — Hardening do OTP Criptografado para Retry de Envio
--
-- MIGRATION: 20260613070000_harden_email_change_challenge_code_retry_v1.sql
-- OBJETIVO:
--   1. Adicionar campos temporários para OTP criptografado à tabela private.account_change_challenges.
--   2. Garantir integridade por delivery_status (pending/sending vs sent/failed).
--   3. Garantir consistência all-or-none e impedir estados UNKNOWN.
--   4. Validar formato base64url sem padding dos campos criptográficos.
--   5. Documentar diretrizes de criptografia, ciclo de vida e tratamento de timeout.
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
-- 2. ADIÇÃO DOS CAMPOS CRIPTOGRÁFICOS TEMPORÁRIOS DO OTP
-- ─────────────────────────────────────────────────────────────────────────

ALTER TABLE private.account_change_challenges
  ADD COLUMN code_ciphertext text NULL,
  ADD COLUMN code_nonce text NULL,
  ADD COLUMN code_auth_tag text NULL,
  ADD COLUMN code_encryption_algorithm text NULL,
  ADD COLUMN code_encryption_key_version integer NULL;

-- ─────────────────────────────────────────────────────────────────────────
-- 3. CONTRATO CONDICIONAL E COERÊNCIA ALL-OR-NONE POR DELIVERY_STATUS
-- ─────────────────────────────────────────────────────────────────────────

ALTER TABLE private.account_change_challenges
  ADD CONSTRAINT chk_conectea_challenge_otp_encryption_retry CHECK (
    (
      (
        delivery_status IN ('pending', 'sending') AND
        code_ciphertext IS NOT NULL AND
        code_nonce IS NOT NULL AND
        code_auth_tag IS NOT NULL AND
        code_encryption_algorithm IS NOT NULL AND
        code_encryption_key_version IS NOT NULL AND

        -- Normalização e preenchimento
        code_ciphertext = btrim(code_ciphertext) AND code_ciphertext <> '' AND
        code_nonce = btrim(code_nonce) AND code_nonce <> '' AND
        code_auth_tag = btrim(code_auth_tag) AND code_auth_tag <> '' AND
        code_encryption_algorithm = btrim(code_encryption_algorithm) AND

        -- Algoritmo e chave
        code_encryption_algorithm = 'aes-256-gcm' AND
        code_encryption_key_version > 0 AND

        -- Formato base64url sem padding
        code_ciphertext ~ '^[A-Za-z0-9_-]+$' AND
        code_nonce ~ '^[A-Za-z0-9_-]{16}$' AND
        code_auth_tag ~ '^[A-Za-z0-9_-]{22}$'
      ) OR (
        delivery_status IN ('sent', 'failed') AND
        code_ciphertext IS NULL AND
        code_nonce IS NULL AND
        code_auth_tag IS NULL AND
        code_encryption_algorithm IS NULL AND
        code_encryption_key_version IS NULL
      )
    ) IS TRUE
  );

-- ─────────────────────────────────────────────────────────────────────────
-- 4. COMENTÁRIOS E DOCUMENTAÇÃO DOS CAMPOS
-- ─────────────────────────────────────────────────────────────────────────

COMMENT ON COLUMN private.account_change_challenges.code_ciphertext IS
  'Valor criptografado temporario do OTP (AES-GCM) para permitir reenvio. Deve ser apagado apos sent ou failed. Nunca contem o OTP puro. Nao retornar ao cliente.';

COMMENT ON COLUMN private.account_change_challenges.code_nonce IS
  'Nonce de criptografia temporario do OTP para permitir reenvio. Deve ser apagado apos sent ou failed. Nunca contem o OTP puro. Nao retornar ao cliente.';

COMMENT ON COLUMN private.account_change_challenges.code_auth_tag IS
  'Tag de autenticacao de criptografia temporaria do OTP para permitir reenvio. Deve ser apagado apos sent ou failed. Nunca contem o OTP puro. Nao retornar ao cliente.';

COMMENT ON COLUMN private.account_change_challenges.code_encryption_algorithm IS
  'Algoritmo temporario de criptografia do OTP (aes-256-gcm). Deve ser apagado apos sent ou failed. Nunca contem o OTP puro. Nao retornar ao cliente.';

COMMENT ON COLUMN private.account_change_challenges.code_encryption_key_version IS
  'Versao da chave de criptografia do OTP. Deve ser apagado apos sent ou failed. Nunca contem o OTP puro. Nao retornar ao cliente.';

-- ─────────────────────────────────────────────────────────────────────────
-- 5. CRIPTOGRAFIA, SEGURANÇA E CICLO DE VIDA FUTURO (APENAS DOCUMENTAÇÃO)
-- ─────────────────────────────────────────────────────────────────────────
/*
   A. DIRETRIZES DE CRIPTOGRAFIA DO OTP:
   -------------------------------------
   1. O OTP futuro será aleatório, gerado de forma segura no backend (Edge Function).
   2. O OTP será criptografado utilizando o algoritmo simétrico AES-256-GCM.
   3. O nonce representa exatamente 12 bytes, que em formato base64url sem padding possui exatamente 16 caracteres.
   4. A tag de autenticação (auth tag) representa exatamente 16 bytes, que em formato base64url sem padding possui exatamente 22 caracteres.
   5. A serialização no banco de dados deve utilizar o formato base64url sem padding.
   6. O ciphertext possui comprimento variável e formato base64url sem padding, e a auth tag será persistida separadamente.
   7. A validação de formato e comprimento por expressões regulares não substitui a integridade e autenticação do AES-GCM.
   8. O campo code_encryption_key_version identifica a versão da chave simétrica usada na cifragem.
   9. A chave de criptografia deve ser rigorosamente separada e independente da chave de HMAC (code_hmac_key_version).
   10. O nonce nunca pode ser reutilizado sob uma mesma chave de criptografia.
   11. A Edge Function será a única responsável por executar as operações de criptografia e descriptografia real;
       nenhuma criptografia ou chave será exposta ou processada diretamente no PostgreSQL.

   B. CICLO DE VIDA FUTURO E TRATAMENTO DE TIMEOUT / RETRIES (Lógica do Backend):
   -----------------------------------------------------------------------------
   1. Criação (Estado pending):
      - Gerar OTP aleatório.
      - Calcular code_hmac e persistir junto à chave de HMAC.
      - Criptografar o OTP puro gerando code_ciphertext, code_nonce e code_auth_tag.
      - Persistir o desafio em estado pending com todos os campos de criptografia preenchidos.

   2. Início de envio (Estado sending):
      - Mudar delivery_status para 'sending'.
      - Preservar o material criptografado temporário para reenvios em caso de falha transitória ou timeout.
      - Incrementar delivery_attempts e registrar last_delivery_attempt_at.

   3. Timeout / Perda de Resposta (Mitigação de falhas e idempotência):
      - Caso a Edge Function sofra timeout ou perca a resposta do GAS, o status permanece como 'sending'.
      - Não marcar o desafio como 'failed'.
      - Não gerar outro OTP.
      - A Edge Function deve descriptografar o OTP armazenado in code_ciphertext e reenviar exatamente
        o mesmo código para o GAS com o mesmo challenge_id.
      - O GAS futuro deverá tratar a chamada de forma idempotente.

   4. Envio Confirmado (Estado sent):
      - Na mesma transação em que muda delivery_status para 'sent':
        - Preencher sent_at, expires_at (sent_at + 15 minutos) e resend_available_at.
        - Apagar (definir como NULL) os cinco campos criptografados temporários do OTP:
          code_ciphertext, code_nonce, code_auth_tag, code_encryption_algorithm e code_encryption_key_version.

   5. Falha Definitiva (Estado failed):
      - Na mesma transação que muda delivery_status para 'failed' e challenge_state para 'cancelled':
        - Preencher failed_at, cancelled_at (onde cancelled_at = failed_at).
        - Registrar o motivo privado de falha sanitizado em delivery_failure_reason_private.
        - Apagar (definir como NULL) os cinco campos criptografados temporários do OTP:
          code_ciphertext, code_nonce, code_auth_tag, code_encryption_algorithm e code_encryption_key_version.
        - Preservar intactos os campos code_hmac e code_hmac_key_version, além do motivo de falha e timestamps.

   C. SEGURANÇA E INTEGRIDADE DO HMAC:
   -----------------------------------
   1. Os campos code_hmac (text NOT NULL) e code_hmac_key_version (integer NOT NULL) são preservados integralmente.
   2. O HMAC continua sendo a única representação para validar o código digitado pelo usuário após a entrega.
   3. A validação futura somente poderá ocorrer sob as condições estritas:
      - challenge_state = 'active'
      - delivery_status = 'sent'
      - now() < expires_at
      - attempts < max_attempts
   4. Não implementar funções ou lógica de validação SQL nesta etapa.
*/
