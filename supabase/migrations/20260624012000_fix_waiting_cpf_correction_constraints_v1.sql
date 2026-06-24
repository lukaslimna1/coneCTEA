-- =========================================================================
-- ConeCTEA — Correção das Constraints para Status waiting_cpf_correction
--
-- MIGRATION: 20260624012000_fix_waiting_cpf_correction_constraints_v1.sql
-- OBJETIVO:
--   - Atualizar as check constraints de public.account_change_requests para
--     suportar corretamente o status 'waiting_cpf_correction'.
--
-- CONSTRAINTS ATUALIZADAS:
--   1. chk_conectea_change_type_status: Permite 'waiting_cpf_correction' apenas para type = 'cpf'.
--   2. chk_conectea_change_closure: Trata 'waiting_cpf_correction' como status ativo (closed_at IS NULL).
--   3. chk_conectea_change_deadlines: Exige prazos do titular e sem prazos de admin para 'waiting_cpf_correction'.
--   4. chk_conectea_change_admin_decision: Exige decisão administrativa preenchida e pública para 'waiting_cpf_correction'.
-- =========================================================================

-- 1. chk_conectea_change_type_status
ALTER TABLE public.account_change_requests
  DROP CONSTRAINT IF EXISTS chk_conectea_change_type_status;

ALTER TABLE public.account_change_requests
  ADD CONSTRAINT chk_conectea_change_type_status CHECK (
    (type = 'email'::public.account_change_type AND status IN (
      'waiting_holder_confirmation'::public.account_change_status,
      'applying'::public.account_change_status,
      'application_failed'::public.account_change_status,
      'completed'::public.account_change_status,
      'cancelled_by_holder'::public.account_change_status,
      'expired'::public.account_change_status
    )) OR
    (type = 'cpf'::public.account_change_type AND status IN (
      'under_review'::public.account_change_status,
      'waiting_document_replacement'::public.account_change_status,
      'waiting_cpf_correction'::public.account_change_status,
      'waiting_holder_confirmation'::public.account_change_status,
      'applying'::public.account_change_status,
      'application_failed'::public.account_change_status,
      'completed'::public.account_change_status,
      'rejected_by_admin'::public.account_change_status,
      'cancelled_by_holder'::public.account_change_status,
      'expired'::public.account_change_status
    ))
  );

-- 2. chk_conectea_change_closure
ALTER TABLE public.account_change_requests
  DROP CONSTRAINT IF EXISTS chk_conectea_change_closure;

ALTER TABLE public.account_change_requests
  ADD CONSTRAINT chk_conectea_change_closure CHECK (
    (status IN (
      'completed'::public.account_change_status,
      'rejected_by_admin'::public.account_change_status,
      'cancelled_by_holder'::public.account_change_status,
      'expired'::public.account_change_status
    ) AND closed_at IS NOT NULL) OR
    (status IN (
      'under_review'::public.account_change_status,
      'waiting_document_replacement'::public.account_change_status,
      'waiting_cpf_correction'::public.account_change_status,
      'waiting_holder_confirmation'::public.account_change_status,
      'applying'::public.account_change_status,
      'application_failed'::public.account_change_status
    ) AND closed_at IS NULL)
  );

-- 3. chk_conectea_change_deadlines
ALTER TABLE public.account_change_requests
  DROP CONSTRAINT IF EXISTS chk_conectea_change_deadlines;

ALTER TABLE public.account_change_requests
  ADD CONSTRAINT chk_conectea_change_deadlines CHECK (
    (admin_deadline_exclusive_at IS NULL OR admin_deadline_exclusive_at > admin_deadline_started_at) AND
    (holder_deadline_exclusive_at IS NULL OR holder_deadline_exclusive_at > holder_deadline_started_at) AND

    ((admin_deadline_started_at IS NULL AND admin_deadline_exclusive_at IS NULL) OR (admin_deadline_started_at IS NOT NULL AND admin_deadline_exclusive_at IS NOT NULL)) AND
    ((holder_deadline_started_at IS NULL AND holder_deadline_exclusive_at IS NULL) OR (holder_deadline_started_at IS NOT NULL AND holder_deadline_exclusive_at IS NOT NULL)) AND

    CASE
      WHEN status = 'under_review'::public.account_change_status THEN
        type = 'cpf'::public.account_change_type AND
        admin_deadline_started_at IS NOT NULL AND
        holder_deadline_started_at IS NULL

      WHEN status IN ('waiting_document_replacement'::public.account_change_status, 'waiting_cpf_correction'::public.account_change_status) THEN
        type = 'cpf'::public.account_change_type AND
        holder_deadline_started_at IS NOT NULL AND
        admin_deadline_started_at IS NULL

      WHEN status = 'waiting_holder_confirmation'::public.account_change_status THEN
        holder_deadline_started_at IS NOT NULL AND
        admin_deadline_started_at IS NULL

      ELSE
        admin_deadline_started_at IS NULL AND
        holder_deadline_started_at IS NULL
    END
  );

-- 4. chk_conectea_change_admin_decision
ALTER TABLE public.account_change_requests
  DROP CONSTRAINT IF EXISTS chk_conectea_change_admin_decision;

ALTER TABLE public.account_change_requests
  ADD CONSTRAINT chk_conectea_change_admin_decision CHECK (
    (status NOT IN (
      'waiting_document_replacement'::public.account_change_status,
      'waiting_cpf_correction'::public.account_change_status,
      'rejected_by_admin'::public.account_change_status
    )) OR
    (
      type = 'cpf'::public.account_change_type AND
      admin_id IS NOT NULL AND
      admin_reason IS NOT NULL AND
      admin_feedback IS NOT NULL AND
      TRIM(BOTH FROM admin_feedback) <> '' AND
      public_admin_feedback IS NOT NULL
    )
  );
