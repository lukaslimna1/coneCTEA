-- =========================================================================
-- ConeCTEA — Cancelamento de Ciclo Ativo de Alteração de E-mail
--
-- MIGRATION: 20260621120000_create_cancel_email_change_v1.sql
-- OBJETIVO:
--   1. Criar função conectea_cancel_email_change_v1
--   2. Encerrar o ciclo ativo de alteração de e-mail do usuário
--   3. Invalidar o OTP/desafio ativo
--   4. Liberar a reserva de e-mail
--
-- STATUS: Criado via microfrente
-- =========================================================================

CREATE OR REPLACE FUNCTION conectea_cancel_email_change_v1()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, private, pg_temp
AS $$
DECLARE
    v_user_id uuid;
    v_cycle_id uuid;
    v_now timestamptz;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    v_now := transaction_timestamp();

    -- Localizar ciclo ativo
    SELECT id INTO v_cycle_id
    FROM private.account_change_challenge_cycles
    WHERE user_id = v_user_id
      AND purpose = 'email_change'
      AND closed_at IS NULL
    ORDER BY created_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('status', 'no_active_cycle');
    END IF;

    -- Tenta atualizar de forma atômica e condicional o desafio, o ciclo e a reserva
    WITH updated_challenge AS (
        UPDATE private.account_change_challenges
        SET challenge_state = 'cancelled',
            cancelled_at = v_now,
            updated_at = v_now
        WHERE cycle_id = v_cycle_id
          AND user_id = v_user_id
          AND purpose = 'email_change'
          AND challenge_state = 'active'
        RETURNING id
    ),
    updated_cycle AS (
        UPDATE private.account_change_challenge_cycles
        SET closed_at = v_now,
            updated_at = v_now
        WHERE id = v_cycle_id
          AND user_id = v_user_id
          AND purpose = 'email_change'
          AND closed_at IS NULL
        RETURNING id
    )
    UPDATE private.account_change_email_reservations
    SET reservation_state = 'released',
        released_at = v_now,
        release_reason = 'user_cancelled',
        cycle_closed_at = v_now,
        updated_at = v_now
    WHERE cycle_id = v_cycle_id
      AND reservation_state IN ('active', 'attached')
      AND EXISTS (SELECT 1 FROM updated_cycle);

    RETURN jsonb_build_object('status', 'success');
END;
$$;

-- Somente usuários logados podem consultar/cancelar
REVOKE ALL ON FUNCTION conectea_cancel_email_change_v1() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION conectea_cancel_email_change_v1() TO authenticated;
