ALTER TABLE public.members ADD COLUMN IF NOT EXISTS tea_relation_type text DEFAULT NULL;

COMMENT ON COLUMN public.members.tea_relation_type IS 'Tipo de vínculo do beneficiário com o universo TEA. Valores esperados: pessoa_tea e rede_apoio_tea. Pessoa TEA mantém validação documental. Rede de Apoio TEA representa familiares/responsáveis/rede de apoio e não exige laudo neste fluxo.';
