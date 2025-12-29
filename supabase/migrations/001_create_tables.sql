-- ============================================================
-- AI Briefing Database Schema
-- ============================================================

-- Table 1: daily_briefings - Daily AI news summary
CREATE TABLE IF NOT EXISTS daily_briefings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    summary TEXT NOT NULL,  -- Markdown format
    audio_url VARCHAR(500),
    audio_duration INT,  -- Duration in seconds
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table 2: news_sources - RSS/Website sources for crawling
CREATE TABLE IF NOT EXISTS news_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    url VARCHAR(1000) NOT NULL,
    feed_type VARCHAR(20) NOT NULL DEFAULT 'rss',  -- rss / website / api
    category VARCHAR(50) DEFAULT 'general',
    is_active BOOLEAN DEFAULT true,
    last_crawled_at TIMESTAMPTZ,
    error_message VARCHAR(500),  -- Last crawl error if any
    scrape_config JSONB,  -- For website type: CSS selectors config
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_briefings_date ON daily_briefings(date DESC);
CREATE INDEX IF NOT EXISTS idx_sources_active ON news_sources(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_sources_feed_type ON news_sources(feed_type);

-- Enable Row Level Security
ALTER TABLE daily_briefings ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_sources ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Public read access
CREATE POLICY "Allow public read for briefings" ON daily_briefings
    FOR SELECT USING (true);

CREATE POLICY "Allow public read for sources" ON news_sources
    FOR SELECT USING (true);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_briefings_updated_at
    BEFORE UPDATE ON daily_briefings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sources_updated_at
    BEFORE UPDATE ON news_sources
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

