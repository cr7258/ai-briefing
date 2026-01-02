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
    /// MiniMax specific: separate thinking content from final output
    #[serde(skip_serializing_if = "Option::is_none")]
    reasoning_split: Option<bool>,
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

        let system_prompt = r###"你是一名AI新闻编辑，负责生成每日AI新闻简报。

【严格规则】你的回复必须以 ## 今日要闻 开头，禁止输出任何以下内容：
- 禁止：分析过程、思考过程、解释说明
- 禁止：类似"从文章中，我可以看到..."、"主要主题包括..."等分析性语句
- 禁止：任何不属于最终简报的内容

【输出格式】（必须严格遵守）：

## 今日要闻

（5～8句话概述今日AI领域的整体趋势和重要动态）

## 重点新闻

### 新闻标题（中文）

新闻内容摘要（3～6句话）

[阅读原文](原文链接)

---

### 新闻标题（中文）

新闻内容摘要（3～6句话）

[阅读原文](原文链接)

（选取5-8条最重要的新闻）

【要求】
- 全部使用中文（简体）
- 中文、数字、英文之间用空格隔开（如：AI 技术、2024 年、OpenAI 发布）
- 聚焦最重要、最有影响力的新闻
- 每条新闻包含：中文标题、摘要段落、阅读原文链接
- 链接必须使用原文的真实URL
- 摘要简洁有信息量"###;

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
            // MiniMax: separate thinking content to reasoning_details field
            reasoning_split: Some(true),
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
    pub fn generate_title(&self, date: chrono::NaiveDate) -> String {
        let date_str = date.format("%Y年%m月%d日").to_string();
        format!("{} AI 日报", date_str)
    }
}

