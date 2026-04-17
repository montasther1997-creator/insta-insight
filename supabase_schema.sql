-- InstaInsight - Supabase Database Schema
-- Run this in Supabase SQL Editor to create the required tables

-- ============================================
-- 1. Users table
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  instagram_id TEXT UNIQUE NOT NULL,
  username TEXT NOT NULL DEFAULT '',
  full_name TEXT NOT NULL DEFAULT '',
  profile_picture_url TEXT DEFAULT '',
  access_token TEXT NOT NULL,
  token_expires_at TIMESTAMPTZ,
  followers_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookup by instagram_id
CREATE INDEX IF NOT EXISTS idx_users_instagram_id ON users(instagram_id);

-- ============================================
-- 2. Posts table (cached media data)
-- ============================================
CREATE TABLE IF NOT EXISTS posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  post_id TEXT NOT NULL,
  media_type TEXT DEFAULT 'IMAGE',
  thumbnail_url TEXT DEFAULT '',
  views_count INTEGER DEFAULT 0,
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  engagement_rate DOUBLE PRECISION DEFAULT 0.0,
  posted_at TIMESTAMPTZ,
  gemini_analysis TEXT,
  analyzed_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);

-- ============================================
-- 3. Reports table (weekly/analysis reports)
-- ============================================
CREATE TABLE IF NOT EXISTS reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  engagement_rate DOUBLE PRECISION DEFAULT 0.0,
  followers_growth INTEGER DEFAULT 0,
  best_post_id TEXT,
  worst_post_id TEXT,
  gemini_summary TEXT,
  geo_breakdown JSONB,
  posting_heatmap JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reports_user_id ON reports(user_id);

-- ============================================
-- 4. Trending Audio table
-- ============================================
CREATE TABLE IF NOT EXISTS trending_audio (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  audio_name TEXT NOT NULL DEFAULT '',
  artist_name TEXT NOT NULL DEFAULT '',
  usage_count INTEGER DEFAULT 0,
  growth_rate DOUBLE PRECISION DEFAULT 0.0,
  country_codes TEXT[] DEFAULT '{}',
  is_rising BOOLEAN DEFAULT false,
  detected_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trending_audio_growth ON trending_audio(growth_rate DESC);

-- ============================================
-- 5. Suggestions table
-- ============================================
CREATE TABLE IF NOT EXISTS suggestions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT '',
  description TEXT DEFAULT '',
  reason TEXT DEFAULT '',
  priority TEXT DEFAULT 'medium',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_suggestions_user_id ON suggestions(user_id);

-- ============================================
-- Row Level Security (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE trending_audio ENABLE ROW LEVEL SECURITY;

-- Users: allow read/write via anon key (app manages auth via Instagram OAuth)
CREATE POLICY "Allow all operations on users" ON users
  FOR ALL USING (true) WITH CHECK (true);

-- Posts: allow all via anon key
CREATE POLICY "Allow all operations on posts" ON posts
  FOR ALL USING (true) WITH CHECK (true);

-- Reports: allow all via anon key
CREATE POLICY "Allow all operations on reports" ON reports
  FOR ALL USING (true) WITH CHECK (true);

-- Suggestions: allow all via anon key
CREATE POLICY "Allow all operations on suggestions" ON suggestions
  FOR ALL USING (true) WITH CHECK (true);

-- Trending audio: read-only for anon, admin manages data
CREATE POLICY "Allow read on trending_audio" ON trending_audio
  FOR SELECT USING (true);
