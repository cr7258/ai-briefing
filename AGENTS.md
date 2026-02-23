# AI Briefing - Development Guide

> **IMPORTANT**: After making any code changes (new files, renamed modules, updated dependencies, changed architecture, modified environment variables, etc.), always check whether this file needs to be updated to stay in sync with the codebase.

## Architecture Overview

The project has three main components:

1. **Rust Backend** - Runs daily via GitHub Actions cron. Crawls RSS feeds, generates AI summaries (OpenAI), synthesizes audio (Volcengine TTS), uploads audio to Volcengine TOS, and writes data to Supabase PostgreSQL.
2. **Flutter App** - Web deployed on Vercel, iOS via App Store. Reads data directly from Supabase (no backend API). Uses Supabase Auth (Google + GitHub + Apple OAuth) and Riverpod for state management. Dual payment: Creem (web) + Apple IAP via RevenueCat (iOS).
3. **Supabase** - Hosts PostgreSQL database, Auth (Google + GitHub + Apple OAuth), and Edge Functions (Deno/TypeScript) for Creem payment and RevenueCat webhook integration.

```
Rust Backend (GitHub Actions cron, daily 05:00 Beijing / 21:00 UTC)
    → RSS crawler + OpenAI summarizer + Volcengine TTS
    → Writes to Supabase DB + Volcengine TOS (audio)

Flutter App
    ├── Web (Vercel: app.ai-briefing.cc) → Creem for payments
    └── iOS (App Store) → Apple IAP via RevenueCat for payments
    ↕ Supabase Dart SDK (direct DB reads, Auth, Edge Function calls)

Supabase
    ├── Auth (Google + GitHub + Apple OAuth)
    ├── Database (PostgreSQL)
    └── Edge Functions (Deno/TypeScript)
        ├── Creem payment (web)
        └── RevenueCat webhook (iOS Apple IAP)

Creem (Web payment provider)
    → Webhook → Supabase Edge Function → DB

RevenueCat (iOS payment management)
    → Apple IAP → RevenueCat Server → Webhook → Supabase Edge Function → DB
```

---

## Project Structure

```
ai-briefing/
├── backend/                          # Rust backend (GitHub Actions)
│   ├── Cargo.toml
│   ├── env.example
│   └── src/
│       ├── main.rs
│       ├── config.rs
│       ├── crawler/
│       │   ├── mod.rs
│       │   └── rss.rs               # RSS feed crawler (feed-rs)
│       ├── db/
│       │   ├── mod.rs
│       │   └── repository.rs        # SeaORM database operations
│       ├── entity/
│       │   ├── mod.rs
│       │   ├── article.rs
│       │   ├── category_briefing.rs
│       │   ├── daily_briefing.rs
│       │   └── news_source.rs
│       ├── jobs/
│       │   ├── mod.rs
│       │   └── daily_briefing.rs     # Main daily job orchestration
│       ├── storage/
│       │   ├── mod.rs
│       │   └── audio.rs             # Volcengine TOS upload
│       ├── summarizer/
│       │   ├── mod.rs
│       │   ├── classifier.rs        # Article category classifier
│       │   └── openai.rs            # OpenAI summary generation
│       └── tts/
│           ├── mod.rs
│           ├── tts.rs               # Volcengine TTS
│           └── utils.rs
│
├── app/                              # Flutter client (Vercel)
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── config/
│       │   └── supabase_config.dart
│       ├── models/
│       │   ├── article.dart
│       │   ├── briefing.dart
│       │   ├── category_briefing.dart
│       │   └── subscription.dart
│       ├── providers/
│       │   ├── auth_provider.dart
│       │   ├── briefing_provider.dart
│       │   ├── subscription_provider.dart
│       │   └── trial_provider.dart
│       ├── responsive/
│       │   └── responsive.dart
│       ├── screens/
│       │   ├── home_screen.dart
│       │   ├── briefing_detail_screen.dart
│       │   ├── category_briefing_screen.dart
│       │   ├── paywall_screen.dart
│       │   └── settings_screen.dart
│       ├── services/
│       │   ├── auth_service.dart
│       │   ├── briefing_service.dart
│       │   ├── revenuecat_service.dart  # RevenueCat Apple IAP (iOS only)
│       │   ├── subscription_service.dart
│       │   └── trial_service.dart
│       ├── theme/
│       │   └── app_theme.dart
│       └── widgets/
│           ├── audio_player.dart
│           ├── auth_dialog.dart
│           ├── briefing_cover.dart
│           └── subscription_gate.dart
│
├── supabase/
│   ├── functions/
│   │   ├── _shared/
│   │   │   ├── cors.ts              # CORS headers
│   │   │   ├── creem.ts             # Creem API helpers
│   │   │   └── supabase.ts          # Supabase client helpers
│   │   ├── create-checkout/
│   │   │   └── index.ts
│   │   ├── creem-webhook/
│   │   │   └── index.ts
│   │   ├── customer-portal/
│   │   │   └── index.ts
│   │   └── revenuecat-webhook/
│   │       └── index.ts             # RevenueCat Apple IAP webhook
│   └── migrations/
│       ├── 001_create_tables.sql
│       ├── 002_seed_sources.sql
│       ├── 003_add_articles_table.sql
│       ├── 004_add_more_sources.sql
│       ├── 005_add_category_briefing_title.sql
│       ├── 006_add_user_subscriptions.sql
│       ├── 007_add_user_trial_access.sql
│       └── 008_add_apple_iap_fields.sql  # Apple IAP / RevenueCat fields
│
└── .github/workflows/
    ├── daily-briefing.yml            # Rust cron job (daily 21:00 UTC)
    ├── deploy-production.yml         # Flutter web → Vercel production
    └── deploy-preview.yml            # Flutter web → Vercel PR preview
```

---

## Database

### Tables

| Table | Purpose | Rust Backend | Flutter Client |
|-------|---------|-------------|----------------|
| `daily_briefings` | Daily AI news summaries (Markdown) | Write | Read |
| `news_sources` | RSS feed configuration | Read | Read |
| `articles` | Individual classified news articles | Write | Read |
| `category_briefings` | Per-category summaries (LLM, Agent, Coding, etc.) | Write | Read |
| `user_subscriptions` | Subscription status (Creem + Apple IAP) | - | Read (Edge Functions write) |
| `user_trial_access` | Free trial content access tracking (max 3) | - | Read/Write |

### Categories (article classification)

The AI classifier assigns articles to these categories: `llm`, `agent`, `coding`, `infra`, `product`, `research`, `fundraising`, `policy`, `other`.

### RLS Policies

- `daily_briefings`, `news_sources`, `articles`, `category_briefings`: Public read (no auth required)
- `user_subscriptions`: Users can only SELECT their own row; Edge Functions use service_role for writes
- `user_trial_access`: Users can SELECT and INSERT their own rows (max 3 unique content items)

---

## Payment / Subscription System

Dual payment channels: **Creem** (web) and **Apple IAP via RevenueCat** (iOS).

Both channels write to the same `user_subscriptions` table. The `subscription_source` column tracks which channel (`creem` or `apple`). Subscription status logic is the same regardless of source.

### Supabase Edge Functions

| Function | Purpose | JWT Verify |
|----------|---------|------------|
| `create-checkout` | Creates Creem checkout session, returns payment URL (web) | `--no-verify-jwt` (auth handled in code) |
| `creem-webhook` | Receives Creem webhook events, updates subscription (web) | `--no-verify-jwt` (Creem has no Supabase JWT) |
| `customer-portal` | Generates Creem billing portal link (web) | `--no-verify-jwt` (auth handled in code) |
| `revenuecat-webhook` | Receives RevenueCat webhook events for Apple IAP (iOS) | `--no-verify-jwt` (auth via Bearer token) |

Shared utilities in `supabase/functions/_shared/`:
- `creem.ts` - Creem API helpers (base URL toggle via `CREEM_TEST_MODE`, headers, HMAC-SHA256 webhook signature verification)
- `cors.ts` - CORS headers for Flutter Web
- `supabase.ts` - Service-role and user-scoped Supabase clients

### Subscription Status Logic

- `active` or `trialing` → access granted
- `canceled` + `current_period_end` in future → access granted (until period ends)
- `expired` or `inactive` or no record → access denied, paywall shown

### Environment Variables (Supabase Edge Function Secrets)

```
# Creem (web payments)
CREEM_API_KEY              - Creem API key
CREEM_WEBHOOK_SECRET       - Webhook signing secret (HMAC-SHA256)
CREEM_PRODUCT_ID           - Creem product ID for the subscription
CREEM_TEST_MODE            - "true" for sandbox, "false"/"" for production

# RevenueCat (iOS Apple IAP)
REVENUECAT_WEBHOOK_AUTH_KEY - Shared secret for webhook authorization
```

### Creem Webhook Events (Web)

- `checkout.completed` → create subscription record (status=active)
- `subscription.active` / `subscription.paid` → grant access
- `subscription.trialing` → grant access (trial)
- `subscription.canceled` → keep access until period end
- `subscription.expired` → revoke access
- `subscription.paused` → pause access
- `refund.created` → revoke access

### RevenueCat Webhook Events (iOS)

- `INITIAL_PURCHASE` / `RENEWAL` / `UNCANCELLATION` → grant access (status=active)
- `CANCELLATION` → keep access until period end (status=canceled)
- `EXPIRATION` → revoke access (status=expired)
- `PRODUCT_CHANGE` → update if still has premium entitlement

### Apple IAP / RevenueCat Setup

- RevenueCat manages Apple IAP complexity (receipt validation, renewals, refunds)
- Flutter uses `purchases_flutter` SDK (RevenueCat)
- RevenueCat `appUserID` is set to Supabase user ID for cross-platform identity
- Entitlement name: `AI Briefing Pro`
- RevenueCat Webhook URL: `<SUPABASE_URL>/functions/v1/revenuecat-webhook`

---

## Flutter App

### Key Patterns

- **State management**: Riverpod (providers in `lib/providers/`)
- **Auth**: Google + GitHub + Apple OAuth via Supabase Auth. Web uses implicit flow for session persistence; iOS uses PKCE flow. Apple Sign-In uses native `sign_in_with_apple` SDK on iOS, OAuth on web.
- **Data access**: Direct Supabase queries via `BriefingService` (no backend API)
- **Subscription gating**: `SubscriptionGate.navigateIfSubscribed()` checks subscription + trial before navigation
- **Free trial**: Non-subscribed logged-in users get 3 free content accesses (tracked in `user_trial_access` table via `TrialService`)
- **Paywall**: `PaywallScreen.show()` displays centered dialog with pricing and checkout flow. Platform-aware: Apple IAP on iOS, Creem on web.
- **Apple IAP (iOS)**: `RevenueCatService` wraps `purchases_flutter` SDK. Initialized in `main.dart` with Supabase user ID. Purchase triggers native Apple payment sheet.

### Content Gating

- All briefings (including latest): **3 free trials**, then **require subscription** (gated via `SubscriptionGate`)
- Category briefings: **3 free trials** (shared quota with daily), then **require subscription**
- The 3 free trial quota is shared across daily and category briefings, tracked per unique content
- Revisiting already-accessed trial content does NOT consume additional quota
- Settings: accessible from avatar dropdown menu (logged-in users)

### Auth Flow

- OAuth via Google, GitHub, and Apple (Supabase Auth)
- `auth_service.dart`: redirect URL is `Uri.base.origin` in debug mode (localhost), `null` in production (uses Supabase Site URL). On iOS, redirect uses `io.supabase.aibriefing://login-callback` deep link.
- `main.dart`: Web uses `AuthFlowType.implicit` to persist session; iOS/Android uses `AuthFlowType.pkce` for secure deep link callback.
- Apple Sign-In: On iOS, uses native `sign_in_with_apple` SDK with `signInWithIdToken()` (nonce-based). On web, uses standard OAuth flow.
- Paywall handles login-first flow: if not logged in, shows auth dialog before creating checkout

### Design

- OLED dark theme (pure black background)
- Fonts: Space Grotesk (headings), DM Sans (body) via Google Fonts
- Primary: #1ED760 (green), Accent: #00D4FF (cyan), Purple: #7C3AED
- See `app/lib/theme/app_theme.dart` for full color palette

---

## Deployment

### Flutter Web (Vercel)

Auto-deploys via GitHub Actions:
- Push to `main` on `app/**` → production deploy (`deploy-production.yml`)
- PR touching `app/**` → preview deploy (`deploy-preview.yml`)

Manual build:
```bash
cd app
flutter build web
```

### Rust Backend (GitHub Actions)

Runs automatically via `daily-briefing.yml` at UTC 21:00 (Beijing 05:00). Can be triggered manually via `workflow_dispatch`.

### Edge Functions

```bash
cd /path/to/ai-briefing
supabase functions deploy create-checkout --no-verify-jwt
supabase functions deploy creem-webhook --no-verify-jwt
supabase functions deploy customer-portal --no-verify-jwt
supabase functions deploy revenuecat-webhook --no-verify-jwt
```

### Database Migrations

Migrations 001-005 were run manually in Supabase SQL Editor (not tracked in schema_migrations). Run new migrations in SQL Editor or via `supabase db push`.

---

## Local Development

### Flutter Web

```bash
cd app
cp .env.example .env  # Add Supabase URL and anon key
flutter pub get
flutter run -d chrome --web-port=3000
```

Supabase Dashboard → Auth → URL Configuration → Redirect URLs: add `http://localhost:3000`

### Rust Backend

```bash
cd backend
cp env.example .env  # Fill in all credentials
cargo run --release -- --run-now  # Run once immediately
```

### Edge Functions (local)

```bash
supabase functions serve --env-file supabase/.env.local
# For webhook testing: ngrok http 54321, then set ngrok URL in Creem Dashboard
```

### Flutter App Environment Variables (`.env`)

| Variable | Purpose |
|----------|---------|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_PUBLISHABLE_KEY` | Supabase anon key |
| `REVENUECAT_APPLE_API_KEY` | RevenueCat Apple API key (iOS only) |

### Backend Environment Variables

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | Supabase PostgreSQL connection string |
| `OPENAI_API_KEY` | OpenAI API key |
| `OPENAI_BASE_URL` | OpenAI-compatible API base URL |
| `OPENAI_MODEL` | Model name (e.g. `gpt-4o-mini`) |
| `TTS_BASE_URL` | Volcengine TTS endpoint |
| `TTS_APPID` | Volcengine TTS app ID |
| `TTS_ACCESS_TOKEN` | Volcengine TTS access token |
| `TTS_VOICE_TYPE` | Voice type (e.g. `BV700_V2_streaming`) |
| `TOS_ACCESS_KEY` | Volcengine TOS access key |
| `TOS_SECRET_KEY` | Volcengine TOS secret key |
| `TOS_ENDPOINT` | TOS endpoint URL |
| `TOS_REGION` | TOS region (e.g. `cn-shanghai`) |
| `TOS_BUCKET` | TOS bucket name |
| `CRON_SCHEDULE` | Cron expression (UTC) |
| `NEWS_HOURS_BACK` | Hours of news to fetch (default: 24) |
