use anyhow::Result;
use chrono::NaiveDate;
use sea_orm::{
    ActiveModelTrait, ColumnTrait, DatabaseConnection, EntityTrait, QueryFilter, QueryOrder, Set,
};
use uuid::Uuid;

use crate::entity::{
    article, category_briefing, daily_briefing, news_source, 
    CategoryBriefing, DailyBriefing, NewsSource,
};
use crate::summarizer::ClassifiedArticle;

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

    /// Save classified articles to database
    pub async fn save_articles(
        &self,
        briefing_id: Uuid,
        articles: &[ClassifiedArticle],
    ) -> Result<()> {
        for art in articles {
            let new_article = article::ActiveModel {
                id: Set(Uuid::new_v4()),
                briefing_id: Set(Some(briefing_id)),
                title: Set(art.title.clone()),
                url: Set(art.url.clone()),
                summary: Set(Some(art.summary.clone())),
                category: Set(art.category.clone()),
                source_name: Set(Some(art.source_name.clone())),
                published_at: Set(art.published_at.map(|dt| dt.into())),
            };
            new_article.insert(&self.db).await?;
        }
        Ok(())
    }

    /// Save or update a category briefing
    pub async fn upsert_category_briefing(
        &self,
        briefing_id: Uuid,
        category: &str,
        title: Option<String>,
        summary: String,
        audio_url: Option<String>,
        audio_duration: Option<i32>,
        article_count: i32,
    ) -> Result<category_briefing::Model> {
        // Check if exists
        let existing = CategoryBriefing::find()
            .filter(category_briefing::Column::BriefingId.eq(briefing_id))
            .filter(category_briefing::Column::Category.eq(category))
            .one(&self.db)
            .await?;

        if let Some(existing) = existing {
            // Update existing
            let mut model: category_briefing::ActiveModel = existing.into();
            model.title = Set(title);
            model.summary = Set(summary);
            model.audio_url = Set(audio_url);
            model.audio_duration = Set(audio_duration);
            model.article_count = Set(Some(article_count));
            let updated = model.update(&self.db).await?;
            return Ok(updated);
        }

        // Create new
        let new_briefing = category_briefing::ActiveModel {
            id: Set(Uuid::new_v4()),
            briefing_id: Set(Some(briefing_id)),
            category: Set(category.to_string()),
            title: Set(title),
            summary: Set(summary),
            audio_url: Set(audio_url),
            audio_duration: Set(audio_duration),
            article_count: Set(Some(article_count)),
        };

        let result = new_briefing.insert(&self.db).await?;
        Ok(result)
    }

    /// Update category briefing with audio information
    pub async fn update_category_briefing_audio(
        &self,
        category_briefing_id: Uuid,
        audio_url: &str,
        duration: i32,
    ) -> Result<()> {
        let briefing = CategoryBriefing::find_by_id(category_briefing_id)
            .one(&self.db)
            .await?
            .ok_or_else(|| anyhow::anyhow!("Category briefing not found"))?;

        let mut model: category_briefing::ActiveModel = briefing.into();
        model.audio_url = Set(Some(audio_url.to_string()));
        model.audio_duration = Set(Some(duration));
        model.update(&self.db).await?;

        Ok(())
    }

    /// Get all category briefings for a daily briefing
    pub async fn get_category_briefings(
        &self,
        briefing_id: Uuid,
    ) -> Result<Vec<category_briefing::Model>> {
        let briefings = CategoryBriefing::find()
            .filter(category_briefing::Column::BriefingId.eq(briefing_id))
            .order_by_asc(category_briefing::Column::Category)
            .all(&self.db)
            .await?;

        Ok(briefings)
    }

    /// Update news source crawl status (success)
    pub async fn update_source_crawl_success(&self, source_id: Uuid) -> Result<()> {
        let source = NewsSource::find_by_id(source_id)
            .one(&self.db)
            .await?
            .ok_or_else(|| anyhow::anyhow!("News source not found"))?;

        let mut model: news_source::ActiveModel = source.into();
        model.last_crawled_at = Set(Some(chrono::Utc::now().into()));
        model.error_message = Set(None);
        model.update(&self.db).await?;

        Ok(())
    }

    /// Update news source crawl status (failure)
    pub async fn update_source_crawl_error(&self, source_id: Uuid, error: &str) -> Result<()> {
        let source = NewsSource::find_by_id(source_id)
            .one(&self.db)
            .await?
            .ok_or_else(|| anyhow::anyhow!("News source not found"))?;

        let mut model: news_source::ActiveModel = source.into();
        model.last_crawled_at = Set(Some(chrono::Utc::now().into()));
        model.error_message = Set(Some(error.chars().take(500).collect())); // Truncate to 500 chars
        model.update(&self.db).await?;

        Ok(())
    }
}
