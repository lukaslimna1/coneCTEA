-- =========================================================================
-- ConeCTEA — Cobertura Anual e Calendário Oficial de Feriados de 2026 a 2035
--
-- MIGRATION: 20260613020000_load_account_change_holidays_2026_and_coverage_v1.sql
-- OBJETIVO:
--   1. Criar a tabela privada de cobertura anual do calendário de feriados.
--   2. Criar trigger de atualizações automáticas de updated_at para a cobertura.
--   3. Criar a função interna de validação de ano utilizável (complete ou reviewed).
--   4. Substituir a função de prazo do titular para incluir proteção fail-closed sobre ano não utilizável.
--   5. Carregar set-based os feriados nacionais, estadual e municipal fixos de 2026 a 2035.
--   6. Carregar os feriados móveis materializados de 2026 a 2035.
--   7. Registrar a cobertura para 2026 (reviewed) e de 2027 a 2035 (complete).
--
-- STATUS: Criação local da migration para auditoria. Não aplicada remotamente.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. TABELA DE COBERTURA ANUAL (SCHEMA PRIVATE)
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE private.conectea_operational_holiday_year_coverage (
  calendar_year integer PRIMARY KEY,
  status text NOT NULL,
  source_reference text NOT NULL,
  reviewed_at timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chk_conectea_coverage_year CHECK (calendar_year BETWEEN 2000 AND 2100),
  CONSTRAINT chk_conectea_coverage_status CHECK (status IN ('incomplete', 'complete', 'reviewed')),
  CONSTRAINT chk_conectea_coverage_reviewed CHECK (status <> 'reviewed' OR reviewed_at IS NOT NULL)
);

COMMENT ON TABLE private.conectea_operational_holiday_year_coverage IS 'Tabela privada de auditoria da cobertura anual de feriados operacionais.';

-- Revogar acesso direto por padrão para a tabela privada
REVOKE ALL ON TABLE private.conectea_operational_holiday_year_coverage FROM PUBLIC, anon, authenticated;

-- Criar a trigger associando à função de atualização existente no schema private
CREATE TRIGGER trg_conectea_operational_holiday_year_coverage_updated_at
  BEFORE UPDATE ON private.conectea_operational_holiday_year_coverage
  FOR EACH ROW
  EXECUTE FUNCTION private.conectea_set_operational_holidays_updated_at();

-- ─────────────────────────────────────────────────────────────────────────
-- 2. FUNÇÃO INTERNA — VERIFICAÇÃO DE ANO UTILIZÁVEL
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_is_account_change_holiday_year_usable_v1(
  p_year integer
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_status text;
BEGIN
  IF p_year IS NULL THEN
    RAISE EXCEPTION 'p_year cannot be null' USING ERRCODE = '22004';
  END IF;

  -- Buscar status de cobertura do ano informado
  SELECT status INTO v_status
  FROM private.conectea_operational_holiday_year_coverage
  WHERE calendar_year = p_year;

  IF v_status IS NULL THEN
    RETURN false;
  END IF;

  -- Retorna true apenas se o ano estiver completo ou revisado
  RETURN v_status IN ('complete', 'reviewed');
END;
$$;

COMMENT ON FUNCTION public.conectea_is_account_change_holiday_year_usable_v1(integer)
  IS 'Verifica se o ano civil informado é utilizável para contagem de prazos operacionais (status complete ou reviewed).';

-- Revogar execução pública
REVOKE ALL ON FUNCTION public.conectea_is_account_change_holiday_year_usable_v1(integer) FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 3. PRAZO DO TITULAR (10 DIAS ÚTEIS — COM PROTEÇÃO FAIL-CLOSED)
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
  v_current_year integer;
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

    -- Extrair o ano civil da data analisada
    v_current_year := EXTRACT(year FROM v_current_date)::integer;

    -- Proteção fail-closed: se o ano civil não estiver marcado como utilizável, interromper o cálculo
    IF NOT public.conectea_is_account_change_holiday_year_usable_v1(v_current_year) THEN
      RAISE EXCEPTION 'Calendário operacional indisponível para o período informado.' USING ERRCODE = '22000';
    END IF;

    -- Se for dia útil operacional (segunda a sexta, excluindo feriados cadastrados), incrementar contador
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
  IS 'Calcula o limite exclusivo (início do dia seguinte ao último permitido) do prazo do titular de 10 dias úteis operacionais sob o fuso de America/Sao_Paulo, com verificação de usabilidade anual.';

-- Revogar execução direta
REVOKE ALL ON FUNCTION public.conectea_account_change_holder_deadline_v1(timestamptz) FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 4. CARGA OFICIAL DE FERIADOS LEGAIS FIXOS (GERAÇÃO SET-BASED 2026 A 2035)
-- ─────────────────────────────────────────────────────────────────────────

INSERT INTO private.conectea_operational_holidays (holiday_date, name, scope, holiday_type, source_reference)
SELECT
  (y.year || '-' || f.day_month)::date AS holiday_date,
  f.name,
  f.scope,
  'fixed'::text AS holiday_type,
  f.source_reference
FROM (
  SELECT generate_series(2026, 2035) AS year
) y
CROSS JOIN (
  VALUES
    -- Nacionais Fixos (9 registros por ano)
    ('01-01', 'Confraternização Universal', 'national', 'Lei Federal nº 662/1949 e Lei Federal nº 10.607/2002'),
    ('04-21', 'Tiradentes', 'national', 'Lei Federal nº 662/1949 e Lei Federal nº 10.607/2002'),
    ('05-01', 'Dia do Trabalho', 'national', 'Lei Federal nº 662/1949 e Lei Federal nº 10.607/2002'),
    ('09-07', 'Independência do Brasil', 'national', 'Lei Federal nº 662/1949 e Lei Federal nº 10.607/2002'),
    ('10-12', 'Nossa Senhora Aparecida', 'national', 'Lei Federal nº 6.802/1980'),
    ('11-02', 'Finados', 'national', 'Lei Federal nº 662/1949 e Lei Federal nº 10.607/2002'),
    ('11-15', 'Proclamação da República', 'national', 'Lei Federal nº 662/1949 e Lei Federal nº 10.607/2002'),
    ('11-20', 'Dia Nacional de Zumbi e da Consciência Negra', 'national', 'Lei Federal nº 14.759/2023'),
    ('12-25', 'Natal', 'national', 'Lei Federal nº 662/1949 e Lei Federal nº 10.607/2002'),
    -- Estadual SP Fixo (1 registro por ano)
    ('07-09', 'Revolução Constitucionalista de 1932', 'state_sp', 'Lei Estadual SP nº 9.497/1997'),
    -- Municipal Bauru Fixo (1 registro por ano)
    ('08-01', 'Aniversário de Bauru', 'municipal_bauru', 'Lei Municipal de Bauru nº 4.735/2001')
) f(day_month, name, scope, source_reference);

-- ─────────────────────────────────────────────────────────────────────────
-- 5. CARGA OFICIAL DE FERIADOS LEGAIS MÓVEIS (MATERIALIZADOS 2026 A 2035)
-- ─────────────────────────────────────────────────────────────────────────

INSERT INTO private.conectea_operational_holidays (holiday_date, name, scope, holiday_type, source_reference)
VALUES
  -- Paixão de Cristo (national / movable — 10 registros)
  ('2026-04-03'::date, 'Paixão de Cristo', 'national', 'movable', 'Lei Federal nº 9.093/1995 e Portaria MGI nº 11.460/2025'),
  ('2027-03-26'::date, 'Paixão de Cristo', 'national', 'movable', 'Lei Federal nº 9.093/1995'),
  ('2028-04-14'::date, 'Paixão de Cristo', 'national', 'movable', 'Lei Federal nº 9.093/1995'),
  ('2029-03-30'::date, 'Paixão de Cristo', 'national', 'movable', 'Lei Federal nº 9.093/1995'),
  ('2030-04-19'::date, 'Paixão de Cristo', 'national', 'movable', 'Lei Federal nº 9.093/1995'),
  ('2031-04-11'::date, 'Paixão de Cristo', 'national', 'movable', 'Lei Federal nº 9.093/1995'),
  ('2032-03-26'::date, 'Paixão de Cristo', 'national', 'movable', 'Lei Federal nº 9.093/1995'),
  ('2033-04-15'::date, 'Paixão de Cristo', 'national', 'movable', 'Lei Federal nº 9.093/1995'),
  ('2034-04-07'::date, 'Paixão de Cristo', 'national', 'movable', 'Lei Federal nº 9.093/1995'),
  ('2035-03-23'::date, 'Paixão de Cristo', 'national', 'movable', 'Lei Federal nº 9.093/1995'),

  -- Corpus Christi (municipal_bauru / movable — 10 registros)
  ('2026-06-04'::date, 'Corpus Christi', 'municipal_bauru', 'movable', 'Lei Municipal de Bauru nº 4.735/2001 e Decreto Municipal de Bauru nº 19.159/2025'),
  ('2027-05-27'::date, 'Corpus Christi', 'municipal_bauru', 'movable', 'Lei Municipal de Bauru nº 4.735/2001'),
  ('2028-06-15'::date, 'Corpus Christi', 'municipal_bauru', 'movable', 'Lei Municipal de Bauru nº 4.735/2001'),
  ('2029-05-31'::date, 'Corpus Christi', 'municipal_bauru', 'movable', 'Lei Municipal de Bauru nº 4.735/2001'),
  ('2030-06-20'::date, 'Corpus Christi', 'municipal_bauru', 'movable', 'Lei Municipal de Bauru nº 4.735/2001'),
  ('2031-06-12'::date, 'Corpus Christi', 'municipal_bauru', 'movable', 'Lei Municipal de Bauru nº 4.735/2001'),
  ('2032-05-27'::date, 'Corpus Christi', 'municipal_bauru', 'movable', 'Lei Municipal de Bauru nº 4.735/2001'),
  ('2033-06-16'::date, 'Corpus Christi', 'municipal_bauru', 'movable', 'Lei Municipal de Bauru nº 4.735/2001'),
  ('2034-06-08'::date, 'Corpus Christi', 'municipal_bauru', 'movable', 'Lei Municipal de Bauru nº 4.735/2001'),
  ('2035-05-24'::date, 'Corpus Christi', 'municipal_bauru', 'movable', 'Lei Municipal de Bauru nº 4.735/2001');

-- ─────────────────────────────────────────────────────────────────────────
-- 6. MARCAÇÃO DE COBERTURA REVISADA E COMPLETA (2026 A 2035)
-- ─────────────────────────────────────────────────────────────────────────

-- Ano de 2026 (reviewed)
INSERT INTO private.conectea_operational_holiday_year_coverage (calendar_year, status, reviewed_at, source_reference)
VALUES (
  2026,
  'reviewed',
  now(),
  'Compilado oficial federal (Leis 662/1949, 10.607/2002, 6.802/1980, 14.759/2023, 9.093/1995 e Portaria MGI 11.460/2025), estadual (Lei SP 9.497/1997) e municipais de Bauru (Lei 4.735/2001 e Decreto 19.159/2025).'
);

-- Anos de 2027 a 2035 (complete)
INSERT INTO private.conectea_operational_holiday_year_coverage (calendar_year, status, reviewed_at, source_reference)
SELECT
  year,
  'complete'::text AS status,
  NULL::timestamptz AS reviewed_at,
  'Feriados fixos federais (Leis 662/1949, 10.607/2002, 6.802/1980, 14.759/2023), estaduais (Lei SP 9.497/1997) e municipais de Bauru (Lei 4.735/2001) gerados set-based. Feriados móveis calculados e materializados. Revisão administrativa anual pendente.'::text AS source_reference
FROM generate_series(2027, 2035) AS year;
