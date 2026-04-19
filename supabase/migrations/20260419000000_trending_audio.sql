-- Trending audio table — populated every 12h by the fetch-trending-audio Edge Function.
create table if not exists public.trending_audio (
  id text primary key,
  audio_name text not null,
  artist_name text not null default '',
  usage_count integer not null default 0,
  growth_rate numeric not null default 0,
  country_codes text[] not null default '{}',
  is_rising boolean not null default false,
  detected_at timestamptz not null default now()
);

-- Additive columns so an older schema upgrades cleanly.
alter table public.trending_audio add column if not exists preview_url text;
alter table public.trending_audio add column if not exists cover_url text;
alter table public.trending_audio add column if not exists duration integer;
alter table public.trending_audio add column if not exists updated_at timestamptz not null default now();

create index if not exists trending_audio_usage_idx
  on public.trending_audio (usage_count desc);

create index if not exists trending_audio_updated_idx
  on public.trending_audio (updated_at desc);

-- Public read, no writes (only the service role — used by the Edge Function — can write).
alter table public.trending_audio enable row level security;

drop policy if exists "trending_audio_read_all" on public.trending_audio;
create policy "trending_audio_read_all"
  on public.trending_audio
  for select
  to anon, authenticated
  using (true);

-- pg_cron / pg_net for the 12-hour refresh schedule.
create extension if not exists pg_cron with schema extensions;
create extension if not exists pg_net with schema extensions;

do $$
begin
  if exists (select 1 from cron.job where jobname = 'trending-audio-refresh') then
    perform cron.unschedule('trending-audio-refresh');
  end if;
end $$;

-- Runs at 00:00 and 12:00 UTC daily. The function verifies the x-cron-secret header.
select cron.schedule(
  'trending-audio-refresh',
  '0 */12 * * *',
  $$
  select net.http_post(
    url := 'https://iixuvhjhhtfsioqhmqkx.supabase.co/functions/v1/fetch-trending-audio',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', coalesce(current_setting('app.settings.cron_secret', true), '')
    ),
    body := '{}'::jsonb
  );
  $$
);
