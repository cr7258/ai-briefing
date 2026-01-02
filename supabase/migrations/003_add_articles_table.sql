-- ============================================================
-- Migration: Add articles and category_briefings tables
-- Remove news_sources.category (classification is now per-article)
-- ============================================================

-- 1. Remove category column from news_sources
ALTER TABLE news_sources DROP COLUMN IF EXISTS category;

-- 2. Create articles table (stores classified articles per briefing)
CREATE TABLE IF NOT EXISTS articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    briefing_id UUID REFERENCES daily_briefings(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    summary TEXT,                     -- AI-generated one-line summary
    category VARCHAR(50) NOT NULL,   -- LLM/Agent/Multimodal/Coding/Infra/Robotics/Research/App/Industry/Cloud Native
    source_name VARCHAR(100),
    published_at TIMESTAMPTZ
);

-- 3. Create category_briefings table (stores per-category briefing + audio)
CREATE TABLE IF NOT EXISTS category_briefings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    briefing_id UUID REFERENCES daily_briefings(id) ON DELETE CASCADE,
    category VARCHAR(50) NOT NULL,
    summary TEXT NOT NULL,            -- AI-generated category briefing (Markdown)
    audio_url VARCHAR(500),
    audio_duration INT,               -- Duration in seconds
    article_count INT DEFAULT 0,
    UNIQUE(briefing_id, category)     -- One briefing per category per day
);

-- 4. Create indexes
CREATE INDEX IF NOT EXISTS idx_articles_briefing_id ON articles(briefing_id);
CREATE INDEX IF NOT EXISTS idx_articles_category ON articles(category);
CREATE INDEX IF NOT EXISTS idx_articles_url ON articles(url);
CREATE INDEX IF NOT EXISTS idx_category_briefings_briefing_id ON category_briefings(briefing_id);
CREATE INDEX IF NOT EXISTS idx_category_briefings_category ON category_briefings(category);

-- 5. Enable Row Level Security
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE category_briefings ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies: Public read access
CREATE POLICY "Allow public read for articles" ON articles
    FOR SELECT USING (true);

CREATE POLICY "Allow public read for category_briefings" ON category_briefings
    FOR SELECT USING (true);

-- 7. Comments
COMMENT ON COLUMN articles.category IS 'Article category: LLM, Agent, Multimodal, Coding, Infra, Robotics, Research, App, Industry, Cloud Native';
COMMENT ON TABLE category_briefings IS 'Per-category briefings with audio for premium experience';

