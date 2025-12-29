use anyhow::{Context, Result};
use chrono::Local;
use serde::{Deserialize, Serialize};
use tracing::{debug, info};

use crate::crawler::Article;

/// OpenAI chat completion client (compatible with OpenAI API format)
pub struct OpenAISummarizer {
    client: reqwest::Client,
    api_key: String,
    base_url: String,
    model: String,
}

#[derive(Debug, Serialize)]
struct ChatRequest {
    model: String,
    messages: Vec<Message>,
    temperature: f32,
    max_tokens: u32,
}

#[derive(Debug, Serialize, Deserialize)]
struct Message {
    role: String,
    content: String,
}

#[derive(Debug, Deserialize)]
struct ChatResponse {
    choices: Vec<Choice>,
}

#[derive(Debug, Deserialize)]
struct Choice {
    message: Message,
}

impl OpenAISummarizer {
    /// Create a new OpenAI summarizer
    /// Supports OpenAI API and compatible APIs (DeepSeek, Moonshot, etc.)
    pub fn new(api_key: String, base_url: String, model: String) -> Self {
        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(120))
            .build()
            .expect("Failed to create HTTP client");

        Self {
            client,
            api_key,
            base_url,
            model,
        }
    }

    /// Generate daily briefing summary from articles
    pub async fn generate_summary(&self, articles: &[Article]) -> Result<String> {
        if articles.is_empty() {
            return Ok("No AI news articles found today.".to_string());
        }

        let today = Local::now().format("%Y-%m-%d").to_string();
        info!("Generating summary for {} articles", articles.len());

        // Prepare articles content for the prompt
        let articles_text = articles
            .iter()
            .take(30) // Limit to avoid token overflow
            .enumerate()
            .map(|(i, a)| {
                let content = a.get_content_for_summary();
                // Truncate long content
                let content = if content.len() > 1000 {
                    format!("{}...", &content[..1000])
                } else {
                    content
                };
                format!(
                    "{}. [{}] {}\nURL: {}\n{}",
                    i + 1,
                    a.source_name,
                    a.title,
                    a.url,
                    content
                )
            })
            .collect::<Vec<_>>()
            .join("\n\n---\n\n");

        let system_prompt = r#"You are an AI news editor. Generate a daily AI news briefing in Chinese (Simplified).

Output format (Markdown):

## 今日要闻

(Write 2-3 paragraphs summarizing the overall trends and key themes from today's AI news)

## 重点新闻

### [News Title 1]

[Summary paragraph about this news item, 2-3 sentences]

[阅读原文](original_url)

---

### [News Title 2]

[Summary paragraph about this news item, 2-3 sentences]

[阅读原文](original_url)

(Continue for 5-8 most important news items)

Guidelines:
- Write in Chinese (Simplified)
- Focus on the most significant and impactful news
- Each news item should have: Chinese title, summary paragraph, and "阅读原文" link
- The "阅读原文" link must use the EXACT URL from the source
- Keep summaries concise but informative
- Highlight trends, breakthroughs, and industry-impacting news"#;

        let user_prompt = format!(
            "Today is {}. Generate a daily AI news briefing from these articles:\n\n{}",
            today, articles_text
        );

        let request = ChatRequest {
            model: self.model.clone(),
            messages: vec![
                Message {
                    role: "system".to_string(),
                    content: system_prompt.to_string(),
                },
                Message {
                    role: "user".to_string(),
                    content: user_prompt,
                },
            ],
            temperature: 0.7,
            max_tokens: 4000,
        };

        let url = format!("{}/chat/completions", self.base_url);
        debug!("Sending request to: {}", url);

        let response = self
            .client
            .post(&url)
            .header("Authorization", format!("Bearer {}", self.api_key))
            .json(&request)
            .send()
            .await
            .context("Failed to send request to LLM API")?;

        let status = response.status();
        if !status.is_success() {
            let error_text = response.text().await.unwrap_or_default();
            anyhow::bail!("OpenAI API error ({}): {}", status, error_text);
        }

        let chat_response: ChatResponse = response
            .json()
            .await
            .context("Failed to parse OpenAI response")?;

        let summary = chat_response
            .choices
            .first()
            .map(|c| c.message.content.clone())
            .unwrap_or_default();

        info!("Generated summary with {} characters", summary.len());

        Ok(summary)
    }

    /// Generate a title for the daily briefing
    pub fn generate_title(&self) -> String {
        let today = Local::now().format("%Y年%m月%d日").to_string();
        format!("{} AI 日报", today)
    }
}

