-- Migration: Patch Dependent Correction Contact Pair Rules
-- Description: Adiciona regras de validação de par telefone/nome para responsável e emergência.

CREATE OR REPLACE FUNCTION public.conectea_submit_dependent_correction_v1(
    p_member_id uuid,
    p_review_data jsonb,
    p_observation text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id uuid := auth.uid();
    v_member_exists boolean;
    v_member_status text;
    v_member_user_id uuid;
    v_current_resp_name text;
    v_current_emerg_name text;
    v_existing_pending boolean;
    v_key text;
    v_val jsonb;
    v_allowed_keys text[] := ARRAY[
        'name',
        'birth_date',
        'phone',
        'state',
        'city',
        'responsible_person_name',
        'responsible_phone',
        'emergency_person_name',
        'emergency_phone',
        'gender',
        'raca_cor',
        'blood_type',
        'social_name'
    ];
    v_forbidden_keys text[] := ARRAY[
        'cpf',
        'cid',
        'laudo',
        'document',
        'document_file_id',
        'file_id',
        'url',
        'diagnosis'
    ];
    v_new_request_id uuid;
    v_normalized_observation text := trim(p_observation);

    -- Variables for pair rules
    v_has_new_resp_phone boolean;
    v_has_new_resp_name boolean;
    v_has_new_emerg_phone boolean;
    v_has_new_emerg_name boolean;
BEGIN
    -- Validar autenticação
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'unauthorized');
    END IF;

    -- Validar payload vazio
    IF p_review_data IS NULL OR p_review_data::text = '{}'::text THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'empty_payload');
    END IF;

    -- Validar se o member existe e pertence ao usuario
    SELECT true, status, user_id, responsible_person_name, emergency_person_name
    INTO v_member_exists, v_member_status, v_member_user_id, v_current_resp_name, v_current_emerg_name
    FROM public.members
    WHERE id = p_member_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'member_not_found');
    END IF;

    IF v_member_user_id != v_user_id THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'forbidden');
    END IF;

    -- Validar se member está ativo ou aprovado (carteirinha ativa)
    IF v_member_status != 'active' AND v_member_status != 'approved' THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'member_not_active');
    END IF;

    -- Validar pendencias simultaneas
    SELECT true INTO v_existing_pending
    FROM public.dependent_correction_requests
    WHERE member_id = p_member_id AND status = 'under_review';

    IF v_existing_pending THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'already_under_review');
    END IF;

    -- Validar allowlist e chaves proibidas no payload
    FOR v_key, v_val IN SELECT * FROM jsonb_each(p_review_data) LOOP
        IF v_key = ANY(v_forbidden_keys) THEN
            RETURN jsonb_build_object('success', false, 'error_code', 'unsupported_field', 'field', v_key);
        END IF;

        IF NOT (v_key = ANY(v_allowed_keys)) THEN
            RETURN jsonb_build_object('success', false, 'error_code', 'invalid_field', 'field', v_key);
        END IF;
    END LOOP;

    -- Validar regras de par nome/telefone
    v_has_new_resp_phone := p_review_data ? 'responsible_phone';
    v_has_new_resp_name := (p_review_data ? 'responsible_person_name') AND (trim(p_review_data->>'responsible_person_name') != '');

    IF v_has_new_resp_phone AND (v_current_resp_name IS NULL OR trim(v_current_resp_name) = '') AND NOT v_has_new_resp_name THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'responsible_name_required');
    END IF;

    v_has_new_emerg_phone := p_review_data ? 'emergency_phone';
    v_has_new_emerg_name := (p_review_data ? 'emergency_person_name') AND (trim(p_review_data->>'emergency_person_name') != '');

    IF v_has_new_emerg_phone AND (v_current_emerg_name IS NULL OR trim(v_current_emerg_name) = '') AND NOT v_has_new_emerg_name THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'emergency_name_required');
    END IF;

    -- Inserir a nova solicitacao de correcao sem alterar members nem card_requests
    INSERT INTO public.dependent_correction_requests (
        user_id,
        member_id,
        status,
        review_data,
        observation
    ) VALUES (
        v_user_id,
        p_member_id,
        'under_review',
        p_review_data,
        v_normalized_observation
    ) RETURNING id INTO v_new_request_id;

    -- Retornar confirmacao limpa
    RETURN jsonb_build_object(
        'success', true,
        'request_id', v_new_request_id,
        'status', 'under_review'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'internal_error');
END;
$$;

COMMENT ON FUNCTION public.conectea_submit_dependent_correction_v1 IS 'Submete revisao com bloqueio CPF/CID e validacao de pares (telefone/nome).';
