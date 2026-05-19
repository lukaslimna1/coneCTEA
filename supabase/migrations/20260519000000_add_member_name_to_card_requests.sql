-- 1. Add column
ALTER TABLE public.card_requests ADD COLUMN IF NOT EXISTS member_name text;

-- 2. Backfill existing records
UPDATE public.card_requests cr
SET member_name = m.name
FROM public.members m
WHERE cr.member_id = m.id;

-- 3. Function and Trigger for INSERT/UPDATE on card_requests
CREATE OR REPLACE FUNCTION public.sync_card_request_member_name()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.member_id IS NOT NULL THEN
    NEW.member_name := (SELECT name FROM public.members WHERE id = NEW.member_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_sync_card_request_member_name ON public.card_requests;
CREATE TRIGGER tr_sync_card_request_member_name
BEFORE INSERT OR UPDATE OF member_id
ON public.card_requests
FOR EACH ROW
EXECUTE FUNCTION public.sync_card_request_member_name();

-- 4. Function and Trigger for UPDATE on members
CREATE OR REPLACE FUNCTION public.propagate_member_name_to_card_requests()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.name IS DISTINCT FROM OLD.name THEN
    UPDATE public.card_requests
    SET member_name = NEW.name
    WHERE member_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_propagate_member_name_to_card_requests ON public.members;
CREATE TRIGGER tr_propagate_member_name_to_card_requests
AFTER UPDATE OF name
ON public.members
FOR EACH ROW
EXECUTE FUNCTION public.propagate_member_name_to_card_requests();
