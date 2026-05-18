-- Migration: Funções para Prazos Administrativos em Dias Úteis Operacionais (Frente 26H.3-FIX.1)
-- Fuso oficial: America/Sao_Paulo
-- Dias úteis operacionais: segunda a sexta, ignorando sábados, domingos e sem considerar feriados nesta etapa.

-- 1. Soma dias úteis operacionais a partir do dia seguinte à data inicial
CREATE OR REPLACE FUNCTION public.conectea_add_business_days(
  p_start_date date,
  p_business_days integer
)
RETURNS date
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_current_date date := p_start_date;
  v_days_added integer := 0;
  v_dow integer;
BEGIN
  -- Validação dos prazos de produto exigidos pelo ConeCTEA
  IF p_business_days NOT IN (7, 15, 30) THEN
    RAISE EXCEPTION 'Quantidade de dias úteis inválida. Deve ser 7, 15 ou 30.';
  END IF;

  -- Começa a contar a partir do próximo dia
  WHILE v_days_added < p_business_days LOOP
    v_current_date := v_current_date + 1;
    -- EXTRACT(isodow FROM date) retorna: 1 (segunda) a 7 (domingo)
    v_dow := EXTRACT(isodow FROM v_current_date);
    IF v_dow BETWEEN 1 AND 5 THEN
      v_days_added := v_days_added + 1;
    END IF;
  END LOOP;

  RETURN v_current_date;
END;
$$;

-- 2. Gera o expires_at server-side no início do dia civil em America/Sao_Paulo convertido para timestamptz/UTC
CREATE OR REPLACE FUNCTION public.conectea_admin_deadline(
  p_business_days integer
)
RETURNS timestamptz
LANGUAGE sql
SECURITY INVOKER
AS $$
  SELECT (public.conectea_add_business_days(public.conectea_project_today(), p_business_days)::timestamp AT TIME ZONE 'America/Sao_Paulo');
$$;

-- 3. Verifica se o prazo administrativo está vencido sob a regra de data civil
-- O vencimento ocorre apenas a partir do dia civil seguinte ao expires_at em America/Sao_Paulo
CREATE OR REPLACE FUNCTION public.conectea_is_admin_deadline_expired(
  p_expires_at timestamptz
)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
AS $$
  SELECT public.conectea_project_today() > (p_expires_at AT TIME ZONE 'America/Sao_Paulo')::date;
$$;

-- 4. Controle explícito de privilégios (Grants e Revokes)
REVOKE EXECUTE ON FUNCTION public.conectea_add_business_days(date, integer) FROM public;
REVOKE EXECUTE ON FUNCTION public.conectea_add_business_days(date, integer) FROM anon;
GRANT EXECUTE ON FUNCTION public.conectea_add_business_days(date, integer) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.conectea_admin_deadline(integer) FROM public;
REVOKE EXECUTE ON FUNCTION public.conectea_admin_deadline(integer) FROM anon;
GRANT EXECUTE ON FUNCTION public.conectea_admin_deadline(integer) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.conectea_is_admin_deadline_expired(timestamptz) FROM public;
REVOKE EXECUTE ON FUNCTION public.conectea_is_admin_deadline_expired(timestamptz) FROM anon;
GRANT EXECUTE ON FUNCTION public.conectea_is_admin_deadline_expired(timestamptz) TO authenticated;
