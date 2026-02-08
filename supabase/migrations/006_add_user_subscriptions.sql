-- ============================================================
-- Migration: Add user_subscriptions table for Creem payment integration
-- Tracks subscription status per user for paywall gating
-- ============================================================

-- 1. Create user_subscriptions table
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    creem_customer_id VARCHAR(100),
    creem_subscription_id VARCHAR(100),
    product_id VARCHAR(100),
    status VARCHAR(50) NOT NULL DEFAULT 'inactive',
    -- status values: active, trialing, canceled, expired, inactive
    current_period_end TIMESTAMPTZ,
    canceled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 2. Create indexes
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_creem_subscription_id ON user_subscriptions(creem_subscription_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON user_subscriptions(status);

-- 3. Enable Row Level Security
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
-- Users can only read their own subscription
CREATE POLICY "Users can read own subscription" ON user_subscriptions
    FOR SELECT USING (auth.uid() = user_id);

-- Only service role (Edge Functions) can insert/update/delete
-- No INSERT/UPDATE/DELETE policies for anon/authenticated roles
-- Edge Functions use the service_role key which bypasses RLS

-- 5. Comments
COMMENT ON TABLE user_subscriptions IS 'Tracks Creem subscription status per user for paywall gating';
COMMENT ON COLUMN user_subscriptions.status IS 'Subscription status: active, trialing, canceled, expired, inactive';
COMMENT ON COLUMN user_subscriptions.current_period_end IS 'End of current billing period - user retains access until this date even if canceled';
