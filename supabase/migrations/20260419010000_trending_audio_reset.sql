-- Reset trending_audio to the correct schema (TikTok music id is text, not uuid).
drop table if exists public.trending_audio cascade;

create table public.trending_audio (
  id text primary key,
  audio_name text not null,
  artist_name text not null default '',
  usage_count integer not null default 0,
  growth_rate numeric not null default 0,
  country_codes text[] not null default '{}',
  is_rising boolean not null default false,
  preview_url text,
  cover_url text,
  duration integer,
  detected_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index trending_audio_usage_idx
  on public.trending_audio (usage_count desc);

create index trending_audio_updated_idx
  on public.trending_audio (updated_at desc);

alter table public.trending_audio enable row level security;

create policy "trending_audio_read_all"
  on public.trending_audio
  for select
  to anon, authenticated
  using (true);
