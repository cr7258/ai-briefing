# AI Briefing

Daily AI news briefing app with voice broadcast support.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Client                          │
│         (iOS, Android, Web, macOS, Windows)                 │
└──────────────────────────┬──────────────────────────────────┘
                           │ REST API (PostgREST)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   Supabase Cloud                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ PostgreSQL  │  │   Storage   │  │    Auth     │         │
│  │  Database   │  │   (Audio)   │  │  (Future)   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└──────────────────────────▲──────────────────────────────────┘
                           │
┌──────────────────────────┴──────────────────────────────────┐
│                    Rust Backend                             │
│  ┌─────────┐  ┌───────────┐  ┌─────────┐  ┌─────────────┐  │
│  │ Crawler │  │ Summarizer│  │   TTS   │  │  Scheduler  │  │
│  │  (RSS)  │  │ (OpenAI)  │  │(MiniMax)│  │   (Cron)    │  │
│  └─────────┘  └───────────┘  └─────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
ai-briefing/
├── backend/           # Rust backend
│   ├── src/
│   │   ├── crawler/   # RSS feed crawler
│   │   ├── summarizer/# OpenAI summary generation
│   │   ├── tts/       # MiniMax text-to-speech
│   │   ├── storage/   # Supabase storage
│   │   ├── db/        # Database models & repository
│   │   └── jobs/      # Scheduled jobs
│   └── Cargo.toml
├── app/               # Flutter client
│   ├── lib/
│   │   ├── config/    # App configuration
│   │   ├── models/    # Data models
│   │   ├── providers/ # Riverpod providers
│   │   ├── screens/   # UI screens
│   │   ├── services/  # API services
│   │   └── widgets/   # Reusable widgets
│   └── pubspec.yaml
├── supabase/          # Database migrations
│   └── migrations/
└── design.md          # Detailed design document
```

## Quick Start

### 1. Setup Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Run the SQL migrations in `supabase/migrations/`
3. Create a storage bucket named `briefing-audio` with public access

### 2. Configure Backend

```bash
cd backend
cp env.example .env
# Edit .env with your credentials
```

Required environment variables:
- `DATABASE_URL` - Supabase PostgreSQL connection string
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key (for storage)
- `OPENAI_API_KEY` - OpenAI API key
- `MINIMAX_GROUP_ID` - MiniMax group ID
- `MINIMAX_API_KEY` - MiniMax API key

### 3. Run Backend

```bash
cd backend

# Run scheduler only (wait for cron time)
cargo run --release

# Run once immediately, then exit
cargo run --release -- --run-now

# Run once on start, then continue with scheduler
cargo run --release -- --run-on-start
```

### 4. Configure Flutter App

Edit `app/lib/config/supabase_config.dart` with your Supabase credentials.

### 5. Run Flutter App

```bash
cd app
flutter pub get
flutter run
```

## Features

- 📰 Daily AI news aggregation from multiple sources
- 🤖 AI-powered summary generation (OpenAI)
- 🔊 Voice broadcast with high-quality TTS (MiniMax)
- 📱 Cross-platform support (iOS, Android, Web, macOS, Windows)
- 🌙 Dark mode support
- 📚 Markdown rendering with clickable links

## News Sources

| Source | Type |
|--------|------|
| TechCrunch AI | RSS |
| The Verge AI | RSS |
| VentureBeat AI | RSS |
| AI News | RSS |
| Hacker News AI | RSS |
| OpenAI Blog | RSS |
| Hugging Face Blog | RSS |
| vLLM Blog | RSS |

## License

MIT

