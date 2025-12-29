use anyhow::Result;
use chrono::Local;
use tracing::{error, info};

use crate::config::Config;
use crate::crawler::RssCrawler;
use crate::db::Repository;
use crate::storage::SupabaseStorage;
use crate::summarizer::OpenAISummarizer;
use crate::tts::MiniMaxTTS;

/// Execute the daily briefing job
/// 1. Crawl news from all active sources
/// 2. Generate AI summary
/// 3. Generate audio with TTS
/// 4. Upload audio to storage
/// 5. Save briefing to database
pub async fn run_daily_briefing_job(config: &Config, repo: &Repository) -> Result<()> {
    let today = Local::now().date_naive();
    info!("Starting daily briefing job for {}", today);

    // Check if briefing already exists for today
    if let Some(existing) = repo.get_briefing_by_date(today).await? {
        if existing.audio_url.is_some() {
            info!("Briefing for {} already exists with audio, skipping", today);
            return Ok(());
        }
        info!(
            "Briefing for {} exists but without audio, will update",
            today
        );
    }

    // Step 1: Crawl news
    info!("Step 1/5: Crawling news sources");
    let sources = repo.get_active_sources().await?;
    let crawler = RssCrawler::new();
    let articles = crawler.fetch_all(&sources).await;

    if articles.is_empty() {
        info!("No articles found, skipping briefing generation");
        return Ok(());
    }

    info!("Crawled {} articles from {} sources", articles.len(), sources.len());

    // Step 2: Generate AI summary
    info!("Step 2/5: Generating AI summary");
    let summarizer = OpenAISummarizer::new(
        config.openai_api_key.clone(),
        config.openai_base_url.clone(),
        config.openai_model.clone(),
    );
    let summary = summarizer.generate_summary(&articles).await?;
    let title = summarizer.generate_title();

    // Step 3: Save briefing to database (without audio first)
    info!("Step 3/5: Saving briefing to database");
    let briefing = repo
        .upsert_briefing(today, title.clone(), summary.clone(), None, None)
        .await?;
    info!("Saved briefing with ID: {}", briefing.id);

    // Step 4: Generate audio with TTS
    info!("Step 4/5: Generating audio with TTS");
    let tts = MiniMaxTTS::new(
        config.minimax_api_key.clone(),
        config.minimax_model.clone(),
        config.minimax_voice_id.clone(),
    );

    match tts.synthesize_long_text(&summary).await {
        Ok(tts_result) => {
            // Step 5: Upload audio to storage
            info!("Step 5/5: Uploading audio to storage");
            let storage = SupabaseStorage::new(
                config.supabase_url.clone(),
                config.supabase_secret_key.clone(),
            );

            // Ensure bucket exists
            if let Err(e) = storage.ensure_bucket_exists().await {
                error!("Failed to ensure bucket exists: {}", e);
            }

            let filename = format!("{}.mp3", today);
            match storage.upload_audio(&filename, tts_result.audio_data).await {
                Ok(audio_url) => {
                    // Update briefing with audio info
                    repo.update_briefing_audio(
                        briefing.id,
                        &audio_url,
                        tts_result.duration_seconds,
                    )
                    .await?;
                    info!("Updated briefing with audio: {}", audio_url);
                }
                Err(e) => {
                    error!("Failed to upload audio: {}", e);
                }
            }
        }
        Err(e) => {
            error!("Failed to generate audio: {}", e);
            // Continue without audio - briefing is still saved
        }
    }

    info!("Daily briefing job completed successfully");
    Ok(())
}
