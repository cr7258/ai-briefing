use anyhow::Result;
use chrono::NaiveDate;
use sea_orm::{
    ActiveModelTrait, ColumnTrait, DatabaseConnection, EntityTrait, QueryFilter, QueryOrder, Set,
};
use uuid::Uuid;

use crate::entity::{daily_briefing, news_source, DailyBriefing, NewsSource};

/// Database repository for all operations
pub struct Repository {
    db: DatabaseConnection,
}

impl Repository {
    /// Create a new repository instance
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    /// Get all active news sources
    pub async fn get_active_sources(&self) -> Result<Vec<news_source::Model>> {
        let sources = NewsSource::find()
            .filter(news_source::Column::IsActive.eq(true))
            .order_by_asc(news_source::Column::Name)
            .all(&self.db)
            .await?;

        Ok(sources)
    }

    /// Get briefing for a specific date
    pub async fn get_briefing_by_date(
        &self,
        date: NaiveDate,
    ) -> Result<Option<daily_briefing::Model>> {
        let briefing = DailyBriefing::find()
            .filter(daily_briefing::Column::Date.eq(date))
            .one(&self.db)
            .await?;

        Ok(briefing)
    }

    /// Create or update a daily briefing (upsert)
    pub async fn upsert_briefing(
        &self,
        date: NaiveDate,
        title: String,
        summary: String,
        audio_url: Option<String>,
        audio_duration: Option<i32>,
    ) -> Result<daily_briefing::Model> {
        // Check if exists
        if let Some(existing) = self.get_briefing_by_date(date).await? {
            // Update existing
            let mut model: daily_briefing::ActiveModel = existing.into();
            model.title = Set(title);
            model.summary = Set(summary);
            model.audio_url = Set(audio_url);
            model.audio_duration = Set(audio_duration);
            let updated = model.update(&self.db).await?;
            return Ok(updated);
        }

        // Create new
        let new_briefing = daily_briefing::ActiveModel {
            id: Set(Uuid::new_v4()),
            date: Set(date),
            title: Set(title),
            summary: Set(summary),
            audio_url: Set(audio_url),
            audio_duration: Set(audio_duration),
            created_at: Set(chrono::Utc::now().into()),
            updated_at: Set(chrono::Utc::now().into()),
        };

        let result = new_briefing.insert(&self.db).await?;
        Ok(result)
    }

    /// Update briefing with audio information
    pub async fn update_briefing_audio(
        &self,
        briefing_id: Uuid,
        audio_url: &str,
        duration: i32,
    ) -> Result<()> {
        let briefing = DailyBriefing::find_by_id(briefing_id)
            .one(&self.db)
            .await?
            .ok_or_else(|| anyhow::anyhow!("Briefing not found"))?;

        let mut model: daily_briefing::ActiveModel = briefing.into();
        model.audio_url = Set(Some(audio_url.to_string()));
        model.audio_duration = Set(Some(duration));
        model.update(&self.db).await?;

        Ok(())
    }
}
