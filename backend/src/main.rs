mod config;
mod crawler;
mod db;
mod entity;
mod jobs;
mod storage;
mod summarizer;
mod tts;

use anyhow::Result;
use chrono::{Datelike, NaiveDate};
use sea_orm::Database;
use tokio_cron_scheduler::{Job, JobScheduler};
use tracing::{error, info};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use crate::config::Config;
use crate::db::Repository;
use crate::jobs::run_daily_briefing_job;

/// Parse command line arguments
struct Args {
    run_now: bool,
    run_on_start: bool,
    target_date: Option<NaiveDate>,
    hours_back: Option<i64>,
    force: bool,
}

fn parse_args() -> Args {
    let args: Vec<String> = std::env::args().collect();
    
    let run_now = args.iter().any(|a| a == "--run-now");
    let run_on_start = args.iter().any(|a| a == "--run-on-start");
    
    // Parse --date YYYY-MM-DD or --date MM-DD (assumes current year)
    let target_date = args
        .iter()
        .position(|a| a == "--date")
        .and_then(|i| args.get(i + 1))
        .and_then(|date_str| {
            // Try full format first: YYYY-MM-DD
            if let Ok(date) = NaiveDate::parse_from_str(date_str, "%Y-%m-%d") {
                return Some(date);
            }
            // Try short format: MM-DD (use current year)
            if let Ok(date) = NaiveDate::parse_from_str(
                &format!("{}-{}", chrono::Local::now().year(), date_str),
                "%Y-%m-%d",
            ) {
                return Some(date);
            }
            // Try short format: M-D
            if let Ok(date) = NaiveDate::parse_from_str(
                &format!("{}-{}", chrono::Local::now().year(), date_str),
                "%Y-%-m-%-d",
            ) {
                return Some(date);
            }
            None
        });
    
    // Parse --hours N
    let hours_back = args
        .iter()
        .position(|a| a == "--hours")
        .and_then(|i| args.get(i + 1))
        .and_then(|h| h.parse().ok());
    
    let force = args.iter().any(|a| a == "--force");
    
    Args {
        run_now,
        run_on_start,
        target_date,
        hours_back,
        force,
    }
}

fn print_usage() {
    println!("Usage: ai-briefing-backend [OPTIONS]");
    println!();
    println!("Options:");
    println!("  --run-now         Run job immediately and exit");
    println!("  --run-on-start    Run job once on startup, then continue with scheduler");
    println!("  --date DATE       Generate briefing for specific date (YYYY-MM-DD or MM-DD)");
    println!("  --hours N         Fetch articles from the last N hours (default: 24)");
    println!("  --force           Force regenerate even if briefing already exists");
    println!();
    println!("Examples:");
    println!("  ai-briefing-backend --run-now --date 2025-01-01 --hours 48");
    println!("  ai-briefing-backend --run-now --date 01-01 --force");
}

#[tokio::main]
async fn main() -> Result<()> {
    // Check for help flag
    if std::env::args().any(|a| a == "--help" || a == "-h") {
        print_usage();
        return Ok(());
    }

    // Initialize logging
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info,ai_briefing_backend=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    info!("Starting AI Briefing Backend");

    // Load configuration
    let config = Config::from_env()?;
    info!("Configuration loaded successfully");

    // Parse command line arguments
    let args = parse_args();

    // Create database connection with SeaORM
    let mut opt = sea_orm::ConnectOptions::new(&config.database_url);
    opt.sqlx_logging(true)
        .sqlx_logging_level(log::LevelFilter::Debug);
    let db = Database::connect(opt).await?;
    info!("Database connection established");

    let repo = Repository::new(db.clone());

    if args.run_now {
        // Run job immediately and exit
        let target_date = args.target_date;
        let hours_back = args.hours_back;
        let force = args.force;
        
        if let Some(date) = target_date {
            info!("Running job for specific date: {} (--date flag)", date);
        } else {
            info!("Running job immediately (--run-now flag)");
        }
        if force {
            info!("Force mode enabled (--force flag)");
        }
        
        if let Err(e) = run_daily_briefing_job(&config, &repo, target_date, hours_back, force).await {
            error!("Job failed: {}", e);
            return Err(e);
        }
        info!("Job completed successfully");
        return Ok(());
    }

    if args.run_on_start {
        // Run job once on startup, then continue with scheduler
        info!("Running job on startup (--run-on-start flag)");
        if let Err(e) = run_daily_briefing_job(&config, &repo, None, None, false).await {
            error!("Initial job failed: {}", e);
            // Continue to scheduler even if initial job fails
        }
    }

    // Create scheduler
    let scheduler = JobScheduler::new().await?;

    // Clone config for closure
    let job_config = config.clone();

    // Schedule daily job
    let cron_schedule = config.cron_schedule.clone();
    info!("Scheduling daily job with cron: {}", cron_schedule);

    let job = Job::new_async(cron_schedule.as_str(), move |_uuid, _lock| {
        let config = job_config.clone();
        let db = db.clone();

        Box::pin(async move {
            let repo = Repository::new(db);
            if let Err(e) = run_daily_briefing_job(&config, &repo, None, None, false).await {
                error!("Daily briefing job failed: {}", e);
            }
        })
    })?;

    scheduler.add(job).await?;
    info!("Daily job scheduled");

    // Start scheduler
    scheduler.start().await?;
    info!("Scheduler started, waiting for jobs...");

    // Keep running
    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(60)).await;
    }
}
