-- =========================================================================
-- ConeCTEA — RPC Segura de Listagem de Revisão de CPF para Admins
--
-- MIGRATION: 20260628011500_create_admin_cpf_change_list_rpc_v1.sql
-- OBJETIVO:
--   1. Criar RPC public.conectea_admin_list_cpf_change_requests_v1() para listagem
--      segura e econômica de solicitações de alteração de CPF.
--   2. Implementar contadores consolidados na mesma chamada com suporte ao filtro agrupado expired_failed.
--   3. Mascarar e minimizar informações sensíveis retornadas.
--   4. Validar permissões de admin_master ou admin_dev server-side.
--   5. Corrigir cálculo de has_document baseado na tabela de payloads seguros privada.
--   6. Normalizar filtros de entrada contra whitelist e remover true fallback acidental.
-- =========================================================================

CREATE OR REPLACE FUNCTION public.conectea_admin_list_cpf_change_requests_v1(
  p_filter text default 'analysis',
  p_search text default null,
  p_limit int default 20,
  p_offset int default 0
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id uuid;
  v_role text;
  v_limit int;
  v_offset int;
  v_filter text;
  v_count_under_review bigint;
  v_count_corrections bigint;
  v_count_completed bigint;
  v_count_confirmation bigint;
  v_count_rejected bigint;
  v_count_cancelled bigint;
  v_count_expired bigint;
  v_count_failed bigint;
  v_count_expired_failed bigint;
  v_count_total bigint;
  v_items_json jsonb;
BEGIN
  -- 1. Exigir usuário autenticado
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Acesso negado: usuário não autenticado.' USING ERRCODE = '42501';
  END IF;

  -- 2. Validar se o usuário é Admin Master ou Admin Dev no servidor
  SELECT role INTO v_role
  FROM public.profiles
  WHERE id = v_user_id;

  IF v_role IS NULL OR v_role NOT IN ('admin_master', 'admin_dev') THEN
    RAISE EXCEPTION 'Acesso negado: privilégios insuficientes.' USING ERRCODE = '42501';
  END IF;

  -- 3. Sanitizar paginação e filtros
  v_limit := COALESCE(p_limit, 20);
  IF v_limit < 1 THEN
    v_limit := 20;
  ELSIF v_limit > 50 THEN
    v_limit := 50;
  END IF;

  v_offset := COALESCE(p_offset, 0);
  IF v_offset < 0 THEN
    v_offset := 0;
  END IF;

  -- Normalizar filtro de entrada para whitelist restrita (previne ELSE true acidental)
  v_filter := lower(trim(COALESCE(p_filter, 'analysis')));
  IF v_filter NOT IN ('analysis', 'corrections', 'completed', 'confirmation', 'rejected', 'cancelled', 'expired_failed', 'expired_or_failed', 'all') THEN
    v_filter := 'analysis';
  END IF;

  -- 4. Obter contadores agregados respeitando a busca (se fornecida)
  SELECT
    count(*) FILTER (WHERE cr.status = 'under_review'::public.account_change_status) AS count_under_review,
    count(*) FILTER (WHERE cr.status IN ('waiting_cpf_correction'::public.account_change_status, 'waiting_document_replacement'::public.account_change_status)) AS count_corrections,
    count(*) FILTER (WHERE cr.status = 'completed'::public.account_change_status) AS count_completed,
    count(*) FILTER (WHERE cr.status = 'waiting_holder_confirmation'::public.account_change_status) AS count_confirmation,
    count(*) FILTER (WHERE cr.status = 'rejected_by_admin'::public.account_change_status) AS count_rejected,
    count(*) FILTER (WHERE cr.status = 'cancelled_by_holder'::public.account_change_status) AS count_cancelled,
    count(*) FILTER (WHERE cr.status = 'expired'::public.account_change_status) AS count_expired,
    count(*) FILTER (WHERE cr.status = 'application_failed'::public.account_change_status) AS count_failed,
    count(*) FILTER (WHERE cr.status IN ('expired'::public.account_change_status, 'application_failed'::public.account_change_status)) AS count_expired_failed,
    count(*) AS count_total
  INTO
    v_count_under_review,
    v_count_corrections,
    v_count_completed,
    v_count_confirmation,
    v_count_rejected,
    v_count_cancelled,
    v_count_expired,
    v_count_failed,
    v_count_expired_failed,
    v_count_total
  FROM public.account_change_requests cr
  LEFT JOIN public.profiles p ON cr.user_id = p.id
  WHERE cr.type = 'cpf'::public.account_change_type
    AND (
      p_search IS NULL OR trim(p_search) = '' OR
      cr.protocol_number ILIKE '%' || trim(p_search) || '%' OR
      p.name ILIKE '%' || trim(p_search) || '%' OR
      COALESCE(p.social_name, '') ILIKE '%' || trim(p_search) || '%' OR
      p.email ILIKE '%' || trim(p_search) || '%'
    );

  -- 5. Obter itens com minimização estrita de dados sensíveis e joins otimizados
  SELECT COALESCE(jsonb_agg(t), '[]'::jsonb) INTO v_items_json
  FROM (
    SELECT
      cr.id,
      cr.protocol_number,
      cr.status,
      cr.created_at,
      cr.updated_at,
      cr.status_changed_at,
      cr.closed_at,
      CASE
        WHEN cr.admin_deadline_exclusive_at IS NULL THEN NULL
        ELSE (cr.admin_deadline_exclusive_at AT TIME ZONE 'America/Sao_Paulo')::date - 1
      END AS admin_deadline_due_date,
      CASE
        WHEN cr.holder_deadline_exclusive_at IS NULL THEN NULL
        ELSE (cr.holder_deadline_exclusive_at AT TIME ZONE 'America/Sao_Paulo')::date - 1
      END AS holder_deadline_due_date,
      CASE
        WHEN cr.status = 'under_review'::public.account_change_status AND cr.admin_deadline_exclusive_at IS NOT NULL AND now() >= cr.admin_deadline_exclusive_at THEN true
        WHEN cr.status IN ('waiting_holder_confirmation'::public.account_change_status, 'waiting_document_replacement'::public.account_change_status, 'waiting_cpf_correction'::public.account_change_status)
             AND cr.holder_deadline_exclusive_at IS NOT NULL AND now() >= cr.holder_deadline_exclusive_at THEN true
        ELSE false
      END AS is_overdue,
      CASE
        WHEN cr.status = 'under_review'::public.account_change_status AND cr.admin_deadline_exclusive_at IS NOT NULL THEN
          ((cr.admin_deadline_exclusive_at AT TIME ZONE 'America/Sao_Paulo')::date - 1) - (now() AT TIME ZONE 'America/Sao_Paulo')::date
        WHEN cr.status IN ('waiting_holder_confirmation'::public.account_change_status, 'waiting_document_replacement'::public.account_change_status, 'waiting_cpf_correction'::public.account_change_status)
             AND cr.holder_deadline_exclusive_at IS NOT NULL THEN
          ((cr.holder_deadline_exclusive_at AT TIME ZONE 'America/Sao_Paulo')::date - 1) - (now() AT TIME ZONE 'America/Sao_Paulo')::date
        ELSE NULL
      END AS remaining_calendar_days,
      EXISTS (
        SELECT 1 
        FROM private.account_change_secure_payloads sp 
        WHERE sp.request_id = cr.id
      ) AS has_document,
      cr.old_value_masked,
      cr.new_value_masked,
      COALESCE(
        split_part(nullif(trim(p.social_name), ''), ' ', 1),
        split_part(nullif(trim(p.name), ''), ' ', 1),
        'Titular'
      ) AS user_first_name,
      CASE
        WHEN p.email IS NULL OR p.email = '' THEN ''
        WHEN position('@' in p.email) = 0 THEN '***'
        ELSE
          CASE
            WHEN length(split_part(p.email, '@', 1)) <= 2 THEN
              substring(split_part(p.email, '@', 1) from 1 for 1) || '***@' || split_part(p.email, '@', 2)
            ELSE
              substring(split_part(p.email, '@', 1) from 1 for 2) || '***@' || split_part(p.email, '@', 2)
          END
      END AS user_email_masked
    FROM public.account_change_requests cr
    LEFT JOIN public.profiles p ON cr.user_id = p.id
    WHERE cr.type = 'cpf'::public.account_change_type
      AND (
        CASE v_filter
          WHEN 'analysis' THEN cr.status = 'under_review'::public.account_change_status
          WHEN 'corrections' THEN cr.status IN ('waiting_cpf_correction'::public.account_change_status, 'waiting_document_replacement'::public.account_change_status)
          WHEN 'completed' THEN cr.status = 'completed'::public.account_change_status
          WHEN 'confirmation' THEN cr.status = 'waiting_holder_confirmation'::public.account_change_status
          WHEN 'rejected' THEN cr.status = 'rejected_by_admin'::public.account_change_status
          WHEN 'cancelled' THEN cr.status = 'cancelled_by_holder'::public.account_change_status
          WHEN 'expired_failed' THEN cr.status IN ('expired'::public.account_change_status, 'application_failed'::public.account_change_status)
          WHEN 'expired_or_failed' THEN cr.status IN ('expired'::public.account_change_status, 'application_failed'::public.account_change_status)
          WHEN 'all' THEN true
        END
      )
      AND (
        p_search IS NULL OR trim(p_search) = '' OR
        cr.protocol_number ILIKE '%' || trim(p_search) || '%' OR
        p.name ILIKE '%' || trim(p_search) || '%' OR
        COALESCE(p.social_name, '') ILIKE '%' || trim(p_search) || '%' OR
        p.email ILIKE '%' || trim(p_search) || '%'
      )
    ORDER BY cr.created_at DESC, cr.id DESC
    LIMIT v_limit
    OFFSET v_offset
  ) t;

  -- 6. Retornar resposta JSONB consolidada
  RETURN jsonb_build_object(
    'items', v_items_json,
    'counts', jsonb_build_object(
      'analysis', v_count_under_review,
      'corrections', v_count_corrections,
      'completed', v_count_completed,
      'confirmation', v_count_confirmation,
      'rejected', v_count_rejected,
      'cancelled', v_count_cancelled,
      'expired', v_count_expired,
      'failed', v_count_failed,
      'expired_failed', v_count_expired_failed,
      'total', v_count_total
    ),
    'server_now', now()
  );
END;
$$;

COMMENT ON FUNCTION public.conectea_admin_list_cpf_change_requests_v1(text, text, int, int)
  IS 'Lista de forma segura e econômica as solicitações de alteração de CPF, com contadores agregados incluindo expired_failed, para Admin Master e Admin Dev.';

-- 7. Configurações rígidas de privilégios e grants
REVOKE ALL ON FUNCTION public.conectea_admin_list_cpf_change_requests_v1(text, text, int, int) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_admin_list_cpf_change_requests_v1(text, text, int, int) TO authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_list_cpf_change_requests_v1(text, text, int, int) TO service_role;
