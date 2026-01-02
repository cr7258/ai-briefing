-- ============================================================
-- Add more news sources
-- ============================================================

-- Remove category column from news_sources (no longer needed)
ALTER TABLE news_sources DROP COLUMN IF EXISTS category;

-- Add new sources
INSERT INTO news_sources (name, url, feed_type, is_active) VALUES
    -- LLM Official Blogs
    ('OpenAI Blog', 'https://openai.com/blog/rss.xml', 'rss', true),
    ('LMSYS Org', 'https://lmsys.org/rss.xml', 'rss', true),
    ('Google AI Blog', 'https://blog.google/technology/ai/rss/', 'rss', true),
    ('Hugging Face Blog', 'https://huggingface.co/blog/feed.xml', 'rss', true),
    
    -- Agent / Tools
    ('LangChain Blog', 'https://blog.langchain.dev/rss/', 'rss', true),
    
    -- Infrastructure
    ('NVIDIA Blog', 'https://blogs.nvidia.com/feed/', 'rss', true),
    ('vLLM Blog', 'https://blog.vllm.ai/feed.xml', 'rss', true),
    
    -- Cloud Native
    ('CNCF Blog', 'https://www.cncf.io/blog/feed/', 'rss', true),
    ('Kubernetes Blog', 'https://kubernetes.io/feed.xml', 'rss', true),
    
    -- Tech Media
    ('TechCrunch AI', 'https://techcrunch.com/category/artificial-intelligence/feed/', 'rss', true),
    ('Ars Technica', 'https://feeds.arstechnica.com/arstechnica/technology-lab', 'rss', true),
    ('MIT Tech Review AI', 'https://www.technologyreview.com/topic/artificial-intelligence/feed', 'rss', true),
    
    -- Chinese Media
    ('机器之心', 'https://www.jiqizhixin.com/rss', 'rss', true),
    ('量子位', 'https://www.qbitai.com/feed', 'rss', true)
ON CONFLICT DO NOTHING;
