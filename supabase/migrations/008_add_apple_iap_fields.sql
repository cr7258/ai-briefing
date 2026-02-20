-- ============================================================
-- Migration: Add Apple IAP / RevenueCat fields to user_subscriptions
-- Supports dual payment channels: Creem (web) + Apple IAP (iOS)
-- ============================================================

-- 1. Add new columns
ALTER TABLE user_subscriptions
  ADD COLUMN IF NOT EXISTS subscription_source VARCHAR(20) DEFAULT 'creem',
  ADD COLUMN IF NOT EXISTS apple_original_transaction_id VARCHAR(100),
  ADD COLUMN IF NOT EXISTS revenuecat_customer_id VARCHAR(100);

-- 2. Add index for RevenueCat lookups
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_revenuecat_customer_id
  ON user_subscriptions(revenuecat_customer_id);

-- 3. Comments
COMMENT ON COLUMN user_subscriptions.subscription_source IS 'Payment source: creem (web) or apple (iOS IAP via RevenueCat)';
COMMENT ON COLUMN user_subscriptions.apple_original_transaction_id IS 'Apple original transaction ID for IAP tracking';
COMMENT ON COLUMN user_subscriptions.revenuecat_customer_id IS 'RevenueCat customer ID (set to Supabase user ID)';
