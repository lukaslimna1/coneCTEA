-- =========================================================================
-- ConeCTEA — Fundação do Domínio, Schema e RLS para Alterações de Conta
-- 
-- MIGRATION: 20260612190000_harden_account_change_protocol_hex_v1.sql
-- OBJETIVO: Substituir a função de protocolo pelo formato AC-YYYYMMDD-HEX8
--           e adicionar uma restrição de formato CHECK à tabela pública.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. SUBSTITUIÇÃO DA FUNÇÃO DE PROTOCOLO PELO FORMATO AC-YYYYMMDD-HEX8
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.generate_account_change_protocol_v1()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  v_date_str text;
  v_hex_str text;
  v_protocol text;
  v_exists boolean;
BEGIN
  -- Obtém a data oficial na timezone 'America/Sao_Paulo'
  v_date_str := to_char(timezone('America/Sao_Paulo', now()), 'YYYYMMDD');
  
  LOOP
    -- Gera 4 bytes aleatórios seguros e converte para hexadecimal de 8 caracteres em maiúsculas
    v_hex_str := upper(encode(extensions.gen_random_bytes(4), 'hex'));
    v_protocol := 'AC-' || v_date_str || '-' || v_hex_str;
    
    -- Defesa robusta contra colisões (a constraint UNIQUE é a garantia definitiva)
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

COMMENT ON FUNCTION public.generate_account_change_protocol_v1() IS 'Gera protocolos server-side no formato AC-YYYYMMDD-HEX8 criptograficamente seguro, livre de dados pessoais.';

-- ─────────────────────────────────────────────────────────────────────────
-- 2. ADIÇÃO DA CHECK CONSTRAINT DE FORMATO NA TABELA PÚBLICA
-- ─────────────────────────────────────────────────────────────────────────

ALTER TABLE public.account_change_requests
  ADD CONSTRAINT account_change_requests_protocol_format_v1_check
  CHECK (protocol_number ~ '^AC-[0-9]{8}-[A-F0-9]{8}$');
