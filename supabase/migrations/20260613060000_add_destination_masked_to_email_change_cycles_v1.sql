-- =========================================================================
-- ConeCTEA — Adição de Destino Mascarado ao Ciclo de Alterações
--
-- MIGRATION: 20260613060000_add_destination_masked_to_email_change_cycles_v1.sql
-- OBJETIVO:
--   1. Adicionar o campo destination_masked à tabela private.account_change_challenge_cycles.
--   2. Garantir integridade do campo com constraint de tamanho e btrim.
--   3. Documentar decisões arquiteturais e regras de segurança associadas.
--
-- STATUS: Criação local da migration para auditoria. Não aplicada remotamente neste turno.
-- =========================================================================

-- Adiciona a coluna destination_masked na tabela privada de ciclos
ALTER TABLE private.account_change_challenge_cycles
  ADD COLUMN destination_masked text NOT NULL;

-- Constraint de integridade para a coluna destination_masked
ALTER TABLE private.account_change_challenge_cycles
  ADD CONSTRAINT chk_conectea_cycle_destination_masked CHECK (
    destination_masked IS NOT NULL
    AND destination_masked = btrim(destination_masked)
    AND destination_masked <> ''
    AND length(destination_masked) <= 254
  );

-- Comentário explicativo na coluna destination_masked
COMMENT ON COLUMN private.account_change_challenge_cycles.destination_masked IS 
  'Contem somente a representacao mascarada do novo email. Nao contem o email completo. Pertence ao ciclo privado pre-protocolo. Sera copiado para public.account_change_requests.new_value_masked na finalizacao atomica. Nao pode ser exposto diretamente ao Flutter por leitura de tabela.';

-- ─────────────────────────────────────────────────────────────────────────
-- DECISÕES ARQUITETURAIS (APENAS DOCUMENTAÇÃO)
-- ─────────────────────────────────────────────────────────────────────────
/*
   A. COMPORTAMENTO FUTURO DA EDGE FUNCTION E BANCO:
   --------------------------------------------------
   1. destination_masked será calculado e formatado na Edge Function (ex: "l***s@domain.com") 
      junto da normalização do e-mail em minúsculas e sem espaços.
   2. destination_hmac e destination_masked devem representar semanticamente o mesmo destino normalizado.
   3. A finalização transacional (ao validar o OTP com sucesso) copiará de forma atômica:
      - destination_masked do ciclo para public.account_change_requests.new_value_masked.
      - destination_hmac do ciclo para public.account_change_requests.new_value_hmac.
      - Os metadados criptográficos (ciphertext, nonce, auth_tag, algoritmo, versões) do ciclo 
        para a tabela privada de payloads (private.account_change_secure_payloads).
   4. Não será necessário descriptografar nada no banco para a criação do protocolo de carência.
   5. O Flutter nunca recebe o e-mail completo, apenas lê o valor mascarado de requests quando o protocolo for criado.
*/
