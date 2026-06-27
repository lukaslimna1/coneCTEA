-- =========================================================================
-- ConeCTEA — RPCs de Gerenciamento da Fila de Descarte do Google Drive
--
-- MIGRATION: 20260624113500_create_gc_drive_queue_rpcs_v1.sql
-- OBJETIVO:
--   - Criar RPCs privadas para lock, resolução e liberação de itens
--     travados na fila private.gc_drive_files_to_delete.
--   - Fornecer wrappers públicos restritos a service_role para uso
--     exclusivo pela Edge Function process-gc-drive-queue.
--
-- PRIVACIDADE E SEGURANÇA:
--   - Funções privadas com SECURITY DEFINER e search_path blindado.
--   - Concorrência segura via FOR UPDATE SKIP LOCKED.
--   - Nenhuma dessas RPCs é acessível por anon, authenticated ou PUBLIC.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. RPC DE LOCK: BUSCA E BLOQUEIA ITENS PENDING
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION private.conectea_lock_gc_drive_pending_v1(
  p_limit integer,
  p_locked_by text
)
RETURNS TABLE (
  id uuid,
  file_id text,
  source_table text,
  source_id uuid,
  reason text,
  attempts integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $$
BEGIN
  -- Validar inputs
  IF p_limit IS NULL OR p_limit < 1 OR p_limit > 50 THEN
    RAISE EXCEPTION 'Limite inválido: deve ser entre 1 e 50.'
      USING ERRCODE = '22023'; -- invalid_parameter_value
  END IF;

  IF p_locked_by IS NULL OR length(trim(p_locked_by)) = 0 THEN
    RAISE EXCEPTION 'Identificador do processador é obrigatório.'
      USING ERRCODE = '22004'; -- null_value_not_allowed
  END IF;

  -- Buscar, bloquear e atualizar itens pending elegíveis
  RETURN QUERY
  WITH locked_items AS (
    SELECT g.id AS item_id
    FROM private.gc_drive_files_to_delete g
    WHERE g.status = 'pending'
      AND g.next_attempt_at <= now()
    ORDER BY g.next_attempt_at, g.created_at
    FOR UPDATE SKIP LOCKED
    LIMIT p_limit
  )
  UPDATE private.gc_drive_files_to_delete g
  SET status = 'processing',
      locked_at = now(),
      locked_by = p_locked_by,
      attempts = g.attempts + 1,
      updated_at = now()
  FROM locked_items li
  WHERE g.id = li.item_id
  RETURNING
    g.id,
    g.file_id,
    g.source_table,
    g.source_id,
    g.reason,
    g.attempts;
END;
$$;

-- Wrapper público restrito
CREATE OR REPLACE FUNCTION public.conectea_lock_gc_drive_pending_v1(
  p_limit integer,
  p_locked_by text
)
RETURNS TABLE (
  id uuid,
  file_id text,
  source_table text,
  source_id uuid,
  reason text,
  attempts integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM private.conectea_lock_gc_drive_pending_v1(p_limit, p_locked_by);
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. RPC DE RESOLUÇÃO: MARCA ITEM COMO PROCESSED OU FAILED
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION private.conectea_resolve_gc_drive_item_v1(
  p_id uuid,
  p_success boolean,
  p_locked_by text,
  p_error_code text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $$
DECLARE
  v_now timestamptz;
  v_attempts integer;
  v_max_attempts integer;
  v_is_fatal_error boolean;
  v_final_status text;
BEGIN
  -- Validar inputs obrigatórios
  IF p_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'missing_id');
  END IF;

  IF p_success IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'missing_success');
  END IF;

  IF p_locked_by IS NULL OR length(trim(p_locked_by)) = 0 THEN
    RAISE EXCEPTION 'O parâmetro p_locked_by é obrigatório para resolução.'
      USING ERRCODE = '22004'; -- null_value_not_allowed
  END IF;

  -- Validar e restringir o p_error_code à whitelist de segurança
  v_is_fatal_error := false;
  IF p_error_code IS NOT NULL THEN
    IF length(p_error_code) > 80 THEN
      RAISE EXCEPTION 'O código de erro excede o limite de 80 caracteres.'
        USING ERRCODE = '22023'; -- invalid_parameter_value
    END IF;

    IF p_error_code NOT IN (
      'gas_auth_failed',
      'gas_replay_rejected',
      'gas_invalid_payload',
      'drive_file_not_found',
      'drive_permission_denied',
      'drive_error',
      'gas_unavailable',
      'worker_unavailable',
      'unknown_error'
    ) THEN
      RAISE EXCEPTION 'Código de erro inválido ou não autorizado: %', p_error_code
        USING ERRCODE = '22023'; -- invalid_parameter_value
    END IF;

    -- Identificar se é um erro fatal que impossibilita retentativas (falha definitiva imediata)
    IF p_error_code IN ('gas_auth_failed', 'gas_invalid_payload', 'drive_permission_denied') THEN
      v_is_fatal_error := true;
    END IF;
  END IF;

  v_now := now();

  -- Buscar o item e bloquear se corresponder ao ID, status 'processing' e locked_by correto
  SELECT attempts, max_attempts
  INTO v_attempts, v_max_attempts
  FROM private.gc_drive_files_to_delete
  WHERE id = p_id
    AND status = 'processing'
    AND locked_by = p_locked_by
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'not_found');
  END IF;

  IF p_success THEN
    -- Sucesso: marcar como processed
    v_final_status := 'processed';
    UPDATE private.gc_drive_files_to_delete
    SET status = v_final_status,
        processed_at = v_now,
        locked_at = NULL,
        locked_by = NULL,
        last_error_code = NULL,
        updated_at = v_now
    WHERE id = p_id;
  ELSE
    -- Falha: verificar se esgotou tentativas ou se é um erro fatal definitivo
    IF v_attempts >= v_max_attempts OR v_is_fatal_error THEN
      -- Falha definitiva
      v_final_status := 'failed';
      UPDATE private.gc_drive_files_to_delete
      SET status = v_final_status,
          locked_at = NULL,
          locked_by = NULL,
          last_error_code = p_error_code,
          updated_at = v_now
      WHERE id = p_id;
    ELSE
      -- Falha temporária: backoff exponencial e voltar para pending
      v_final_status := 'pending';
      UPDATE private.gc_drive_files_to_delete
      SET status = v_final_status,
          locked_at = NULL,
          locked_by = NULL,
          last_error_code = p_error_code,
          next_attempt_at = v_now + (interval '1 minute' * power(2, v_attempts)),
          updated_at = v_now
      WHERE id = p_id;
    END IF;
  END IF;

  RETURN jsonb_build_object('success', true, 'final_status', v_final_status);
END;
$$;

-- Wrapper público restrito
CREATE OR REPLACE FUNCTION public.conectea_resolve_gc_drive_item_v1(
  p_id uuid,
  p_success boolean,
  p_locked_by text,
  p_error_code text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $$
BEGIN
  RETURN private.conectea_resolve_gc_drive_item_v1(p_id, p_success, p_locked_by, p_error_code);
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 3. RPC DE LIBERAÇÃO: DESBLOQUEIA ITENS TRAVADOS EM PROCESSING
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION private.conectea_unlock_stale_gc_drive_items_v1()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $$
DECLARE
  v_count integer;
BEGIN
  -- Liberar itens travados em processing há mais de 15 minutos
  UPDATE private.gc_drive_files_to_delete
  SET status = 'pending',
      locked_at = NULL,
      locked_by = NULL,
      next_attempt_at = now(),
      updated_at = now()
  WHERE status = 'processing'
    AND locked_at < now() - interval '15 minutes';

  GET DIAGNOSTICS v_count = ROW_COUNT;

  RETURN v_count;
END;
$$;

-- Wrapper público restrito
CREATE OR REPLACE FUNCTION public.conectea_unlock_stale_gc_drive_items_v1()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, private, pg_temp
AS $$
BEGIN
  RETURN private.conectea_unlock_stale_gc_drive_items_v1();
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 4. POLÍTICA DE PRIVILÉGIOS E SEGURANÇA (GRANTS)
-- ─────────────────────────────────────────────────────────────────────────

-- Lock RPC (privada e pública)
REVOKE ALL ON FUNCTION private.conectea_lock_gc_drive_pending_v1(integer, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.conectea_lock_gc_drive_pending_v1(integer, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.conectea_lock_gc_drive_pending_v1(integer, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.conectea_lock_gc_drive_pending_v1(integer, text) TO service_role;

-- Resolve RPC (privada e pública)
REVOKE ALL ON FUNCTION private.conectea_resolve_gc_drive_item_v1(uuid, boolean, text, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.conectea_resolve_gc_drive_item_v1(uuid, boolean, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.conectea_resolve_gc_drive_item_v1(uuid, boolean, text, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.conectea_resolve_gc_drive_item_v1(uuid, boolean, text, text) TO service_role;

-- Unlock Stale RPC (privada e pública)
REVOKE ALL ON FUNCTION private.conectea_unlock_stale_gc_drive_items_v1() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.conectea_unlock_stale_gc_drive_items_v1() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.conectea_unlock_stale_gc_drive_items_v1() TO service_role;
GRANT EXECUTE ON FUNCTION public.conectea_unlock_stale_gc_drive_items_v1() TO service_role;
