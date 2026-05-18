-- Migration: Funções para Validade Civil da Carteirinha ConeCTEA (Frente 26H.2-FIX.1)
-- Fuso oficial: America/Sao_Paulo
-- Validade do produto preservada em 1 ano.

-- 1. Retorna o dia civil atual sob o fuso oficial de Bauru/SP (Brasília - America/Sao_Paulo)
CREATE OR REPLACE FUNCTION public.conectea_project_today()
RETURNS date
LANGUAGE sql
SECURITY INVOKER
AS $$
  SELECT (now() AT TIME ZONE 'America/Sao_Paulo')::date;
$$;

-- 2. Calcula a janela de validade da carteirinha digital para 1 ano
-- O issued_at é o início do dia civil atual e valid_until é o início do dia civil atual + 1 ano.
CREATE OR REPLACE FUNCTION public.conectea_digital_card_validity_window(
  OUT issued_at timestamptz,
  OUT valid_until timestamptz
)
LANGUAGE sql
SECURITY INVOKER
AS $$
  SELECT 
    ((now() AT TIME ZONE 'America/Sao_Paulo')::date::timestamp AT TIME ZONE 'America/Sao_Paulo') AS issued_at,
    (((now() AT TIME ZONE 'America/Sao_Paulo')::date + interval '1 year')::timestamp AT TIME ZONE 'America/Sao_Paulo') AS valid_until;
$$;

-- 3. Verifica se a carteirinha está vencida sob a regra de data civil
-- O vencimento ocorre apenas a partir do dia seguinte ao valid_until.
CREATE OR REPLACE FUNCTION public.conectea_is_digital_card_expired(p_valid_until timestamptz)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
AS $$
  SELECT public.conectea_project_today() > (p_valid_until AT TIME ZONE 'America/Sao_Paulo')::date;
$$;

-- 4. Controle explícito de execução (Grants e Revokes)
REVOKE EXECUTE ON FUNCTION public.conectea_project_today() FROM public;
REVOKE EXECUTE ON FUNCTION public.conectea_project_today() FROM anon;
GRANT EXECUTE ON FUNCTION public.conectea_project_today() TO authenticated;

REVOKE EXECUTE ON FUNCTION public.conectea_digital_card_validity_window() FROM public;
REVOKE EXECUTE ON FUNCTION public.conectea_digital_card_validity_window() FROM anon;
GRANT EXECUTE ON FUNCTION public.conectea_digital_card_validity_window() TO authenticated;

REVOKE EXECUTE ON FUNCTION public.conectea_is_digital_card_expired(timestamptz) FROM public;
REVOKE EXECUTE ON FUNCTION public.conectea_is_digital_card_expired(timestamptz) FROM anon;
GRANT EXECUTE ON FUNCTION public.conectea_is_digital_card_expired(timestamptz) TO authenticated;
