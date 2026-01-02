use anyhow::Result;
use chrono::{DateTime, Local, NaiveDate, NaiveTime, TimeZone, Utc};
use std::collections::HashMap;
use tracing::{error, info, warn};

use crate::config::Config;
use crate::crawler::RssCrawler;
use crate::db::Repository;
use crate::storage::AudioStorage;
use crate::summarizer::{ArticleClassifier, OpenAISummarizer, CATEGORIES};
use crate::tts::VolcengineTTS;

/// Category display names (Chinese)
fn get_category_name(category: &str) -> &'static str {
    match category {
        "llm" => "大语言模型",
        "agent" => "AI 代理",
        "multimodal" => "多模态",
        "coding" => "AI 编程",
        "infra" => "基础设施",
        "robotics" => "机器人",
        "research" => "研究",
        "apps" => "应用",
        "industry" => "行业",
        "cloud_native" => "云原生",
        _ => "其他",
    }
}

/// Execute the daily briefing job (Premium version)
/// 
/// # Arguments
/// * `config` - Application configuration
/// * `repo` - Database repository
/// * `target_date` - Optional specific date to generate briefing for (defaults to today)
/// * `hours_back` - Optional hours to look back for articles (defaults to config value)
/// * `force` - Force regenerate even if briefing already exists
/// 
/// Steps:
/// 1. Crawl news from all active sources
/// 2. AI classify all articles
/// 3. Save articles to database
/// 4. Generate comprehensive briefing + TTS
/// 5. Generate per-category briefings + TTS
pub async fn run_daily_briefing_job(
    config: &Config,
    repo: &Repository,
    target_date: Option<NaiveDate>,
    hours_back: Option<i64>,
    force: bool,
) -> Result<()> {
    let briefing_date = target_date.unwrap_or_else(|| Local::now().date_naive());
    let hours = hours_back.unwrap_or(config.news_hours_back);
    
    // Calculate end_time: if target_date is specified, use end of that day (23:59:59 UTC)
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
        if existing.audio_url.is_some() && !force {
            info!("Briefing for {} already exists with audio, skipping (use --force to regenerate)", briefing_date);
            return Ok(());
        }
        if force {
            info!("Briefing for {} exists, will regenerate (--force)", briefing_date);
        } else {
            info!("Briefing for {} exists but without audio, will update", briefing_date);
        }
    }

    // Initialize services
    let summarizer = OpenAISummarizer::new(
        config.openai_api_key.clone(),
        config.openai_base_url.clone(),
        config.openai_model.clone(),
    );
    
    let classifier = ArticleClassifier::new(
        config.openai_api_key.clone(),
        config.openai_base_url.clone(),
        config.openai_model.clone(),
    );
    
    let tts = VolcengineTTS::new(
        config.tts_base_url.clone(),
        config.tts_appid.clone(),
        config.tts_access_token.clone(),
        config.tts_voice_type.clone(),
    );

    let storage = AudioStorage::new(
        config.tos_access_key.clone(),
        config.tos_secret_key.clone(),
        config.tos_endpoint.clone(),
        config.tos_region.clone(),
        config.tos_bucket.clone(),
    )
    .await?;

    // ========================================
    // Step 1: Crawl news
    // ========================================
    info!("Step 1/7: Crawling news sources (last {} hours)", hours);
    let sources = repo.get_active_sources().await?;
    let crawler = RssCrawler::new();
    
    // Crawl each source individually to track success/failure
    let mut raw_articles = Vec::new();
    let mut success_count = 0;
    let mut error_count = 0;
    
    for source in &sources {
        if source.feed_type != "rss" {
            continue;
        }
        
        match crawler.fetch(source, hours, end_time).await {
            Ok(articles) => {
                info!("  ✓ {} - {} articles", source.name, articles.len());
                raw_articles.extend(articles);
                success_count += 1;
                
                // Record success
                if let Err(e) = repo.update_source_crawl_success(source.id).await {
                    warn!("Failed to update source status: {}", e);
                }
            }
            Err(e) => {
                let error_msg = format!("{}", e);
                warn!("  ✗ {} - {}", source.name, error_msg);
                error_count += 1;
                
                // Record error
                if let Err(e) = repo.update_source_crawl_error(source.id, &error_msg).await {
                    warn!("Failed to update source error: {}", e);
                }
            }
        }
    }
    
    // Sort by published date (newest first)
    raw_articles.sort_by(|a, b| {
        b.published_at
            .unwrap_or(chrono::Utc::now())
            .cmp(&a.published_at.unwrap_or(chrono::Utc::now()))
    });

    info!(
        "Crawled {} articles from {} sources ({} success, {} failed)",
        raw_articles.len(),
        sources.len(),
        success_count,
        error_count
    );

    if raw_articles.is_empty() {
        info!("No articles found, skipping briefing generation");
        return Ok(());
    }

    // ========================================
    // Step 2: AI classify all articles
    // ========================================
    info!("Step 2/7: Classifying articles with AI");
    let classified_articles = classifier.classify(&raw_articles).await?;
    info!("Classified {} articles", classified_articles.len());

    // Group by category
    let grouped = ArticleClassifier::group_by_category(&classified_articles);
    for (cat, arts) in &grouped {
        info!("  - {}: {} articles", cat, arts.len());
    }

    // ========================================
    // Step 3: Generate comprehensive briefing
    // ========================================
    info!("Step 3/7: Generating comprehensive briefing");
    let comprehensive_summary = summarizer
        .generate_comprehensive_briefing(&classified_articles)
        .await?;
    let title = summarizer.generate_title(briefing_date);

    // ========================================
    // Step 4: Save briefing to database
    // ========================================
    info!("Step 4/7: Saving briefing to database");
    let briefing = repo
        .upsert_briefing(briefing_date, title.clone(), comprehensive_summary.clone(), None, None)
        .await?;
    info!("Saved briefing with ID: {}", briefing.id);

    // Save articles
    repo.save_articles(briefing.id, &classified_articles).await?;
    info!("Saved {} articles", classified_articles.len());

    // ========================================
    // Step 5: Generate comprehensive audio
    // ========================================
    info!("Step 5/7: Generating comprehensive audio");
    match tts.synthesize_long_text(&comprehensive_summary).await {
        Ok(tts_result) => {
            let filename = format!("{}.mp3", briefing_date);
            match storage.upload(&filename, tts_result.audio_data).await {
                Ok(audio_url) => {
                    repo.update_briefing_audio(briefing.id, &audio_url, tts_result.duration_seconds)
                        .await?;
                    info!("Uploaded comprehensive audio: {}", audio_url);
                }
                Err(e) => {
                    error!("Failed to upload comprehensive audio: {}", e);
                }
            }
        }
        Err(e) => {
            error!("Failed to generate comprehensive audio: {}", e);
        }
    }

    // ========================================
    // Step 6: Generate per-category briefings
    // ========================================
    info!("Step 6/7: Generating per-category briefings");
    let mut category_summaries: HashMap<String, String> = HashMap::new();
    
    for category in CATEGORIES {
        if let Some(articles) = grouped.get(*category) {
            if articles.is_empty() {
                continue;
            }

            let category_name = get_category_name(category);
            info!("  Generating {} briefing ({} articles)", category, articles.len());

            match summarizer
                .generate_category_briefing(category, category_name, articles)
                .await
            {
                Ok(summary) => {
                    // Save category briefing (without audio first)
                    repo.upsert_category_briefing(
                        briefing.id,
                        category,
                        summary.clone(),
                        None,
                        None,
                        articles.len() as i32,
                    )
                    .await?;
                    
                    category_summaries.insert(category.to_string(), summary);
                }
                Err(e) => {
                    warn!("Failed to generate {} briefing: {}", category, e);
                }
            }
        }
    }

    // ========================================
    // Step 7: Generate per-category audio
    // ========================================
    info!("Step 7/7: Generating per-category audio");
    for (category, summary) in &category_summaries {
        info!("  Generating {} audio", category);
        
        match tts.synthesize_long_text(summary).await {
            Ok(tts_result) => {
                let filename = format!("{}-{}.mp3", briefing_date, category);
                match storage.upload(&filename, tts_result.audio_data).await {
                    Ok(audio_url) => {
                        // Get category briefing and update with audio
                        let cat_briefings = repo.get_category_briefings(briefing.id).await?;
                        if let Some(cat_briefing) = cat_briefings.iter().find(|b| b.category == *category) {
                            repo.update_category_briefing_audio(
                                cat_briefing.id,
                                &audio_url,
                                tts_result.duration_seconds,
                            )
                            .await?;
                        }
                        info!("  Uploaded {} audio: {}", category, audio_url);
                    }
                    Err(e) => {
                        warn!("  Failed to upload {} audio: {}", category, e);
                    }
                }
            }
            Err(e) => {
                warn!("  Failed to generate {} audio: {}", category, e);
            }
        }
    }

    info!("Daily briefing job completed successfully");
    info!(
        "  - Comprehensive briefing: 1 (with audio)"
    );
    info!(
        "  - Category briefings: {} (with audio)",
        category_summaries.len()
    );
    info!("  - Total articles: {}", classified_articles.len());

    Ok(())
}
