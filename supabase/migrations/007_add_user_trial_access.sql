-- Track free trial access for non-subscribed users (max 3 unique briefings)
CREATE TABLE user_trial_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content_type TEXT NOT NULL CHECK (content_type IN ('daily_briefing', 'category_briefing')),
  content_id UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, content_type, content_id)
);

-- Index for fast lookups
CREATE INDEX idx_user_trial_access_user_id ON user_trial_access(user_id);

ALTER TABLE user_trial_access ENABLE ROW LEVEL SECURITY;

-- Users can read their own trial records
CREATE POLICY "Users can view own trial access"
  ON user_trial_access FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own trial records
CREATE POLICY "Users can insert own trial access"
  ON user_trial_access FOR INSERT
  WITH CHECK (auth.uid() = user_id);
