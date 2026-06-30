-- Migration: Create Dependent Correction Requests Foundation
-- Description: Cria a fundação transacional segura para correção de dependentes sem alterar members ou carteirinhas ativas.

-- 1. CRIAR TABELA
CREATE TABLE public.dependent_correction_requests (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    member_id uuid NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
    status text NOT NULL DEFAULT 'under_review',
    review_data jsonb NOT NULL,
    observation text,
    admin_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    admin_feedback text,
    public_admin_feedback text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    reviewed_at timestamptz,
    closed_at timestamptz,

    CONSTRAINT dependent_correction_requests_status_check CHECK (status IN ('under_review', 'approved', 'rejected', 'cancelled', 'expired')),
    CONSTRAINT dependent_correction_requests_review_data_not_empty CHECK (review_data::text != '{}'::text),
    CONSTRAINT dependent_correction_requests_closed_at_check CHECK (
        (status = 'under_review' AND closed_at IS NULL) OR
        (status IN ('approved', 'rejected', 'cancelled', 'expired') AND closed_at IS NOT NULL)
    )
);

-- 2. ÍNDICE ÚNICO PARCIAL: bloqueia mais de uma revisão simultânea para o mesmo membro
CREATE UNIQUE INDEX idx_dependent_correction_requests_under_review_unique
ON public.dependent_correction_requests (member_id)
WHERE status = 'under_review';

-- 3. ÍNDICES DE PERFORMANCE
CREATE INDEX idx_dependent_correction_requests_user_id ON public.dependent_correction_requests(user_id);
CREATE INDEX idx_dependent_correction_requests_member_id ON public.dependent_correction_requests(member_id);

-- 4. RLS E POLÍTICAS
ALTER TABLE public.dependent_correction_requests ENABLE ROW LEVEL SECURITY;

-- Responsável lê suas próprias solicitações
CREATE POLICY "Users can view their own dependent correction requests"
ON public.dependent_correction_requests
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Admin pode ler todas
CREATE POLICY "Admins can view all dependent correction requests"
ON public.dependent_correction_requests
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'admin_dev', 'admin_master')
    )
);

-- Segurança padrão do projeto: revoke total para forms diretos, garantido acesso apenas via view/RPC
REVOKE INSERT, UPDATE, DELETE ON public.dependent_correction_requests FROM public, authenticated;
GRANT SELECT ON public.dependent_correction_requests TO authenticated;
GRANT ALL ON public.dependent_correction_requests TO service_role;

-- 5. TRIGGER DE UPDATED_AT
CREATE OR REPLACE FUNCTION public.set_dependent_correction_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_dependent_correction_requests_updated_at
  BEFORE UPDATE ON public.dependent_correction_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.set_dependent_correction_requests_updated_at();

-- 6. RPC DE SUBMISSÃO
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
    SELECT true, status, user_id INTO v_member_exists, v_member_status, v_member_user_id
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
        RETURN jsonb_build_object('success', false, 'error_code', 'internal_error', 'details', SQLERRM);
END;
$$;

COMMENT ON FUNCTION public.conectea_submit_dependent_correction_v1 IS 'Submete uma revisao de dados simples de dependente (fase 1) sem alterar members, garantindo a permanencia da carteirinha digital. Bloqueia CPF/CID/Documentos.';
