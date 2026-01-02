use anyhow::Result;
use chrono::{DateTime, Local, NaiveDate, NaiveTime, TimeZone, Utc};
use tracing::{error, info};

use crate::config::Config;
use crate::crawler::RssCrawler;
use crate::db::Repository;
use crate::storage::AudioStorage;
use crate::summarizer::OpenAISummarizer;
use crate::tts::VolcengineTTS;

/// Execute the daily briefing job
/// 
/// # Arguments
/// * `config` - Application configuration
/// * `repo` - Database repository
/// * `target_date` - Optional specific date to generate briefing for (defaults to today)
/// * `hours_back` - Optional hours to look back for articles (defaults to config value)
/// 
/// Steps:
/// 1. Crawl news from all active sources
/// 2. Generate AI summary
/// 3. Generate audio with TTS
/// 4. Upload audio to storage
/// 5. Save briefing to database
pub async fn run_daily_briefing_job(
    config: &Config,
    repo: &Repository,
    target_date: Option<NaiveDate>,
    hours_back: Option<i64>,
) -> Result<()> {
    let briefing_date = target_date.unwrap_or_else(|| Local::now().date_naive());
    let hours = hours_back.unwrap_or(config.news_hours_back);
    
    // Calculate end_time: if target_date is specified, use end of that day (23:59:59 UTC)
    // Otherwise use current time
    let end_time: Option<DateTime<Utc>> = target_date.map(|date| {
        let end_of_day = NaiveTime::from_hms_opt(23, 59, 59).unwrap();
        Utc.from_utc_datetime(&date.and_time(end_of_day))
    });
    
    if let Some(end) = end_time {
        info!(
            "Starting daily briefing job for {} (fetching {} hours before {})",
            briefing_date, hours, end
        );
    } else {
        info!(
            "Starting daily briefing job for {} (fetching last {} hours)",
            briefing_date, hours
        );
    }

    // Check if briefing already exists for the target date
    if let Some(existing) = repo.get_briefing_by_date(briefing_date).await? {
        if existing.audio_url.is_some() {
            info!("Briefing for {} already exists with audio, skipping", briefing_date);
            return Ok(());
        }
        info!(
            "Briefing for {} exists but without audio, will update",
            briefing_date
        );
    }

    // Step 1: Crawl news
    info!("Step 1/5: Crawling news sources (last {} hours)", hours);
    let sources = repo.get_active_sources().await?;
    let crawler = RssCrawler::new();
    let articles = crawler.fetch_all(&sources, hours, end_time).await;

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
    let title = summarizer.generate_title(briefing_date);

    // Step 3: Save briefing to database (without audio first)
    info!("Step 3/5: Saving briefing to database");
    let briefing = repo
        .upsert_briefing(briefing_date, title.clone(), summary.clone(), None, None)
        .await?;
    info!("Saved briefing with ID: {}", briefing.id);

    // Step 4: Generate audio with TTS (Volcengine)
    info!("Step 4/5: Generating audio with TTS");
    let tts = VolcengineTTS::new(
        config.tts_base_url.clone(),
        config.tts_appid.clone(),
        config.tts_access_token.clone(),
        config.tts_voice_type.clone(),
    );

    match tts.synthesize_long_text(&summary).await {
        Ok(tts_result) => {
            // Step 5: Upload audio to storage
            info!("Step 5/5: Uploading audio to storage");
            let storage = match AudioStorage::new(
                config.tos_access_key.clone(),
                config.tos_secret_key.clone(),
                config.tos_endpoint.clone(),
                config.tos_region.clone(),
                config.tos_bucket.clone(),
            )
            .await
            {
                Ok(s) => s,
                Err(e) => {
                    error!("Failed to create storage client: {}", e);
                    return Ok(());
                }
            };

            let filename = format!("{}.mp3", briefing_date);
            match storage.upload(&filename, tts_result.audio_data).await {
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
