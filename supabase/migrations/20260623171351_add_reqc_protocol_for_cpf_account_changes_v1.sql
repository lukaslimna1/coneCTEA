-- =========================================================================
-- ConeCTEA — Protocolo REQC para Alteração de CPF
--
-- MIGRATION: 20260623171351_add_reqc_protocol_for_cpf_account_changes_v1.sql
-- OBJETIVO:
--   1. Adaptar a check constraint de formato de protocol_number em public.account_change_requests
--      para permitir tanto o formato legado de e-mail (AC-YYYYMMDD-HEX8) quanto o novo formato de CPF (REQC-YYYY-HEX8).
--   2. Criar a função geradora do protocolo de CPF: public.generate_cpf_change_protocol_v1().
--   3. Atualizar a função do trigger public.handle_account_change_requests_protocol()
--      para despachar o formato de protocolo dinamicamente com base no type ('cpf' -> REQC, outros -> AC).
--
-- MOTIVAÇÃO E JUSTIFICATIVAS:
--   - Compatibilidade de E-mail: O prefixo AC- continua existindo para o fluxo de alteração de e-mail,
--     preservando as auditorias e chaves de negócio preexistentes.
--   - Distinção Visual: O prefixo REQC- é adotado unicamente para o type = 'cpf', permitindo à UI e aos
--     desenvolvedores distinguir instantaneamente o domínio da solicitação no banco e em ambientes autenticados.
--   - Separação de Camadas: Isso mantém a camada de protocolo isolada, testável e sem dependências com
--     reservas, documentos, payloads criptográficos ou RPCs de negócio.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. ADAPTAÇÃO DA CHECK CONSTRAINT DE FORMATO DE PROTOCOLO
-- ─────────────────────────────────────────────────────────────────────────

ALTER TABLE public.account_change_requests
  DROP CONSTRAINT IF EXISTS account_change_requests_protocol_format_v1_check;

ALTER TABLE public.account_change_requests
  ADD CONSTRAINT account_change_requests_protocol_format_v1_check
  CHECK (
    protocol_number ~ '^AC-[0-9]{8}-[A-F0-9]{8}$' OR
    protocol_number ~ '^REQC-[0-9]{4}-[A-F0-9]{8}$'
  );

-- ─────────────────────────────────────────────────────────────────────────
-- 2. CRIAÇÃO DA FUNÇÃO GERADORA: REQC-YYYY-HEX8
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.generate_cpf_change_protocol_v1()
RETURNS text
LANGUAGE plpgsql
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_year_str text;
  v_hex_str text;
  v_protocol text;
  v_exists boolean;
BEGIN
  -- Obtém o ano civil oficial na timezone 'America/Sao_Paulo'
  v_year_str := to_char(timezone('America/Sao_Paulo', now()), 'YYYY');
  
  LOOP
    -- Gera 4 bytes aleatórios seguros e converte para hexadecimal de 8 caracteres em maiúsculas
    v_hex_str := upper(encode(extensions.gen_random_bytes(4), 'hex'));
    v_protocol := 'REQC-' || v_year_str || '-' || v_hex_str;
    
    -- Defesa contra colisões consultando a tabela de solicitações
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

COMMENT ON FUNCTION public.generate_cpf_change_protocol_v1() 
  IS 'Gera protocolos server-side no formato REQC-YYYY-HEX8 de forma segura e livre de dados pessoais.';

-- ─────────────────────────────────────────────────────────────────────────
-- 3. ATUALIZAÇÃO DA FUNÇÃO DO TRIGGER DE PROTOCOLO
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.handle_account_change_requests_protocol()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, pg_temp
AS $$
BEGIN
  -- Preserva o protocolo se já vier preenchido (ex: injeção explícita de testes)
  -- Trata string vazia ou apenas espaços vazios (via btrim) como ausência de protocolo
  IF NEW.protocol_number IS NULL OR btrim(NEW.protocol_number) = '' THEN
    IF NEW.type = 'cpf' THEN
      NEW.protocol_number := public.generate_cpf_change_protocol_v1();
    ELSE
      NEW.protocol_number := public.generate_account_change_protocol_v1();
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_account_change_requests_protocol() 
  IS 'Gerencia a injeção do número de protocolo antes da inserção baseado no tipo da solicitação de alteração.';
