-- =========================================================================
-- ConeCTEA — Fundação de Prazos e Calendário Operacional para Alterações de Conta
--
-- MIGRATION: 20260613010000_create_account_change_deadline_foundation_v1.sql
-- OBJETIVO:
--   1. Criar a tabela privada de feriados operacionais com chave primária composta.
--   2. Criar a trigger de atualizações automáticas de updated_at para os feriados.
--   3. Criar a função de verificação de dia útil.
--   4. Criar as funções de cálculo de prazo administrativo (dias corridos) e do titular (dias úteis) com limite exclusivo.
--   5. Criar as funções de verificação de atraso/expiração baseadas em >= e limite exclusivo.
--
-- STATUS: Criação local da migration para auditoria. Não aplicada remotamente.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. TABELA OPERACIONAL DE FERIADOS (SCHEMA PRIVATE)
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE private.conectea_operational_holidays (
  holiday_date date NOT NULL,
  name text NOT NULL,
  scope text NOT NULL,
  holiday_type text NOT NULL,
  source_reference text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (holiday_date, scope),
  CONSTRAINT chk_conectea_holiday_scope CHECK (scope IN ('national', 'state_sp', 'municipal_bauru')),
  CONSTRAINT chk_conectea_holiday_type CHECK (holiday_type IN ('fixed', 'movable', 'exceptional'))
);

COMMENT ON TABLE private.conectea_operational_holidays IS 'Calendário de feriados operacionais do ConeCTEA para contagem de prazos úteis.';

-- Revogar acesso direto por padrão para a tabela privada
REVOKE ALL ON TABLE private.conectea_operational_holidays FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. TRIGGER DE ATUALIZAÇÃO AUTOMÁTICA (UPDATED_AT)
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION private.conectea_set_operational_holidays_updated_at()
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

COMMENT ON FUNCTION private.conectea_set_operational_holidays_updated_at()
  IS 'Função interna de trigger para atualizar o timestamp updated_at dos feriados.';

-- Revogar execução da função de trigger
REVOKE ALL ON FUNCTION private.conectea_set_operational_holidays_updated_at() FROM PUBLIC, anon, authenticated;

-- Criar a trigger na tabela de feriados operacionais
CREATE TRIGGER trg_conectea_operational_holidays_updated_at
  BEFORE UPDATE ON private.conectea_operational_holidays
  FOR EACH ROW
  EXECUTE FUNCTION private.conectea_set_operational_holidays_updated_at();

-- ─────────────────────────────────────────────────────────────────────────
-- 3. FUNÇÃO INTERNA — VERIFICAÇÃO DE DIA ÚTIL
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_is_account_change_workday_v1(
  p_date date
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_dow integer;
  v_is_holiday boolean;
BEGIN
  -- EXTRACT(isodow FROM date) retorna: 1 (segunda) a 7 (domingo)
  v_dow := EXTRACT(isodow FROM p_date);

  -- Se for sábado (6) ou domingo (7), não é dia útil
  IF v_dow IN (6, 7) THEN
    RETURN false;
  END IF;

  -- Verifica se a data civil está na tabela de feriados operacionais (independente do escopo)
  SELECT EXISTS (
    SELECT 1
    FROM private.conectea_operational_holidays
    WHERE holiday_date = p_date
  ) INTO v_is_holiday;

  IF v_is_holiday THEN
    RETURN false;
  END IF;

  RETURN true;
END;
$$;

COMMENT ON FUNCTION public.conectea_is_account_change_workday_v1(date)
  IS 'Verifica se uma data civil é dia útil operacional, ignorando fins de semana e feriados cadastrados.';

-- Revogar execução pública da função interna
REVOKE ALL ON FUNCTION public.conectea_is_account_change_workday_v1(date) FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 4. CÁLCULO DO PRAZO ADMINISTRATIVO (10 DIAS CORRIDOS — LIMITE EXCLUSIVO)
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_account_change_admin_deadline_v1(
  p_started_at timestamptz
)
RETURNS timestamptz
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_start_date date;
  v_last_allowed_date date;
  v_deadline_exclusive_at timestamptz;
BEGIN
  IF p_started_at IS NULL THEN
    RAISE EXCEPTION 'p_started_at cannot be null' USING ERRCODE = '22004';
  END IF;

  -- Converter o timestamp inicial para a data civil na timezone America/Sao_Paulo
  v_start_date := (p_started_at AT TIME ZONE 'America/Sao_Paulo')::date;

  -- Somar exatamente 10 dias corridos (a contagem inicia no dia civil seguinte, não contando o dia de início)
  v_last_allowed_date := v_start_date + 10;

  -- Limite exclusivo: início do dia civil seguinte (last_allowed_date + 1) às 00:00:00 em America/Sao_Paulo
  v_deadline_exclusive_at := ((v_last_allowed_date + 1)::timestamp AT TIME ZONE 'America/Sao_Paulo');

  RETURN v_deadline_exclusive_at;
END;
$$;

COMMENT ON FUNCTION public.conectea_account_change_admin_deadline_v1(timestamptz)
  IS 'Calcula o limite exclusivo (início do dia seguinte ao último permitido) do prazo administrativo de 10 dias corridos sob o fuso de America/Sao_Paulo.';

-- Revogar execução direta
REVOKE ALL ON FUNCTION public.conectea_account_change_admin_deadline_v1(timestamptz) FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 5. CÁLCULO DO PRAZO DO TITULAR (10 DIAS ÚTEIS — LIMITE EXCLUSIVO)
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_account_change_holder_deadline_v1(
  p_started_at timestamptz
)
RETURNS timestamptz
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_start_date date;
  v_current_date date;
  v_workdays_counted integer := 0;
  v_last_allowed_date date;
  v_deadline_exclusive_at timestamptz;
BEGIN
  IF p_started_at IS NULL THEN
    RAISE EXCEPTION 'p_started_at cannot be null' USING ERRCODE = '22004';
  END IF;

  -- Converter o timestamp inicial para a data civil na timezone America/Sao_Paulo
  v_start_date := (p_started_at AT TIME ZONE 'America/Sao_Paulo')::date;
  v_current_date := v_start_date;

  -- Contar exatamente 10 dias úteis, iniciando a verificação no dia civil seguinte
  WHILE v_workdays_counted < 10 LOOP
    v_current_date := v_current_date + 1;
    IF public.conectea_is_account_change_workday_v1(v_current_date) THEN
      v_workdays_counted := v_workdays_counted + 1;
    END IF;
  END LOOP;

  v_last_allowed_date := v_current_date;

  -- Limite exclusivo: início do dia civil seguinte (last_allowed_date + 1) às 00:00:00 em America/Sao_Paulo
  v_deadline_exclusive_at := ((v_last_allowed_date + 1)::timestamp AT TIME ZONE 'America/Sao_Paulo');

  RETURN v_deadline_exclusive_at;
END;
$$;

COMMENT ON FUNCTION public.conectea_account_change_holder_deadline_v1(timestamptz)
  IS 'Calcula o limite exclusivo (início do dia seguinte ao último permitido) do prazo do titular de 10 dias úteis operacionais sob o fuso de America/Sao_Paulo.';

-- Revogar execução direta
REVOKE ALL ON FUNCTION public.conectea_account_change_holder_deadline_v1(timestamptz) FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 6. FUNÇÕES DE VERIFICAÇÃO DE VENCIMENTO / EXCEÇÃO DE ATRASO
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_is_account_change_admin_overdue_v1(
  p_deadline_exclusive_at timestamptz
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = pg_catalog, pg_temp
AS $$
BEGIN
  IF p_deadline_exclusive_at IS NULL THEN
    RAISE EXCEPTION 'p_deadline_exclusive_at cannot be null' USING ERRCODE = '22004';
  END IF;

  -- Retorna se o horário oficial do servidor (now()) atingiu ou passou o limite exclusivo estabelecido
  RETURN now() >= p_deadline_exclusive_at;
END;
$$;

COMMENT ON FUNCTION public.conectea_is_account_change_admin_overdue_v1(timestamptz)
  IS 'Verifica se o prazo administrativo foi ultrapassado baseando-se no limite exclusivo e no relógio do servidor (now() >= deadline).';

-- Revogar execução direta
REVOKE ALL ON FUNCTION public.conectea_is_account_change_admin_overdue_v1(timestamptz) FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_is_account_change_holder_expired_v1(
  p_deadline_exclusive_at timestamptz
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = pg_catalog, pg_temp
AS $$
BEGIN
  IF p_deadline_exclusive_at IS NULL THEN
    RAISE EXCEPTION 'p_deadline_exclusive_at cannot be null' USING ERRCODE = '22004';
  END IF;

  -- Retorna se o horário oficial do servidor (now()) atingiu ou passou o limite exclusivo estabelecido
  RETURN now() >= p_deadline_exclusive_at;
END;
$$;

COMMENT ON FUNCTION public.conectea_is_account_change_holder_expired_v1(timestamptz)
  IS 'Verifica se o prazo do titular expirou baseando-se no limite exclusivo e no relógio do servidor (now() >= deadline).';

-- Revogar execução direta
REVOKE ALL ON FUNCTION public.conectea_is_account_change_holder_expired_v1(timestamptz) FROM PUBLIC, anon, authenticated;
