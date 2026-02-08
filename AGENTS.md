# AI Briefing - Development Notes

## Architecture Overview

```
Flutter Web App (Vercel: ai-briefing.vercel.app)
    ↕ Supabase Dart SDK
Supabase
    ├── Auth (GitHub OAuth)
    ├── Database (PostgreSQL)
    ├── Edge Functions (Deno/TypeScript)
    └── Storage (audio files)

Rust Backend (GitHub Actions cron, daily 05:00 Beijing time)
    → RSS crawler + OpenAI summarizer + TTS
    → Writes to Supabase DB + Storage

Creem (Payment provider)
    → Webhook → Supabase Edge Function → DB
```

## Payment / Subscription System (Creem)

### Supabase Edge Functions

Three Edge Functions in `supabase/functions/`:

| Function | Purpose | JWT Verify |
|----------|---------|------------|
| `create-checkout` | Creates Creem checkout session, returns payment URL | `--no-verify-jwt` (auth handled in code) |
| `creem-webhook` | Receives Creem webhook events, updates subscription status | `--no-verify-jwt` (Creem has no Supabase JWT) |
| `customer-portal` | Generates Creem billing portal link for subscription management | `--no-verify-jwt` (auth handled in code) |

Shared utilities in `supabase/functions/_shared/`:
- `creem.ts` - Creem API helpers (base URL, headers, HMAC-SHA256 signature verification)
- `cors.ts` - CORS headers for Flutter Web client
- `supabase.ts` - Service-role and user-scoped Supabase clients

### Database

`user_subscriptions` table (migration: `006_add_user_subscriptions.sql`):
- `user_id` (FK to auth.users, unique)
- `creem_customer_id`, `creem_subscription_id`, `product_id`
- `status`: active, trialing, canceled, expired, inactive
- `current_period_end`, `canceled_at`
- RLS: users can only SELECT their own row; Edge Functions use service_role to INSERT/UPDATE

### Subscription Status Logic

- `active` or `trialing` → access granted
- `canceled` + `current_period_end` in future → access granted (until period ends)
- `expired` or `inactive` or no record → access denied, paywall shown

### Environment Variables (Supabase Edge Function Secrets)

```
CREEM_API_KEY          - Creem API key
CREEM_WEBHOOK_SECRET   - Webhook signing secret (HMAC-SHA256)
CREEM_PRODUCT_ID       - Creem product ID for the subscription
CREEM_TEST_MODE        - "true" for sandbox, "false" for production
```

### Webhook Events Handled

- `checkout.completed` → create subscription record (status=active)
- `subscription.active` / `subscription.paid` → grant access
- `subscription.trialing` → grant access (trial)
- `subscription.canceled` → keep access until period end
- `subscription.expired` → revoke access
- `subscription.paused` → pause access
- `refund.created` → revoke access

## Flutter App Structure

### Key Files

- `lib/models/subscription.dart` - UserSubscription model with `isActive`, `isCanceled` getters
- `lib/services/subscription_service.dart` - Queries DB + invokes Edge Functions
- `lib/providers/subscription_provider.dart` - Riverpod providers (`hasActiveSubscriptionProvider`)
- `lib/screens/paywall_screen.dart` - Modal bottom sheet with pricing + checkout button
- `lib/screens/settings_screen.dart` - Subscription status, manage billing, account info
- `lib/widgets/subscription_gate.dart` - Intercepts navigation, shows paywall if not subscribed

### Content Gating

- Latest/featured briefing: **always free** (hero card on home screen)
- Past briefings (list tiles): **require subscription** (gated via `SubscriptionGate`)
- Category briefings (list tiles): **require subscription**
- Settings page: accessible from avatar dropdown menu (logged-in users)

### Auth Flow

- OAuth via GitHub (Supabase Auth)
- `auth_service.dart`: redirect URL is `Uri.base.origin` in debug mode (localhost), `null` in production (uses Supabase Site URL)
- Paywall handles login-first flow: if not logged in, shows auth dialog before creating checkout

## Deployment

### Deploy Edge Functions

```bash
cd /Users/sevenc/code/ai/ai-briefing
supabase functions deploy create-checkout --no-verify-jwt
supabase functions deploy creem-webhook --no-verify-jwt
supabase functions deploy customer-portal --no-verify-jwt
```

### Database Migration

Run `supabase/migrations/006_add_user_subscriptions.sql` in Supabase SQL Editor (previous migrations 001-005 were run manually, not tracked in schema_migrations).

### Creem Webhook URL

```
https://<project-ref>.supabase.co/functions/v1/creem-webhook
```

### Flutter Web

```bash
cd app
flutter build web
# Deploy build/web to Vercel (auto-deploys on git push)
```

### Local Development

```bash
# Flutter Web with fixed port (for OAuth redirect)
cd app
flutter run -d chrome --web-port=3000

# Supabase Dashboard → Auth → URL Configuration → Redirect URLs:
# Add http://localhost:3000

# Edge Functions local
supabase functions serve --env-file supabase/.env.local

# Webhook tunnel (for local testing)
ngrok http 54321
# Then set ngrok URL as webhook in Creem Dashboard
```

### Supabase .env.local (for local Edge Function testing)

```
CREEM_API_KEY=xxx
CREEM_WEBHOOK_SECRET=xxx
CREEM_PRODUCT_ID=xxx
CREEM_TEST_MODE=true
```

## Design

- OLED dark theme (pure black background)
- Fonts: Space Grotesk (headings), DM Sans (body)
- Primary: #1ED760 (Spotify green), Accent: #00D4FF (cyan), Purple: #7C3AED
- See `app/lib/theme/app_theme.dart` for full color palette
