-- ============================================================
-- Seed data: Default news sources
-- ============================================================

INSERT INTO news_sources (name, url, feed_type, category) VALUES
    -- Tech News RSS
    ('TechCrunch AI', 'https://techcrunch.com/category/artificial-intelligence/feed/', 'rss', 'news'),
    ('The Verge AI', 'https://www.theverge.com/ai-artificial-intelligence/rss/index.xml', 'rss', 'news'),
    ('VentureBeat AI', 'https://venturebeat.com/category/ai/feed/', 'rss', 'news'),
    ('AI News', 'https://www.artificialintelligence-news.com/feed/', 'rss', 'news'),
    
    -- Community
    ('Hacker News AI', 'https://hnrss.org/newest?q=AI+OR+LLM+OR+GPT', 'rss', 'community'),
    
    -- Official Blogs
    ('OpenAI Blog', 'https://openai.com/blog/rss/', 'rss', 'blog'),
    ('Hugging Face Blog', 'https://huggingface.co/blog/feed.xml', 'rss', 'blog'),
    ('vLLM Blog', 'https://blog.vllm.ai/feed.xml', 'rss', 'blog')
ON CONFLICT DO NOTHING;

