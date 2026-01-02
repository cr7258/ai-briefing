use anyhow::{Context, Result};
use chrono::{DateTime, Duration, Utc};
use feed_rs::parser;
use tracing::{debug, warn};

use super::Article;
use crate::entity::news_source;

/// RSS feed crawler
pub struct RssCrawler {
    client: reqwest::Client,
}

impl RssCrawler {
    /// Create a new RSS crawler
    pub fn new() -> Self {
        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(30))
            .user_agent("AI-Briefing-Bot/1.0")
            .build()
            .expect("Failed to create HTTP client");

        Self { client }
    }

    /// Fetch and parse RSS feed from a source
    /// 
    /// # Arguments
    /// * `source` - The news source to fetch from
    /// * `hours_back` - Only include articles published within this many hours
    /// * `end_time` - The end time for the time range (defaults to now)
    pub async fn fetch(
        &self,
        source: &news_source::Model,
        hours_back: i64,
        end_time: Option<DateTime<Utc>>,
    ) -> Result<Vec<Article>> {
        debug!("Fetching RSS feed: {} ({})", source.name, source.url);

        let response = self
            .client
            .get(&source.url)
            .send()
            .await
            .context("Failed to fetch RSS feed")?;

        let bytes = response
            .bytes()
            .await
            .context("Failed to read response body")?;

        let feed = parser::parse(&bytes[..]).context("Failed to parse RSS feed")?;

        let end = end_time.unwrap_or_else(Utc::now);
        let cutoff_time = end - Duration::hours(hours_back);
        let mut articles = Vec::new();

        for entry in feed.entries {
            // Filter articles by time range
            if let Some(published) = entry.published {
                // Skip articles older than cutoff
                if published < cutoff_time {
                    continue;
                }
                // Skip articles newer than end_time (for historical queries)
                if published > end {
                    continue;
                }
            }

            let title = entry
                .title
                .map(|t| t.content)
                .unwrap_or_else(|| "Untitled".to_string());

            let url = entry
                .links
                .first()
                .map(|l| l.href.clone())
                .unwrap_or_default();

            if url.is_empty() {
                warn!("Skipping article without URL: {}", title);
                continue;
            }

            // Extract content from RSS
            let content = entry
                .content
                .and_then(|c| c.body)
                .map(|html| strip_html_tags(&html));

            let summary = entry.summary.map(|s| strip_html_tags(&s.content));

            let published_at = entry.published.or(entry.updated);

            articles.push(Article {
                title,
                url,
                content,
                summary,
                published_at,
                source_name: source.name.clone(),
            });
        }

        debug!(
            "Fetched {} articles from {} (filtered by last {}h)",
            articles.len(),
            source.name,
            hours_back
        );

        Ok(articles)
    }

    /// Fetch articles from multiple sources
    /// 
    /// # Arguments
    /// * `sources` - List of news sources to fetch from
    /// * `hours_back` - Only include articles published within this many hours
    /// * `end_time` - The end time for the time range (defaults to now)
    pub async fn fetch_all(
        &self,
        sources: &[news_source::Model],
        hours_back: i64,
        end_time: Option<DateTime<Utc>>,
    ) -> Vec<Article> {
        let mut all_articles = Vec::new();

        for source in sources {
            if source.feed_type != "rss" {
                continue;
            }

            match self.fetch(source, hours_back, end_time).await {
                Ok(articles) => {
                    all_articles.extend(articles);
                }
                Err(e) => {
                    warn!("Failed to fetch {}: {}", source.name, e);
                }
            }
        }

        // Sort by published date (newest first)
        all_articles.sort_by(|a, b| {
            b.published_at
                .unwrap_or(Utc::now())
                .cmp(&a.published_at.unwrap_or(Utc::now()))
        });

        all_articles
    }
}

impl Default for RssCrawler {
    fn default() -> Self {
        Self::new()
    }
}

/// Strip HTML tags from content
fn strip_html_tags(html: &str) -> String {
    let document = scraper::Html::parse_fragment(html);
    let mut text = String::new();

    for node in document.root_element().descendants() {
        if let Some(text_node) = node.value().as_text() {
            text.push_str(text_node);
        }
    }

    // Clean up whitespace
    text.split_whitespace().collect::<Vec<_>>().join(" ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_strip_html_tags() {
        let html = "<p>Hello <strong>World</strong>!</p>";
        assert_eq!(strip_html_tags(html), "Hello World !");
    }
}

