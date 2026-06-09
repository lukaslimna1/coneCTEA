-- ConeCTEA — Migration: RPC para Preenchimento Atômico de Campos Opcionais Vazios
-- MIGRATION: 20260609000000_add_conectea_fill_empty_member_optional_fields.sql
--
-- Regras de Negócio:
-- 1. Preenche somente os campos opcionais do membro que ainda estejam nulos, vazios ou com espaços.
-- 2. Nunca sobrescreve valores válidos já preenchidos remotamente.
-- 3. Valida no servidor cada campo contra as allowlists oficiais definidas no projeto.
-- 4. Operação totalmente transacional e atômica.
-- 5. Atualiza o updated_at somente se houver mudança real.
-- 6. Não expõe dados sensíveis (como CPF ou URLs de documentos) no retorno.
--
-- STATUS: Criação de migration local. Não aplicar no banco remoto sem autorização.
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. RPC: conectea_fill_empty_member_optional_fields
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.conectea_fill_empty_member_optional_fields(
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
  responsible_name text,
  emergency_contact text,
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
  v_new_responsible_name text;
  v_new_emergency_contact text;

  v_changed boolean := false;
  v_clean_phone text;

  -- Variáveis de processamento de contatos compostos (DECLARE principal)
  v_responsible_composed text;
  v_responsible_phone_clean text;
  v_emergency_composed text;
  v_emergency_phone_clean text;
BEGIN
  -- 1. Validar login do usuário
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Operação não autorizada.';
  END IF;

  -- 2. Obter o registro atual com bloqueio de concorrência (FOR UPDATE) restrito ao proprietário
  -- O FOR UPDATE previne race conditions de escrita concorrente sobre a mesma linha
  SELECT *
  INTO v_member
  FROM public.members
  WHERE id = p_member_id
    AND user_id = auth.uid()
  FOR UPDATE;

  IF v_member.id IS NULL THEN
    RAISE EXCEPTION 'Membro não encontrado ou acesso não autorizado.';
  END IF;

  -- 3. Processar Campo: blood_type (Tipo Sanguíneo)
  -- Compatibilidade com UI e PDF: validação contra allowlist e btrim
  -- Nota: "Não sei" e "Prefiro não informar" são rejeitados de acordo com a regra restrita de impressão
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

  -- 4. Processar Campo: phone (Telefone do Beneficiário)
  -- Consistência cadastral: validação contra número de dígitos (DDD + 8 ou 9 dígitos)
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

  -- 5. Processar Campo: raca_cor (Raça/Cor IBGE)
  -- Compatibilidade com UI e PDF: validação contra allowlist e btrim
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

  -- 6. Processar Campo: gender (Gênero)
  -- Compatibilidade com UI e PDF: validação contra allowlist e btrim
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

  -- 7. Processar Campo: cid (CID do beneficiário)
  -- Prevenção de payload excessivo: limitação a 20 caracteres
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

  -- 8. Processar Campo: responsible_name (Nome do Responsável Principal)
  -- Prevenção de payload excessivo, compatibilidade com UI e PDF: validação separada de nome e telefone
  IF v_member.responsible_name IS NULL OR btrim(v_member.responsible_name) = '' THEN
    IF (p_responsible_person_name IS NOT NULL AND btrim(p_responsible_person_name) != '') OR
       (p_responsible_phone IS NOT NULL AND btrim(p_responsible_phone) != '') THEN

      -- Se o telefone for informado, o nome do responsável é obrigatório
      IF p_responsible_phone IS NOT NULL AND btrim(p_responsible_phone) != '' THEN
        v_responsible_phone_clean := regexp_replace(p_responsible_phone, '[^0-9]', '', 'g');
        IF length(v_responsible_phone_clean) NOT IN (10, 11) OR v_responsible_phone_clean ~ '^([0-9])\1+$' THEN
          RAISE EXCEPTION 'Telefone do responsável inválido.';
        END IF;

        IF p_responsible_person_name IS NULL OR btrim(p_responsible_person_name) = '' THEN
          RAISE EXCEPTION 'Nome do responsável obrigatório.';
        END IF;

        IF length(btrim(p_responsible_person_name)) > 100 THEN
          RAISE EXCEPTION 'Nome do responsável muito longo.';
        END IF;

        v_responsible_composed := btrim(p_responsible_person_name) || ' - ' || btrim(p_responsible_phone);
      ELSE
        IF length(btrim(p_responsible_person_name)) > 100 THEN
          RAISE EXCEPTION 'Nome do responsável muito longo.';
        END IF;
        v_responsible_composed := btrim(p_responsible_person_name);
      END IF;

      IF length(v_responsible_composed) > 150 THEN
        RAISE EXCEPTION 'Contato do responsável muito longo.';
      END IF;

      v_new_responsible_name := v_responsible_composed;
      v_applied := array_append(v_applied, 'responsible_name');
    ELSE
      v_new_responsible_name := v_member.responsible_name;
    END IF;
  ELSE
    v_new_responsible_name := v_member.responsible_name;
    -- Validar preserved sem concatenar nulls
    IF (p_responsible_person_name IS NOT NULL AND btrim(p_responsible_person_name) != '') OR
       (p_responsible_phone IS NOT NULL AND btrim(p_responsible_phone) != '') THEN

      v_responsible_composed := COALESCE(btrim(p_responsible_person_name), '');
      IF p_responsible_phone IS NOT NULL AND btrim(p_responsible_phone) != '' THEN
        IF p_responsible_person_name IS NOT NULL AND btrim(p_responsible_person_name) != '' THEN
          v_responsible_composed := btrim(p_responsible_person_name) || ' - ' || btrim(p_responsible_phone);
        ELSE
          -- Se enviou apenas telefone mas o campo remoto já está preenchido, tratamos como tentativa incompatível
          v_responsible_composed := btrim(p_responsible_phone);
        END IF;
      END IF;

      IF btrim(v_responsible_composed) != btrim(v_member.responsible_name) THEN
        v_preserved := array_append(v_preserved, 'responsible_name');
      END IF;
    END IF;
  END IF;

  -- 9. Processar Campo: emergency_contact (Contato de Emergência Principal)
  -- Prevenção de payload excessivo, compatibilidade com UI e PDF: validação separada de nome e telefone
  IF v_member.emergency_contact IS NULL OR btrim(v_member.emergency_contact) = '' THEN
    IF (p_emergency_person_name IS NOT NULL AND btrim(p_emergency_person_name) != '') OR
       (p_emergency_phone IS NOT NULL AND btrim(p_emergency_phone) != '') THEN

      -- Se o telefone for informado, o nome do contato de emergência é obrigatório
      IF p_emergency_phone IS NOT NULL AND btrim(p_emergency_phone) != '' THEN
        v_emergency_phone_clean := regexp_replace(p_emergency_phone, '[^0-9]', '', 'g');
        IF length(v_emergency_phone_clean) NOT IN (10, 11) OR v_emergency_phone_clean ~ '^([0-9])\1+$' THEN
          RAISE EXCEPTION 'Telefone de emergência inválido.';
        END IF;

        IF p_emergency_person_name IS NULL OR btrim(p_emergency_person_name) = '' THEN
          RAISE EXCEPTION 'Nome do contato de emergência obrigatório.';
        END IF;

        IF length(btrim(p_emergency_person_name)) > 100 THEN
          RAISE EXCEPTION 'Nome do contato de emergência muito longo.';
        END IF;

        v_emergency_composed := btrim(p_emergency_person_name) || ' - ' || btrim(p_emergency_phone);
      ELSE
        IF length(btrim(p_emergency_person_name)) > 100 THEN
          RAISE EXCEPTION 'Nome do contato de emergência muito longo.';
        END IF;
        v_emergency_composed := btrim(p_emergency_person_name);
      END IF;

      IF length(v_emergency_composed) > 150 THEN
        RAISE EXCEPTION 'Contato de emergência muito longo.';
      END IF;

      v_new_emergency_contact := v_emergency_composed;
      v_applied := array_append(v_applied, 'emergency_contact');
    ELSE
      v_new_emergency_contact := v_member.emergency_contact;
    END IF;
  ELSE
    v_new_emergency_contact := v_member.emergency_contact;
    -- Validar preserved sem concatenar nulls
    IF (p_emergency_person_name IS NOT NULL AND btrim(p_emergency_person_name) != '') OR
       (p_emergency_phone IS NOT NULL AND btrim(p_emergency_phone) != '') THEN

      v_emergency_composed := COALESCE(btrim(p_emergency_person_name), '');
      IF p_emergency_phone IS NOT NULL AND btrim(p_emergency_phone) != '' THEN
        IF p_emergency_person_name IS NOT NULL AND btrim(p_emergency_person_name) != '' THEN
          v_emergency_composed := btrim(p_emergency_person_name) || ' - ' || btrim(p_emergency_phone);
        ELSE
          v_emergency_composed := btrim(p_emergency_phone);
        END IF;
      END IF;

      IF btrim(v_emergency_composed) != btrim(v_member.emergency_contact) THEN
        v_preserved := array_append(v_preserved, 'emergency_contact');
      END IF;
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
      responsible_name = v_new_responsible_name,
      emergency_contact = v_new_emergency_contact,
      updated_at = now()
    WHERE m.id = p_member_id
    RETURNING
      m.blood_type,
      m.phone,
      m.raca_cor,
      m.gender,
      m.cid,
      m.responsible_name,
      m.emergency_contact
    INTO
      v_new_blood_type,
      v_new_phone,
      v_new_raca_cor,
      v_new_gender,
      v_new_cid,
      v_new_responsible_name,
      v_new_emergency_contact;
  ELSE
    -- Se não houver mudança, retornar os valores já carregados em v_member
    v_new_blood_type := v_member.blood_type;
    v_new_phone := v_member.phone;
    v_new_raca_cor := v_member.raca_cor;
    v_new_gender := v_member.gender;
    v_new_cid := v_member.cid;
    v_new_responsible_name := v_member.responsible_name;
    v_new_emergency_contact := v_member.emergency_contact;
  END IF;

  -- 11. Retornar dados unificados e consolidados seguros
  RETURN QUERY SELECT
    p_member_id,
    v_new_blood_type,
    v_new_phone,
    v_new_raca_cor,
    v_new_gender,
    v_new_cid,
    v_new_responsible_name,
    v_new_emergency_contact,
    v_applied,
    v_preserved,
    v_changed;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. COMENTÁRIO TÉCNICO DE AUDITORIA E DOCUMENTAÇÃO
-- ─────────────────────────────────────────────────────────────────────────

COMMENT ON FUNCTION public.conectea_fill_empty_member_optional_fields(
  uuid, text, text, text, text, text, text, text, text, text
) IS 'Preenche de forma atômica e segura somente os campos cadastrais opcionais vazios na tabela members, validando allowlists para consistência cadastral, prevenção de payload excessivo, compatibilidade com UI e PDF, e redução de dados indevidos.';

-- ─────────────────────────────────────────────────────────────────────────
-- 3. SEGURANÇA E GRANTS (RESTRITO A USUÁRIOS AUTENTICADOS)
-- ─────────────────────────────────────────────────────────────────────────

-- Revogar qualquer execução implícita de roles públicas e anônimas
REVOKE ALL ON FUNCTION public.conectea_fill_empty_member_optional_fields(
  uuid, text, text, text, text, text, text, text, text, text
) FROM public, anon;

-- Conceder execução exclusivamente para a role authenticated
GRANT EXECUTE ON FUNCTION public.conectea_fill_empty_member_optional_fields(
  uuid, text, text, text, text, text, text, text, text, text
) TO authenticated;
