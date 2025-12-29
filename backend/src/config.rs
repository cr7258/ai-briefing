use anyhow::{Context, Result};

/// Application configuration loaded from environment variables
#[derive(Debug, Clone)]
pub struct Config {
    pub database_url: String,
    pub supabase_url: String,
    pub supabase_secret_key: String,
    pub openai_api_key: String,
    pub openai_base_url: String,
    pub openai_model: String,
    pub minimax_api_key: String,
    pub minimax_model: String,
    pub minimax_voice_id: String,
    pub cron_schedule: String,
}

impl Config {
    /// Load configuration from environment variables
    pub fn from_env() -> Result<Self> {
        dotenvy::dotenv().ok();

        Ok(Self {
            database_url: std::env::var("DATABASE_URL")
                .context("DATABASE_URL is required")?,
            supabase_url: std::env::var("SUPABASE_URL")
                .context("SUPABASE_URL is required")?,
            supabase_secret_key: std::env::var("SUPABASE_SECRET_KEY")
                .context("SUPABASE_SECRET_KEY is required")?,
            openai_api_key: std::env::var("OPENAI_API_KEY")
                .context("OPENAI_API_KEY is required")?,
            openai_base_url: std::env::var("OPENAI_BASE_URL")
                .unwrap_or_else(|_| "https://api.openai.com/v1".to_string()),
            openai_model: std::env::var("OPENAI_MODEL")
                .unwrap_or_else(|_| "gpt-4o-mini".to_string()),
            minimax_api_key: std::env::var("MINIMAX_API_KEY")
                .context("MINIMAX_API_KEY is required")?,
            minimax_model: std::env::var("MINIMAX_MODEL")
                .unwrap_or_else(|_| "speech-2.6-hd".to_string()),
            minimax_voice_id: std::env::var("MINIMAX_VOICE_ID")
                .unwrap_or_else(|_| "male-qn-qingse".to_string()),
            cron_schedule: std::env::var("CRON_SCHEDULE")
                .unwrap_or_else(|_| "0 0 8 * * *".to_string()), // Default: 8:00 AM UTC
        })
    }
}

