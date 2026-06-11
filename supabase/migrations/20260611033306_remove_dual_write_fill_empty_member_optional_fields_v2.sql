-- ConeCTEA — Migration: RPC para Preenchimento Atômico de Campos Opcionais Vazios (V2) - Sem Dual-Write
-- MIGRATION: 20260611032742_remove_dual_write_fill_empty_member_optional_fields_v2.sql

CREATE OR REPLACE FUNCTION public.conectea_fill_empty_member_optional_fields_v2(
  p_member_id uuid,
  p_blood_type text DEFAULT NULL,
  p_phone text DEFAULT NULL,
  p_raca_cor text DEFAULT NULL,
  p_gender text DEFAULT NULL,
  p_cid text DEFAULT NULL,
  p_responsible_person_name text DEFAULT NULL,
  p_responsible_phone text DEFAULT NULL,
  p_emergency_person_name text DEFAULT NULL,
  p_emergency_phone text DEFAULT NULL
)
RETURNS TABLE (
  member_id uuid,
  blood_type text,
  phone text,
  raca_cor text,
  gender text,
  cid text,
  responsible_person_name text,
  responsible_phone text,
  emergency_person_name text,
  emergency_phone text,
  applied_fields text[],
  preserved_fields text[],
  changed boolean
)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_member public.members%ROWTYPE;
  v_applied text[] := '{}';
  v_preserved text[] := '{}';

  v_new_blood_type text;
  v_new_phone text;
  v_new_raca_cor text;
  v_new_gender text;
  v_new_cid text;

  -- Campos estruturados
  v_new_responsible_person_name text;
  v_new_responsible_phone text;
  v_new_emergency_person_name text;
  v_new_emergency_phone text;

  v_changed boolean := false;
  v_clean_phone text;

  v_responsible_phone_clean text;
  v_emergency_phone_clean text;
BEGIN
  -- 1. Validar login do usuário
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Operação não autorizada.';
  END IF;

  -- 2. Obter o registro atual com bloqueio de concorrência (FOR UPDATE)
  SELECT *
  INTO v_member
  FROM public.members
  WHERE id = p_member_id
    AND user_id = auth.uid()
  FOR UPDATE;

  IF v_member.id IS NULL THEN
    RAISE EXCEPTION 'Membro não encontrado ou acesso não autorizado.';
  END IF;

  -- 3. Processar Campo: blood_type
  IF v_member.blood_type IS NULL OR btrim(v_member.blood_type) = '' THEN
    IF p_blood_type IS NOT NULL AND btrim(p_blood_type) != '' THEN
      IF NOT (btrim(p_blood_type) IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')) THEN
        RAISE EXCEPTION 'Tipo sanguíneo inválido.';
      END IF;
      v_new_blood_type := btrim(p_blood_type);
      v_applied := array_append(v_applied, 'blood_type');
    ELSE
      v_new_blood_type := v_member.blood_type;
    END IF;
  ELSE
    v_new_blood_type := v_member.blood_type;
    IF p_blood_type IS NOT NULL AND btrim(p_blood_type) != '' AND btrim(p_blood_type) != btrim(v_member.blood_type) THEN
      v_preserved := array_append(v_preserved, 'blood_type');
    END IF;
  END IF;

  -- 4. Processar Campo: phone
  IF v_member.phone IS NULL OR btrim(v_member.phone) = '' THEN
    IF p_phone IS NOT NULL AND btrim(p_phone) != '' THEN
      v_clean_phone := regexp_replace(p_phone, '[^0-9]', '', 'g');
      IF length(v_clean_phone) NOT IN (10, 11) OR v_clean_phone ~ '^([0-9])\1+$' THEN
        RAISE EXCEPTION 'Telefone inválido.';
      END IF;
      v_new_phone := btrim(p_phone);
      v_applied := array_append(v_applied, 'phone');
    ELSE
      v_new_phone := v_member.phone;
    END IF;
  ELSE
    v_new_phone := v_member.phone;
    IF p_phone IS NOT NULL AND btrim(p_phone) != '' AND btrim(p_phone) != btrim(v_member.phone) THEN
      v_preserved := array_append(v_preserved, 'phone');
    END IF;
  END IF;

  -- 5. Processar Campo: raca_cor
  IF v_member.raca_cor IS NULL OR btrim(v_member.raca_cor) = '' THEN
    IF p_raca_cor IS NOT NULL AND btrim(p_raca_cor) != '' THEN
      IF NOT (btrim(p_raca_cor) IN ('Branca', 'Preta', 'Parda', 'Amarela', 'Indígena', 'Prefiro não informar')) THEN
        RAISE EXCEPTION 'Opção de raça/cor inválida.';
      END IF;
      v_new_raca_cor := btrim(p_raca_cor);
      v_applied := array_append(v_applied, 'raca_cor');
    ELSE
      v_new_raca_cor := v_member.raca_cor;
    END IF;
  ELSE
    v_new_raca_cor := v_member.raca_cor;
    IF p_raca_cor IS NOT NULL AND btrim(p_raca_cor) != '' AND btrim(p_raca_cor) != btrim(v_member.raca_cor) THEN
      v_preserved := array_append(v_preserved, 'raca_cor');
    END IF;
  END IF;

  -- 6. Processar Campo: gender
  IF v_member.gender IS NULL OR btrim(v_member.gender) = '' THEN
    IF p_gender IS NOT NULL AND btrim(p_gender) != '' THEN
      IF NOT (btrim(p_gender) IN ('Feminino', 'Masculino', 'Não binário', 'Outro', 'Prefiro não informar')) THEN
        RAISE EXCEPTION 'Opção de gênero inválida.';
      END IF;
      v_new_gender := btrim(p_gender);
      v_applied := array_append(v_applied, 'gender');
    ELSE
      v_new_gender := v_member.gender;
    END IF;
  ELSE
    v_new_gender := v_member.gender;
    IF p_gender IS NOT NULL AND btrim(p_gender) != '' AND btrim(p_gender) != btrim(v_member.gender) THEN
      v_preserved := array_append(v_preserved, 'gender');
    END IF;
  END IF;

  -- 7. Processar Campo: cid
  IF v_member.cid IS NULL OR btrim(v_member.cid) = '' THEN
    IF p_cid IS NOT NULL AND btrim(p_cid) != '' THEN
      IF length(btrim(p_cid)) > 20 THEN
        RAISE EXCEPTION 'Código CID inválido ou muito longo.';
      END IF;
      v_new_cid := btrim(p_cid);
      v_applied := array_append(v_applied, 'cid');
    ELSE
      v_new_cid := v_member.cid;
    END IF;
  ELSE
    v_new_cid := v_member.cid;
    IF p_cid IS NOT NULL AND btrim(p_cid) != '' AND btrim(p_cid) != btrim(v_member.cid) THEN
      v_preserved := array_append(v_preserved, 'cid');
    END IF;
  END IF;

  -- 8. Processar Campo: responsible_person_name e responsible_phone
  v_new_responsible_person_name := v_member.responsible_person_name;
  v_new_responsible_phone := v_member.responsible_phone;

  -- Nome do responsável
  IF v_member.responsible_person_name IS NULL OR btrim(v_member.responsible_person_name) = '' THEN
    IF p_responsible_person_name IS NOT NULL AND btrim(p_responsible_person_name) != '' THEN
      IF length(btrim(p_responsible_person_name)) > 100 THEN
        RAISE EXCEPTION 'Nome do responsável muito longo.';
      END IF;
      v_new_responsible_person_name := btrim(p_responsible_person_name);
      v_applied := array_append(v_applied, 'responsible_person_name');
    END IF;
  ELSE
    IF p_responsible_person_name IS NOT NULL AND btrim(p_responsible_person_name) != '' AND btrim(p_responsible_person_name) != btrim(v_member.responsible_person_name) THEN
      v_preserved := array_append(v_preserved, 'responsible_person_name');
    END IF;
  END IF;

  -- Telefone do responsável
  IF v_member.responsible_phone IS NULL OR btrim(v_member.responsible_phone) = '' THEN
    IF p_responsible_phone IS NOT NULL AND btrim(p_responsible_phone) != '' THEN
      IF (v_new_responsible_person_name IS NULL OR btrim(v_new_responsible_person_name) = '') THEN
        RAISE EXCEPTION 'Telefone do responsável sem nome.';
      END IF;

      v_responsible_phone_clean := regexp_replace(p_responsible_phone, '[^0-9]', '', 'g');
      IF length(v_responsible_phone_clean) NOT IN (10, 11) OR v_responsible_phone_clean ~ '^([0-9])\1+$' THEN
        RAISE EXCEPTION 'Telefone do responsável inválido.';
      END IF;

      v_new_responsible_phone := btrim(p_responsible_phone);
      v_applied := array_append(v_applied, 'responsible_phone');
    END IF;
  ELSE
    IF p_responsible_phone IS NOT NULL AND btrim(p_responsible_phone) != '' AND btrim(p_responsible_phone) != btrim(v_member.responsible_phone) THEN
      v_preserved := array_append(v_preserved, 'responsible_phone');
    END IF;
  END IF;

  -- 9. Processar Campo: emergency_person_name e emergency_phone
  v_new_emergency_person_name := v_member.emergency_person_name;
  v_new_emergency_phone := v_member.emergency_phone;

  -- Nome da emergência
  IF v_member.emergency_person_name IS NULL OR btrim(v_member.emergency_person_name) = '' THEN
    IF p_emergency_person_name IS NOT NULL AND btrim(p_emergency_person_name) != '' THEN
      IF length(btrim(p_emergency_person_name)) > 100 THEN
        RAISE EXCEPTION 'Nome do contato de emergência muito longo.';
      END IF;
      v_new_emergency_person_name := btrim(p_emergency_person_name);
      v_applied := array_append(v_applied, 'emergency_person_name');
    END IF;
  ELSE
    IF p_emergency_person_name IS NOT NULL AND btrim(p_emergency_person_name) != '' AND btrim(p_emergency_person_name) != btrim(v_member.emergency_person_name) THEN
      v_preserved := array_append(v_preserved, 'emergency_person_name');
    END IF;
  END IF;

  -- Telefone da emergência
  IF v_member.emergency_phone IS NULL OR btrim(v_member.emergency_phone) = '' THEN
    IF p_emergency_phone IS NOT NULL AND btrim(p_emergency_phone) != '' THEN
      IF (v_new_emergency_person_name IS NULL OR btrim(v_new_emergency_person_name) = '') THEN
        RAISE EXCEPTION 'Telefone de emergência sem nome.';
      END IF;

      v_emergency_phone_clean := regexp_replace(p_emergency_phone, '[^0-9]', '', 'g');
      IF length(v_emergency_phone_clean) NOT IN (10, 11) OR v_emergency_phone_clean ~ '^([0-9])\1+$' THEN
        RAISE EXCEPTION 'Telefone de emergência inválido.';
      END IF;

      v_new_emergency_phone := btrim(p_emergency_phone);
      v_applied := array_append(v_applied, 'emergency_phone');
    END IF;
  ELSE
    IF p_emergency_phone IS NOT NULL AND btrim(p_emergency_phone) != '' AND btrim(p_emergency_phone) != btrim(v_member.emergency_phone) THEN
      v_preserved := array_append(v_preserved, 'emergency_phone');
    END IF;
  END IF;


  -- 10. Executar o UPDATE físico apenas se houver pelo menos uma mudança
  IF cardinality(v_applied) > 0 THEN
    v_changed := true;
    UPDATE public.members AS m
    SET
      blood_type = v_new_blood_type,
      phone = v_new_phone,
      raca_cor = v_new_raca_cor,
      gender = v_new_gender,
      cid = v_new_cid,
      responsible_person_name = v_new_responsible_person_name,
      responsible_phone = v_new_responsible_phone,
      emergency_person_name = v_new_emergency_person_name,
      emergency_phone = v_new_emergency_phone,
      updated_at = now()
    WHERE m.id = p_member_id
    RETURNING
      m.blood_type,
      m.phone,
      m.raca_cor,
      m.gender,
      m.cid,
      m.responsible_person_name,
      m.responsible_phone,
      m.emergency_person_name,
      m.emergency_phone
    INTO
      v_new_blood_type,
      v_new_phone,
      v_new_raca_cor,
      v_new_gender,
      v_new_cid,
      v_new_responsible_person_name,
      v_new_responsible_phone,
      v_new_emergency_person_name,
      v_new_emergency_phone;
  ELSE
    -- Se não houver mudança, retornar os valores
    v_new_blood_type := v_member.blood_type;
    v_new_phone := v_member.phone;
    v_new_raca_cor := v_member.raca_cor;
    v_new_gender := v_member.gender;
    v_new_cid := v_member.cid;
    v_new_responsible_person_name := v_member.responsible_person_name;
    v_new_responsible_phone := v_member.responsible_phone;
    v_new_emergency_person_name := v_member.emergency_person_name;
    v_new_emergency_phone := v_member.emergency_phone;
  END IF;

  -- 11. Retornar dados unificados e consolidados
  RETURN QUERY SELECT
    p_member_id,
    v_new_blood_type,
    v_new_phone,
    v_new_raca_cor,
    v_new_gender,
    v_new_cid,
    v_new_responsible_person_name,
    v_new_responsible_phone,
    v_new_emergency_person_name,
    v_new_emergency_phone,
    v_applied,
    v_preserved,
    v_changed;
END;
$$;

COMMENT ON FUNCTION public.conectea_fill_empty_member_optional_fields_v2(
  uuid, text, text, text, text, text, text, text, text, text
) IS 'V2: Preenche de forma atômica e segura somente os campos opcionais vazios na tabela members, usando contatos estruturados.';

REVOKE ALL ON FUNCTION public.conectea_fill_empty_member_optional_fields_v2(
  uuid, text, text, text, text, text, text, text, text, text
) FROM public, anon;

GRANT EXECUTE ON FUNCTION public.conectea_fill_empty_member_optional_fields_v2(
  uuid, text, text, text, text, text, text, text, text, text
) TO authenticated;
