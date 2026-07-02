-- ConeCTEA — Migration: Create RPC update_dependent_common_data_v1
-- MIGRATION: 20260702082502_create_update_dependent_common_data_rpc_v1.sql

-- 1. Cria a RPC conectea_update_dependent_common_data_v1
CREATE OR REPLACE FUNCTION public.conectea_update_dependent_common_data_v1(
  p_member_id uuid,
  p_updates jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id uuid;
  v_current_member record;
  v_valid_keys text[] := ARRAY['social_name', 'name', 'birth_date', 'phone', 'state', 'city', 'responsible_person_name', 'responsible_phone', 'emergency_person_name', 'emergency_phone', 'gender', 'raca_cor', 'blood_type', 'cid'];
  v_forbidden_keys text[] := ARRAY['cpf', 'document', 'document_url', 'document_file_id', 'file_id', 'drive_file_id', 'drive_url', 'laudo', 'report', 'diagnosis', 'diagnostic', 'qr', 'qr_code', 'tea_id', 'card_id', 'status', 'request_status', 'card_status', 'expires_at', 'valid_until', 'validity', 'user_id', 'member_id', 'id', 'created_at', 'updated_at', 'deleted_at', 'admin_notes', 'admin_feedback', 'role', 'permission'];
  v_key text;
  v_final_resp_name text;
  v_final_resp_phone text;
  v_final_emerg_name text;
  v_final_emerg_phone text;
  v_updated_fields text[] := ARRAY[]::text[];
  v_has_digital_card boolean := false;
  v_front_data jsonb;
  v_back_data jsonb;
BEGIN
  -- 1. Validar autenticação
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  -- 2. Validar payload não nulo, tipo e se está vazio
  IF p_updates IS NULL THEN
    RAISE EXCEPTION 'invalid_payload';
  END IF;

  IF jsonb_typeof(p_updates) <> 'object' THEN
    RAISE EXCEPTION 'invalid_payload';
  END IF;

  IF p_updates = '{}'::jsonb THEN
    RAISE EXCEPTION 'invalid_payload';
  END IF;

  -- 3. Validar se todos os valores são strings ou null
  IF EXISTS (
    SELECT 1 
    FROM jsonb_each(p_updates) AS e(key, value)
    WHERE jsonb_typeof(e.value) NOT IN ('string', 'null')
  ) THEN
    RAISE EXCEPTION 'invalid_payload';
  END IF;

  -- 4. Validar chaves (allowlist e forbidden)
  FOR v_key IN SELECT jsonb_object_keys(p_updates) LOOP
    IF v_key = ANY(v_forbidden_keys) THEN
      RAISE EXCEPTION 'forbidden_field';
    ELSIF NOT (v_key = ANY(v_valid_keys)) THEN
      RAISE EXCEPTION 'unsupported_field';
    END IF;
    v_updated_fields := array_append(v_updated_fields, v_key);
  END LOOP;

  -- 4.b Validar campos essenciais se enviados
  IF p_updates ? 'name' THEN
    IF p_updates->>'name' IS NULL OR btrim(p_updates->>'name') = '' THEN
      RAISE EXCEPTION 'invalid_payload';
    END IF;
  END IF;

  IF p_updates ? 'birth_date' THEN
    IF p_updates->>'birth_date' IS NULL OR btrim(p_updates->>'birth_date') = '' THEN
      RAISE EXCEPTION 'invalid_payload';
    END IF;
    IF (p_updates->>'birth_date') !~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN
      RAISE EXCEPTION 'invalid_payload';
    END IF;
  END IF;

  IF p_updates ? 'phone' THEN
    IF p_updates->>'phone' IS NULL OR btrim(p_updates->>'phone') = '' THEN
      RAISE EXCEPTION 'invalid_payload';
    END IF;
  END IF;

  IF p_updates ? 'state' THEN
    IF p_updates->>'state' IS NULL OR btrim(p_updates->>'state') = '' THEN
      RAISE EXCEPTION 'invalid_payload';
    END IF;
  END IF;

  IF p_updates ? 'city' THEN
    IF p_updates->>'city' IS NULL OR btrim(p_updates->>'city') = '' THEN
      RAISE EXCEPTION 'invalid_payload';
    END IF;
  END IF;

  -- 5. Validar pertencimento do dependente
  SELECT * INTO v_current_member 
  FROM public.members 
  WHERE id = p_member_id AND user_id = v_user_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found';
  END IF;

  -- 6. Validar consistência de contatos (responsável e emergência)
  v_final_resp_name := btrim(COALESCE(
    CASE WHEN p_updates ? 'responsible_person_name' THEN (p_updates->>'responsible_person_name') ELSE v_current_member.responsible_person_name END,
    ''
  ));
  v_final_resp_phone := btrim(COALESCE(
    CASE WHEN p_updates ? 'responsible_phone' THEN (p_updates->>'responsible_phone') ELSE v_current_member.responsible_phone END,
    ''
  ));
  
  v_final_emerg_name := btrim(COALESCE(
    CASE WHEN p_updates ? 'emergency_person_name' THEN (p_updates->>'emergency_person_name') ELSE v_current_member.emergency_person_name END,
    ''
  ));
  v_final_emerg_phone := btrim(COALESCE(
    CASE WHEN p_updates ? 'emergency_phone' THEN (p_updates->>'emergency_phone') ELSE v_current_member.emergency_phone END,
    ''
  ));

  IF (v_final_resp_name <> '' AND v_final_resp_phone = '') OR (v_final_resp_phone <> '' AND v_final_resp_name = '') THEN
    RAISE EXCEPTION 'invalid_contact_pair';
  END IF;

  IF (v_final_emerg_name <> '' AND v_final_emerg_phone = '') OR (v_final_emerg_phone <> '' AND v_final_emerg_name = '') THEN
    RAISE EXCEPTION 'invalid_contact_pair';
  END IF;

  -- 7. Executar o UPDATE estático
  UPDATE public.members
  SET
    social_name = CASE WHEN p_updates ? 'social_name' THEN (p_updates->>'social_name') ELSE social_name END,
    name = CASE WHEN p_updates ? 'name' THEN (p_updates->>'name') ELSE name END,
    birth_date = CASE WHEN p_updates ? 'birth_date' THEN (p_updates->>'birth_date') ELSE birth_date END,
    phone = CASE WHEN p_updates ? 'phone' THEN (p_updates->>'phone') ELSE phone END,
    state = CASE WHEN p_updates ? 'state' THEN (p_updates->>'state') ELSE state END,
    city = CASE WHEN p_updates ? 'city' THEN (p_updates->>'city') ELSE city END,
    responsible_person_name = CASE WHEN p_updates ? 'responsible_person_name' THEN (p_updates->>'responsible_person_name') ELSE responsible_person_name END,
    responsible_phone = CASE WHEN p_updates ? 'responsible_phone' THEN (p_updates->>'responsible_phone') ELSE responsible_phone END,
    emergency_person_name = CASE WHEN p_updates ? 'emergency_person_name' THEN (p_updates->>'emergency_person_name') ELSE emergency_person_name END,
    emergency_phone = CASE WHEN p_updates ? 'emergency_phone' THEN (p_updates->>'emergency_phone') ELSE emergency_phone END,
    gender = CASE WHEN p_updates ? 'gender' THEN (p_updates->>'gender') ELSE gender END,
    raca_cor = CASE WHEN p_updates ? 'raca_cor' THEN (p_updates->>'raca_cor') ELSE raca_cor END,
    blood_type = CASE WHEN p_updates ? 'blood_type' THEN (p_updates->>'blood_type') ELSE blood_type END,
    cid = CASE WHEN p_updates ? 'cid' THEN (p_updates->>'cid') ELSE cid END,
    updated_at = now()
  WHERE id = p_member_id AND user_id = v_user_id;

  -- 8. Sincronizar digital_cards se existir e se houver campos de snapshot
  IF p_updates ?| ARRAY['name', 'blood_type', 'cid', 'emergency_person_name', 'emergency_phone'] THEN
    SELECT true, coalesce(front_data, '{}'::jsonb), coalesce(back_data, '{}'::jsonb)
    INTO v_has_digital_card, v_front_data, v_back_data
    FROM public.digital_cards
    WHERE member_id = p_member_id AND user_id = v_user_id;

    IF v_has_digital_card THEN
      IF p_updates ? 'name' THEN
        v_front_data := jsonb_set(v_front_data, '{name}', p_updates->'name');
      END IF;
      IF p_updates ? 'blood_type' THEN
        v_front_data := jsonb_set(v_front_data, '{bloodType}', p_updates->'blood_type');
      END IF;
      IF p_updates ? 'cid' THEN
        v_front_data := jsonb_set(v_front_data, '{cid}', p_updates->'cid');
      END IF;

      IF p_updates ? 'emergency_person_name' THEN
        v_back_data := jsonb_set(v_back_data, '{emergencyPersonName}', p_updates->'emergency_person_name');
      END IF;
      IF p_updates ? 'emergency_phone' THEN
        v_back_data := jsonb_set(v_back_data, '{emergencyPhone}', p_updates->'emergency_phone');
      END IF;

      UPDATE public.digital_cards
      SET front_data = v_front_data,
          back_data = v_back_data,
          updated_at = now()
      WHERE member_id = p_member_id AND user_id = v_user_id;
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'member_id', p_member_id,
    'updated_fields', to_jsonb(v_updated_fields)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.conectea_update_dependent_common_data_v1(uuid, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.conectea_update_dependent_common_data_v1(uuid, jsonb) TO authenticated;
