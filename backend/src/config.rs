use anyhow::{Context, Result};

/// Application configuration loaded from environment variables
#[derive(Debug, Clone)]
pub struct Config {
    pub database_url: String,
    pub openai_api_key: String,
    pub openai_base_url: String,
    pub openai_model: String,
    // Volcengine TTS configuration
    pub tts_base_url: String,
    pub tts_appid: String,
    pub tts_access_token: String,
    pub tts_voice_type: String,
    // Volcengine TOS (storage) configuration
    pub tos_access_key: String,
    pub tos_secret_key: String,
    pub tos_endpoint: String,
    pub tos_region: String,
    pub tos_bucket: String,
    pub cron_schedule: String,
}

impl Config {
    /// Load configuration from environment variables
    pub fn from_env() -> Result<Self> {
        dotenvy::dotenv().ok();

        Ok(Self {
            database_url: std::env::var("DATABASE_URL")
                .context("DATABASE_URL is required")?,
            openai_api_key: std::env::var("OPENAI_API_KEY")
                .context("OPENAI_API_KEY is required")?,
            openai_base_url: std::env::var("OPENAI_BASE_URL")
                .unwrap_or_else(|_| "https://api.openai.com/v1".to_string()),
            openai_model: std::env::var("OPENAI_MODEL")
                .unwrap_or_else(|_| "gpt-4o-mini".to_string()),
            // Volcengine TTS
            tts_base_url: std::env::var("TTS_BASE_URL")
                .unwrap_or_else(|_| "https://openspeech.bytedance.com".to_string()),
            tts_appid: std::env::var("TTS_APPID")
                .context("TTS_APPID is required")?,
            tts_access_token: std::env::var("TTS_ACCESS_TOKEN")
                .context("TTS_ACCESS_TOKEN is required")?,
            tts_voice_type: std::env::var("TTS_VOICE_TYPE")
                .unwrap_or_else(|_| "BV700_V2_streaming".to_string()),
            // Volcengine TOS (storage)
            tos_access_key: std::env::var("TOS_ACCESS_KEY")
                .context("TOS_ACCESS_KEY is required")?,
            tos_secret_key: std::env::var("TOS_SECRET_KEY")
                .context("TOS_SECRET_KEY is required")?,
            tos_endpoint: std::env::var("TOS_ENDPOINT")
                .unwrap_or_else(|_| "https://tos-cn-shanghai.volces.com".to_string()),
            tos_region: std::env::var("TOS_REGION")
                .unwrap_or_else(|_| "cn-shanghai".to_string()),
            tos_bucket: std::env::var("TOS_BUCKET")
                .context("TOS_BUCKET is required")?,
            cron_schedule: std::env::var("CRON_SCHEDULE")
                .unwrap_or_else(|_| "0 0 22 * * *".to_string()), // Default: 22:00 UTC = 06:00 Beijing
        })
    }
}

