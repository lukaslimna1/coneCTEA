-- =========================================================================
-- ConeCTEA — Consulta de Ciclo Ativo de Alteração de E-mail
--
-- MIGRATION: 20260620152000_create_get_active_email_change_cycle_v1.sql
-- OBJETIVO:
--   1. Criar função conectea_get_active_email_change_cycle_v1
--   2. Retornar dados seguros sobre o ciclo aberto do próprio usuário
--
-- STATUS: Criado via microfrente
-- =========================================================================

CREATE OR REPLACE FUNCTION conectea_get_active_email_change_cycle_v1()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, private
AS $$
DECLARE
    _user_id uuid;
    _cycle record;
    _challenge record;
BEGIN
    _user_id := auth.uid();
    IF _user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    -- Look for open cycle
    SELECT * INTO _cycle
    FROM private.account_change_challenge_cycles
    WHERE user_id = _user_id
      AND purpose = 'email_change'
      AND closed_at IS NULL
    ORDER BY created_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'has_active_cycle', false,
            'server_now', now()
        );
    END IF;

    -- Look for latest challenge
    SELECT * INTO _challenge
    FROM private.account_change_challenges
    WHERE cycle_id = _cycle.id
      AND user_id = _user_id
      AND purpose = 'email_change'
    ORDER BY send_sequence DESC, created_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'has_active_cycle', false,
            'server_now', now()
        );
    END IF;

    -- Check if challenge is resumable
    IF _challenge.challenge_state != 'active' THEN
        RETURN jsonb_build_object(
            'has_active_cycle', false,
            'reason', 'not_resumable',
            'server_now', now()
        );
    END IF;

    IF _challenge.delivery_status = 'failed' THEN
        RETURN jsonb_build_object(
            'has_active_cycle', false,
            'reason', 'not_resumable',
            'server_now', now()
        );
    END IF;

    IF _challenge.attempts >= _challenge.max_attempts THEN
        RETURN jsonb_build_object(
            'has_active_cycle', false,
            'reason', 'not_resumable',
            'server_now', now()
        );
    END IF;

    IF _challenge.expires_at <= now() THEN
        RETURN jsonb_build_object(
            'has_active_cycle', false,
            'reason', 'expired',
            'server_now', now()
        );
    END IF;
    
    RETURN jsonb_build_object(
        'has_active_cycle', true,
        'destination_email_masked', _cycle.destination_masked,
        'otp_expires_at', _challenge.expires_at,
        'resend_available_at', _challenge.resend_available_at,
        'challenge_state', _challenge.challenge_state,
        'delivery_status', _challenge.delivery_status,
        'send_sequence', _challenge.send_sequence,
        'attempts', _challenge.attempts,
        'max_attempts', _challenge.max_attempts,
        'server_now', now(),
        'cycle_status', 'open'
    );
END;
$$;

-- Somente usuários logados podem consultar
REVOKE ALL ON FUNCTION conectea_get_active_email_change_cycle_v1() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION conectea_get_active_email_change_cycle_v1() TO authenticated;

-- =========================================================================
-- FUNÇÃO DE LIMPEZA DE CICLOS ZUMBIS (EXPIRADOS)
-- =========================================================================
CREATE OR REPLACE FUNCTION private.conectea_cleanup_expired_email_change_cycles_v1(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, private, pg_temp
AS $$
DECLARE
    v_cycle_id uuid;
    v_challenge_id uuid;
    v_now timestamptz;
BEGIN
    v_now := transaction_timestamp();

    FOR v_cycle_id IN 
        SELECT id 
        FROM private.account_change_challenge_cycles
        WHERE user_id = p_user_id
          AND purpose = 'email_change'
          AND closed_at IS NULL
    LOOP
        SELECT id INTO v_challenge_id
        FROM private.account_change_challenges
        WHERE cycle_id = v_cycle_id
          AND challenge_state = 'active'
          AND expires_at <= v_now
        ORDER BY send_sequence DESC, created_at DESC
        LIMIT 1;

        IF FOUND THEN
            -- Tenta atualizar de forma atômica e condicional
            WITH updated_challenge AS (
                UPDATE private.account_change_challenges
                SET challenge_state = 'expired',
                    expired_at = v_now,
                    updated_at = v_now
                WHERE id = v_challenge_id
                  AND cycle_id = v_cycle_id
                  AND user_id = p_user_id
                  AND purpose = 'email_change'
                  AND challenge_state = 'active'
                  AND expires_at <= v_now
                RETURNING id
            ),
            updated_cycle AS (
                UPDATE private.account_change_challenge_cycles
                SET closed_at = v_now,
                    updated_at = v_now
                WHERE id = v_cycle_id
                  AND user_id = p_user_id
                  AND purpose = 'email_change'
                  AND closed_at IS NULL
                  AND EXISTS (SELECT 1 FROM updated_challenge)
                RETURNING id
            )
            UPDATE private.account_change_email_reservations
            SET reservation_state = 'released',
                released_at = v_now,
                release_reason = 'otp_expired',
                cycle_closed_at = v_now,
                updated_at = v_now
            WHERE cycle_id = v_cycle_id
              AND reservation_state IN ('active', 'attached')
              AND EXISTS (SELECT 1 FROM updated_cycle);
        END IF;
    END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION private.conectea_cleanup_expired_email_change_cycles_v1(uuid) FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.conectea_cleanup_expired_email_change_cycles_v1(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, private, pg_temp
AS $$
BEGIN
    PERFORM private.conectea_cleanup_expired_email_change_cycles_v1(p_user_id);
END;
$$;

REVOKE ALL ON FUNCTION public.conectea_cleanup_expired_email_change_cycles_v1(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_cleanup_expired_email_change_cycles_v1(uuid) TO service_role;
