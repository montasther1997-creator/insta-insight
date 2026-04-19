// Supabase Edge Function: fetch-trending-audio
// Pulls the TikTok feed via RapidAPI (tikwm tiktok-scraper7), aggregates by music id
// to identify trending audio, and upserts the top 20 into public.trending_audio.
//
// Invoked by pg_cron every 12h (see migration 20260419_trending_audio.sql).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

const RAPIDAPI_HOST = 'tiktok-scraper7.p.rapidapi.com';
const FEED_URL = `https://${RAPIDAPI_HOST}/feed/list`;

type MusicInfo = {
  id: string;
  title?: string;
  play?: string;
  cover?: string;
  author?: string;
  original?: boolean;
  duration?: number;
  album?: string;
};

type FeedItem = {
  music_info?: MusicInfo;
  music?: MusicInfo;
  play_count?: number;
  digg_count?: number;
  comment_count?: number;
  share_count?: number;
  region?: string;
};

type FeedResponse = {
  code: number;
  msg: string;
  data?: FeedItem[];
};

type Aggregate = {
  id: string;
  title: string;
  author: string;
  cover: string;
  play: string;
  duration: number;
  count: number;
  engagement: number;
  countries: Set<string>;
};

async function fetchFeed(
  apiKey: string,
  region: string,
  count: number,
): Promise<FeedItem[]> {
  const r = await fetch(`${FEED_URL}?region=${region}&count=${count}`, {
    headers: {
      'x-rapidapi-key': apiKey,
      'x-rapidapi-host': RAPIDAPI_HOST,
    },
  });
  if (!r.ok) throw new Error(`RapidAPI ${r.status}: ${await r.text()}`);
  const j = (await r.json()) as FeedResponse;
  if (j.code !== 0) throw new Error(`RapidAPI error: ${j.msg}`);
  return j.data ?? [];
}

function aggregate(items: FeedItem[], out: Map<string, Aggregate>) {
  for (const v of items) {
    const m = v.music_info ?? v.music;
    if (!m?.id || !m.title) continue;
    if (m.original === true) continue; // skip original sounds — usually one-off.
    // Titles like "original sound - username" still leak through even when the
    // `original` flag is false, so filter them by name too.
    if (/^original sound\b/i.test(m.title)) continue;

    const engagement =
      (v.play_count ?? 0) +
      (v.digg_count ?? 0) * 2 +
      (v.comment_count ?? 0) * 3 +
      (v.share_count ?? 0) * 4;

    const existing = out.get(m.id);
    if (existing) {
      existing.count += 1;
      existing.engagement += engagement;
      if (v.region) existing.countries.add(v.region);
    } else {
      out.set(m.id, {
        id: m.id,
        title: m.title ?? '',
        author: m.author ?? '',
        cover: m.cover ?? '',
        play: m.play ?? '',
        duration: m.duration ?? 0,
        count: 1,
        engagement,
        countries: new Set(v.region ? [v.region] : []),
      });
    }
  }
}

Deno.serve(async (req) => {
  // Simple shared-secret gate so this isn't open to the internet.
  const expected = Deno.env.get('CRON_SECRET');
  const got = req.headers.get('x-cron-secret');
  if (expected && got !== expected) {
    return new Response(JSON.stringify({ error: 'forbidden' }), {
      status: 403,
      headers: { 'content-type': 'application/json' },
    });
  }

  const rapidKey = Deno.env.get('RAPIDAPI_KEY');
  if (!rapidKey) {
    return new Response(JSON.stringify({ error: 'RAPIDAPI_KEY not set' }), {
      status: 500,
      headers: { 'content-type': 'application/json' },
    });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRole = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const supabase = createClient(supabaseUrl, serviceRole, {
    auth: { persistSession: false },
  });

  // IQ is the primary audience. Its /feed/list is thin (mostly "original
  // sound" clips that get filtered out), so we also pull US + SA so the
  // aggregated list always reaches the ~20 tracks the UI expects.
  // Budget: 3 calls × 2 runs/day × 30 = 180/month.
  const regions = ['IQ', 'US', 'SA'];
  const agg = new Map<string, Aggregate>();
  const regionsUsed: string[] = [];

  try {
    for (const region of regions) {
      const items = await fetchFeed(rapidKey, region, 100);
      aggregate(items, agg);
      regionsUsed.push(region);
      // Stop early once we have enough unique tracks to pick a top-20 from.
      if (agg.size >= 25) break;
    }
  } catch (e) {
    // If we already got *some* tracks from an earlier region, keep going —
    // a partial snapshot is better than wiping the table on a flaky call.
    if (agg.size === 0) {
      return new Response(
        JSON.stringify({ error: 'fetch failed', detail: `${e}` }),
        {
          status: 502,
          headers: { 'content-type': 'application/json' },
        },
      );
    }
  }

  // Sort by (count desc, engagement desc). Tracks used by >= 2 videos are "rising".
  const top = [...agg.values()]
    .sort((a, b) => b.count - a.count || b.engagement - a.engagement)
    .slice(0, 20);

  const now = new Date().toISOString();
  const rows = top.map((t, idx) => ({
    id: t.id,
    audio_name: t.title,
    artist_name: t.author,
    usage_count: t.count,
    growth_rate: Math.max(0, 100 - idx * 4),
    country_codes: [...t.countries],
    is_rising: t.count >= 2,
    preview_url: t.play || null,
    cover_url: t.cover || null,
    duration: t.duration,
    detected_at: now,
    updated_at: now,
  }));

  // Replace the previous snapshot so old entries don't linger.
  const { error: delErr } = await supabase
    .from('trending_audio')
    .delete()
    .neq('id', '');
  if (delErr) {
    return new Response(
      JSON.stringify({ error: 'delete failed', detail: delErr.message }),
      {
        status: 500,
        headers: { 'content-type': 'application/json' },
      },
    );
  }

  const { error: upErr } = await supabase.from('trending_audio').insert(rows);
  if (upErr) {
    return new Response(
      JSON.stringify({ error: 'insert failed', detail: upErr.message }),
      {
        status: 500,
        headers: { 'content-type': 'application/json' },
      },
    );
  }

  return new Response(
    JSON.stringify({
      ok: true,
      inserted: rows.length,
      regions_used: regionsUsed,
      at: now,
    }),
    { headers: { 'content-type': 'application/json' } },
  );
});
