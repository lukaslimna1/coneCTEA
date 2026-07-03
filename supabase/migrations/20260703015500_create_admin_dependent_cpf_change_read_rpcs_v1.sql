-- =========================================================================
-- ConeCTEA — RPCs Seguras de Leitura de Revisão de CPF de Dependente para Admins
--
-- MIGRATION: 20260703015500_create_admin_dependent_cpf_change_read_rpcs_v1.sql
-- OBJETIVO:
--   1. Criar RPC public.conectea_admin_list_dependent_cpf_change_requests_v1() para listagem
--      segura e econômica de solicitações de alteração de CPF de dependentes.
--   2. Criar RPC public.conectea_admin_get_dependent_cpf_change_sensitive_review_v1() para análise
--      segura de dados confidenciais (CPFs limpos e ID do arquivo no Google Drive) sob demanda.
--   3. Validar permissões de admin_master ou admin_dev no servidor de banco de dados.
--   4. Mascarar e minimizar as informações sensíveis retornadas.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. RPC DE LISTAGEM ADMINISTRATIVA
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_admin_list_dependent_cpf_change_requests_v1(
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
  v_count_applying bigint;
  v_count_rejected bigint;
  v_count_cancelled bigint;
  v_count_expired bigint;
  v_count_failed bigint;
  v_count_expired_failed bigint;
  v_count_total bigint;
  v_items_json jsonb;
BEGIN
  -- A. Exigir usuário autenticado
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Acesso negado: usuário não autenticado.' USING ERRCODE = '42501';
  END IF;

  -- B. Validar se o usuário é Admin Master ou Admin Dev no servidor
  SELECT role INTO v_role
  FROM public.profiles
  WHERE id = v_user_id;

  IF v_role IS NULL OR v_role NOT IN ('admin_master', 'admin_dev') THEN
    RAISE EXCEPTION 'Acesso negado: privilégios insuficientes.' USING ERRCODE = '42501';
  END IF;

  -- C. Sanitizar paginação e filtros
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

  -- Normalizar filtro de entrada para whitelist restrita
  v_filter := lower(trim(COALESCE(p_filter, 'analysis')));
  IF v_filter NOT IN ('analysis', 'corrections', 'completed', 'applying', 'rejected', 'cancelled', 'expired', 'failed', 'expired_failed', 'expired_or_failed', 'all') THEN
    v_filter := 'analysis';
  END IF;

  -- D. Obter contadores agregados respeitando a busca (se fornecida)
  SELECT
    count(*) FILTER (WHERE cr.status = 'under_review') AS count_under_review,
    count(*) FILTER (WHERE cr.status IN ('waiting_cpf_correction', 'waiting_document_replacement')) AS count_corrections,
    count(*) FILTER (WHERE cr.status = 'completed') AS count_completed,
    count(*) FILTER (WHERE cr.status = 'applying') AS count_applying,
    count(*) FILTER (WHERE cr.status = 'rejected_by_admin') AS count_rejected,
    count(*) FILTER (WHERE cr.status = 'cancelled_by_holder') AS count_cancelled,
    count(*) FILTER (WHERE cr.status = 'expired') AS count_expired,
    count(*) FILTER (WHERE cr.status = 'application_failed') AS count_failed,
    count(*) FILTER (WHERE cr.status IN ('expired', 'application_failed')) AS count_expired_failed,
    count(*) AS count_total
  INTO
    v_count_under_review,
    v_count_corrections,
    v_count_completed,
    v_count_applying,
    v_count_rejected,
    v_count_cancelled,
    v_count_expired,
    v_count_failed,
    v_count_expired_failed,
    v_count_total
  FROM public.dependent_cpf_change_requests cr
  LEFT JOIN public.profiles p ON cr.user_id = p.id
  LEFT JOIN public.members m ON cr.member_id = m.id
  WHERE (
      p_search IS NULL OR trim(p_search) = '' OR
      cr.protocol_number ILIKE '%' || trim(p_search) || '%' OR
      p.name ILIKE '%' || trim(p_search) || '%' OR
      COALESCE(p.social_name, '') ILIKE '%' || trim(p_search) || '%' OR
      p.email ILIKE '%' || trim(p_search) || '%' OR
      m.name ILIKE '%' || trim(p_search) || '%' OR
      COALESCE(m.social_name, '') ILIKE '%' || trim(p_search) || '%'
    );

  -- E. Obter itens com minimização estrita de dados sensíveis e joins otimizados
  SELECT COALESCE(jsonb_agg(t), '[]'::jsonb) INTO v_items_json
  FROM (
    SELECT
      cr.id,
      cr.protocol_number,
      cr.status,
      cr.created_at,
      cr.updated_at,
      cr.expires_at,
      cr.completed_at,
      cr.cancelled_at,
      cr.user_id,
      cr.member_id,
      cr.current_cpf_masked,
      cr.requested_cpf_masked,
      cr.document_reference_masked,
      cr.admin_feedback,
      EXISTS (
        SELECT 1 
        FROM private.dependent_cpf_change_review_data rd 
        WHERE rd.request_id = cr.id
          AND rd.document_state = 'available'
          AND rd.document_file_id IS NOT NULL
          AND btrim(rd.document_file_id) <> ''
          AND rd.cleared_at IS NULL
      ) AS has_document,
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
      END AS user_email_masked,
      COALESCE(
        split_part(nullif(trim(m.social_name), ''), ' ', 1),
        split_part(nullif(trim(m.name), ''), ' ', 1),
        'Dependente'
      ) AS dependent_first_name,
      COALESCE(nullif(trim(m.social_name), ''), trim(m.name), 'Dependente') AS dependent_full_name
    FROM public.dependent_cpf_change_requests cr
    LEFT JOIN public.profiles p ON cr.user_id = p.id
    LEFT JOIN public.members m ON cr.member_id = m.id
    WHERE (
        CASE v_filter
          WHEN 'analysis' THEN cr.status = 'under_review'
          WHEN 'corrections' THEN cr.status IN ('waiting_cpf_correction', 'waiting_document_replacement')
          WHEN 'completed' THEN cr.status = 'completed'
          WHEN 'applying' THEN cr.status = 'applying'
          WHEN 'rejected' THEN cr.status = 'rejected_by_admin'
          WHEN 'cancelled' THEN cr.status = 'cancelled_by_holder'
          WHEN 'expired' THEN cr.status = 'expired'
          WHEN 'failed' THEN cr.status = 'application_failed'
          WHEN 'expired_failed' THEN cr.status IN ('expired', 'application_failed')
          WHEN 'expired_or_failed' THEN cr.status IN ('expired', 'application_failed')
          WHEN 'all' THEN true
        END
      )
      AND (
        p_search IS NULL OR trim(p_search) = '' OR
        cr.protocol_number ILIKE '%' || trim(p_search) || '%' OR
        p.name ILIKE '%' || trim(p_search) || '%' OR
        COALESCE(p.social_name, '') ILIKE '%' || trim(p_search) || '%' OR
        p.email ILIKE '%' || trim(p_search) || '%' OR
        m.name ILIKE '%' || trim(p_search) || '%' OR
        COALESCE(m.social_name, '') ILIKE '%' || trim(p_search) || '%'
      )
    ORDER BY cr.created_at DESC, cr.id DESC
    LIMIT v_limit
    OFFSET v_offset
  ) t;

  -- F. Retornar resposta JSONB consolidada
  RETURN jsonb_build_object(
    'items', v_items_json,
    'counts', jsonb_build_object(
      'analysis', v_count_under_review,
      'corrections', v_count_corrections,
      'completed', v_count_completed,
      'applying', v_count_applying,
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

COMMENT ON FUNCTION public.conectea_admin_list_dependent_cpf_change_requests_v1(text, text, int, int)
  IS 'Lista de forma segura e econômica as solicitações de alteração de CPF de dependentes, com contadores agregados, para Admin Master e Admin Dev.';

-- Privilégios mínimos e grants
REVOKE ALL ON FUNCTION public.conectea_admin_list_dependent_cpf_change_requests_v1(text, text, int, int) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_admin_list_dependent_cpf_change_requests_v1(text, text, int, int) TO authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_list_dependent_cpf_change_requests_v1(text, text, int, int) TO service_role;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. RPC DE LEITURA DE DADOS SENSÍVEIS (REVIEW)
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_admin_get_dependent_cpf_change_sensitive_review_v1(
  p_request_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private, pg_temp
AS $$
DECLARE
  v_caller_id uuid;
  v_caller_role text;
  v_request_exists boolean;
  v_request_status text;
  v_review_record record;
  v_can_view boolean;
  v_review_found boolean := false;
  v_safe_document_state text := 'unavailable';
  v_can_view_document boolean := false;
  v_review_is_active boolean := false;
BEGIN
  -- A. Validar caller autenticado
  v_caller_id := auth.uid();
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Acesso negado: usuario nao autenticado.' USING ERRCODE = '42501';
  END IF;

  -- B. Validar role do caller (Somente admin_master ou admin_dev possuem permissão)
  SELECT role INTO v_caller_role
  FROM public.profiles
  WHERE id = v_caller_id;

  IF v_caller_role IS NULL OR v_caller_role NOT IN ('admin_master', 'admin_dev') THEN
    RAISE EXCEPTION 'Acesso negado: privilegios insuficientes.' USING ERRCODE = '42501';
  END IF;

  -- C. Validar existência da solicitação
  SELECT EXISTS (
    SELECT 1 FROM public.dependent_cpf_change_requests WHERE id = p_request_id
  ) INTO v_request_exists;

  IF NOT v_request_exists THEN
    RAISE EXCEPTION 'Solicitacao nao encontrada.' USING ERRCODE = 'P0002';
  END IF;

  -- D. Obter status da solicitação
  SELECT status INTO v_request_status
  FROM public.dependent_cpf_change_requests
  WHERE id = p_request_id;

  -- E. Determinar se o status permite leitura completa dos dados limpos
  IF v_request_status IN ('under_review', 'waiting_document_replacement', 'waiting_cpf_correction') THEN
    v_can_view := true;
  ELSE
    v_can_view := false;
  END IF;

  -- F. Consultar tabela de review privada contendo os dados sensíveis salvos em criação
  SELECT rd.* INTO v_review_record
  FROM private.dependent_cpf_change_review_data rd
  WHERE rd.request_id = p_request_id;

  v_review_found := FOUND;

  -- G. Atribuir e calcular de forma segura o estado do documento e expurgo
  IF v_review_found THEN
    v_safe_document_state := COALESCE(v_review_record.document_state, 'unavailable');
    v_review_is_active := v_review_record.cleared_at IS NULL;

    v_can_view_document :=
      v_review_is_active
      AND v_safe_document_state = 'available'
      AND v_review_record.document_file_id IS NOT NULL
      AND v_review_record.document_file_id <> '';
  END IF;

  -- H. Montar retorno condicional baseado no status e expurgo
  IF v_can_view AND v_review_found AND v_review_is_active THEN
    RETURN jsonb_build_object(
      'can_view', true,
      'request_id', p_request_id,
      'status', v_request_status,
      'old_cpf_clear', v_review_record.old_cpf_clear,
      'new_cpf_clear', v_review_record.new_cpf_clear,
      'document_state', v_safe_document_state,
      'can_view_document', v_can_view_document,
      'document_file_id', CASE WHEN v_can_view_document THEN v_review_record.document_file_id ELSE NULL END,
      'server_now', now()
    );
  ELSE
    RETURN jsonb_build_object(
      'can_view', false,
      'request_id', p_request_id,
      'status', v_request_status,
      'old_cpf_clear', null,
      'new_cpf_clear', null,
      'document_state', v_safe_document_state,
      'can_view_document', false,
      'document_file_id', null,
      'server_now', now()
    );
  END IF;
END;
$$;

COMMENT ON FUNCTION public.conectea_admin_get_dependent_cpf_change_sensitive_review_v1(uuid)
  IS 'Obtém dados confidenciais transitórios de auditoria da solicitação de CPF de dependente para admins dev/master, mascarando o PII se o status da solicitação estiver fechado ou inativo.';

-- Privilégios mínimos e grants
REVOKE ALL ON FUNCTION public.conectea_admin_get_dependent_cpf_change_sensitive_review_v1(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_admin_get_dependent_cpf_change_sensitive_review_v1(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_get_dependent_cpf_change_sensitive_review_v1(uuid) TO service_role;
