mod config;
mod crawler;
mod db;
mod entity;
mod jobs;
mod storage;
mod summarizer;
mod tts;

use anyhow::Result;
use sea_orm::Database;
use tokio_cron_scheduler::{Job, JobScheduler};
use tracing::{error, info};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use crate::config::Config;
use crate::db::Repository;
use crate::jobs::run_daily_briefing_job;

#[tokio::main]
async fn main() -> Result<()> {
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

    // Create database connection with SeaORM
    let mut opt = sea_orm::ConnectOptions::new(&config.database_url);
    opt.sqlx_logging(true)
        .sqlx_logging_level(log::LevelFilter::Debug);
    let db = Database::connect(opt).await?;
    info!("Database connection established");

    let repo = Repository::new(db.clone());

    // Check command line arguments
    let args: Vec<String> = std::env::args().collect();
    let run_now = args.iter().any(|a| a == "--run-now");
    let run_on_start = args.iter().any(|a| a == "--run-on-start");

    if run_now {
        // Run job immediately and exit
        info!("Running job immediately (--run-now flag)");
        if let Err(e) = run_daily_briefing_job(&config, &repo).await {
            error!("Job failed: {}", e);
            return Err(e);
        }
        info!("Job completed successfully");
        return Ok(());
    }

    if run_on_start {
        // Run job once on startup, then continue with scheduler
        info!("Running job on startup (--run-on-start flag)");
        if let Err(e) = run_daily_briefing_job(&config, &repo).await {
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
            if let Err(e) = run_daily_briefing_job(&config, &repo).await {
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
