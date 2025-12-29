mod rss;

pub use rss::*;

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Crawled article from any source
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Article {
    pub title: String,
    pub url: String,
    pub content: Option<String>,
    pub summary: Option<String>,
    pub published_at: Option<DateTime<Utc>>,
    pub source_name: String,
}

impl Article {
    /// Get display content for AI summarization
    pub fn get_content_for_summary(&self) -> String {
        if let Some(content) = &self.content {
            if !content.is_empty() {
                return content.clone();
            }
        }
        if let Some(summary) = &self.summary {
            return summary.clone();
        }
        self.title.clone()
    }
}

