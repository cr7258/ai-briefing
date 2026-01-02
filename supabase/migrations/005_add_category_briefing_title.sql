-- ============================================================
-- Migration: Add title column to category_briefings
-- ============================================================

ALTER TABLE category_briefings ADD COLUMN IF NOT EXISTS title TEXT;

COMMENT ON COLUMN category_briefings.title IS 'Title format: YYYY-MM-DD First Article Title';

