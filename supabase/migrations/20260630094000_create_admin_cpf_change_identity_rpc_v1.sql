-- ==============================================================================
-- MIGRATION: 20260630094000_create_admin_cpf_change_identity_rpc_v1.sql
-- PURPOSE: Create RPC for Admin to securely fetch the holder's basic identity
--          for CPF change review (Name, Social Name, Date of Birth) without
--          returning other sensitive fields.
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.conectea_admin_get_cpf_change_identity_v1(
  p_request_id uuid
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_temp'
AS $function$
DECLARE
  v_uid uuid;
  v_role text;
  v_request record;
  v_identity record;
BEGIN
  -- 1. Validate auth user
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'unauthenticated'
    );
  END IF;

  -- 2. Validate admin_master/admin_dev role
  SELECT role INTO v_role
  FROM public.profiles
  WHERE id = v_uid;

  IF v_role NOT IN ('admin_master', 'admin_dev') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'forbidden'
    );
  END IF;

  -- 3. Validate input
  IF p_request_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'invalid_request'
    );
  END IF;

  -- 4. Find the request
  SELECT id, user_id, type
  INTO v_request
  FROM public.account_change_requests
  WHERE id = p_request_id;

  IF NOT FOUND OR v_request.type <> 'cpf'::public.account_change_type THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'request_not_found'
    );
  END IF;

  -- 5. Fetch minimal identity from profiles
  SELECT name, social_name, date_of_birth
  INTO v_identity
  FROM public.profiles
  WHERE id = v_request.user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'profile_not_found'
    );
  END IF;

  -- 6. Return identity fields
  RETURN jsonb_build_object(
    'success', true,
    'name', v_identity.name,
    'social_name', v_identity.social_name,
    'date_of_birth', v_identity.date_of_birth
  );
END;
$function$;

COMMENT ON FUNCTION public.conectea_admin_get_cpf_change_identity_v1(uuid) IS
'Retrieves only name, social name, and birth date of the holder for admin CPF review context. Only accessible by admin_master and admin_dev.';

REVOKE ALL ON FUNCTION public.conectea_admin_get_cpf_change_identity_v1(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conectea_admin_get_cpf_change_identity_v1(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.conectea_admin_get_cpf_change_identity_v1(uuid) TO service_role;
