-- Migration: 20260610162200_add_structured_member_contacts.sql
-- Descrição: Adiciona colunas estruturadas de responsável e contato de emergência na tabela public.members.
-- As colunas legadas responsible_name e emergency_contact continuam existindo temporariamente para compatibilidade.

-- 1. ADICIONAR NOVAS COLUNAS
ALTER TABLE public.members
ADD COLUMN responsible_person_name text,
ADD COLUMN responsible_phone text,
ADD COLUMN emergency_person_name text,
ADD COLUMN emergency_phone text;

-- 2. ADICIONAR CONSTRAINTS CHECK PARA IMPEDIR STRINGS VAZIAS (NOT BLANK)
ALTER TABLE public.members
ADD CONSTRAINT check_responsible_person_name_not_blank
  CHECK (responsible_person_name IS NULL OR btrim(responsible_person_name) <> '');

ALTER TABLE public.members
ADD CONSTRAINT check_responsible_phone_not_blank
  CHECK (responsible_phone IS NULL OR btrim(responsible_phone) <> '');

ALTER TABLE public.members
ADD CONSTRAINT check_emergency_person_name_not_blank
  CHECK (emergency_person_name IS NULL OR btrim(emergency_person_name) <> '');

ALTER TABLE public.members
ADD CONSTRAINT check_emergency_phone_not_blank
  CHECK (emergency_phone IS NULL OR btrim(emergency_phone) <> '');

-- 3. ADICIONAR CONSTRAINTS CHECK PARA INTEGRIDADE (TELEFONE EXIGE NOME)
ALTER TABLE public.members
ADD CONSTRAINT check_responsible_phone_needs_name
  CHECK (responsible_phone IS NULL OR (responsible_person_name IS NOT NULL AND btrim(responsible_person_name) <> ''));

ALTER TABLE public.members
ADD CONSTRAINT check_emergency_phone_needs_name
  CHECK (emergency_phone IS NULL OR (emergency_person_name IS NOT NULL AND btrim(emergency_person_name) <> ''));

-- 4. ADICIONAR CONSTRAINTS CHECK PARA COMPRIMENTO MÁXIMO
ALTER TABLE public.members
ADD CONSTRAINT check_responsible_person_name_length
  CHECK (responsible_person_name IS NULL OR length(btrim(responsible_person_name)) <= 100);

ALTER TABLE public.members
ADD CONSTRAINT check_emergency_person_name_length
  CHECK (emergency_person_name IS NULL OR length(btrim(emergency_person_name)) <= 100);

ALTER TABLE public.members
ADD CONSTRAINT check_responsible_phone_length
  CHECK (responsible_phone IS NULL OR length(btrim(responsible_phone)) <= 30);

ALTER TABLE public.members
ADD CONSTRAINT check_emergency_phone_length
  CHECK (emergency_phone IS NULL OR length(btrim(emergency_phone)) <= 30);

-- 5. ADICIONAR COMENTÁRIOS EXPLICATIVOS
COMMENT ON COLUMN public.members.responsible_person_name IS 'Nome estruturado do responsável principal do membro. A coluna legada responsible_name permanece temporariamente para compatibilidade com versões antigas.';
COMMENT ON COLUMN public.members.responsible_phone IS 'Telefone estruturado do responsável principal do membro. A coluna legada responsible_name permanece temporariamente para compatibilidade com versões antigas.';
COMMENT ON COLUMN public.members.emergency_person_name IS 'Nome estruturado do contato de emergência principal do membro. A coluna legada emergency_contact permanece temporariamente para compatibilidade com versões antigas.';
COMMENT ON COLUMN public.members.emergency_phone IS 'Telefone estruturado do contato de emergência principal do membro. A coluna legada emergency_contact permanece temporariamente para compatibilidade com versões antigas.';
