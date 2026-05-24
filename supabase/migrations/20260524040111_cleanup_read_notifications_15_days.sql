-- Habilita a extensão pg_cron se ainda não estiver habilitada
create extension if not exists pg_cron with schema extensions;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM cron.job
    WHERE jobname = 'cleanup_read_notifications_15_days'
  ) THEN
    PERFORM cron.unschedule('cleanup_read_notifications_15_days');
  END IF;
END $$;

-- Agenda a rotina de deleção para rodar diariamente às 03:15 UTC
select cron.schedule(
  'cleanup_read_notifications_15_days',
  '15 3 * * *',
  $$
    delete from public.notifications
    where is_read = true
      and created_at < (now() - interval '15 days');
  $$
);
