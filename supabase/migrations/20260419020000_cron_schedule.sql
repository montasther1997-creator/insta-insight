-- Reschedule the trending-audio-refresh cron with the secret inlined.
-- Previous schedule relied on app.settings.cron_secret which requires an
-- ALTER DATABASE SET that isn't reachable via supabase db push. Inlining keeps
-- setup reproducible in a single migration.

do $$
begin
  if exists (select 1 from cron.job where jobname = 'trending-audio-refresh') then
    perform cron.unschedule('trending-audio-refresh');
  end if;
end $$;

select cron.schedule(
  'trending-audio-refresh',
  '0 */12 * * *',
  $$
  select net.http_post(
    url := 'https://iixuvhjhhtfsioqhmqkx.supabase.co/functions/v1/fetch-trending-audio',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', 'a591b6e8f1209b8b4bbd173d950c1795ab033b2a967d023c'
    ),
    body := '{}'::jsonb
  );
  $$
);
