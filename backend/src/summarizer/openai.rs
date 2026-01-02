use anyhow::{Context, Result};
use chrono::Local;
use serde::{Deserialize, Serialize};
use tracing::{debug, info};

use super::ClassifiedArticle;

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

    /// Generate comprehensive briefing from classified articles (8-10 articles across all categories)
    pub async fn generate_comprehensive_briefing(&self, articles: &[ClassifiedArticle]) -> Result<String> {
        if articles.is_empty() {
            return Ok("No AI news articles found today.".to_string());
        }

        let today = Local::now().format("%Y-%m-%d").to_string();
        info!("Generating comprehensive briefing from {} classified articles", articles.len());

        // Prepare articles with category info
        let articles_text = articles
            .iter()
            .take(50) // Limit to avoid token overflow
            .enumerate()
            .map(|(i, a)| {
                format!(
                    "{}. [{}][{}] {}\nURL: {}\n摘要: {}",
                    i + 1,
                    a.category,
                    a.source_name,
                    a.title,
                    a.url,
                    a.summary
                )
            })
            .collect::<Vec<_>>()
            .join("\n\n---\n\n");

        let system_prompt = r###"你是一名AI新闻编辑，负责生成每日AI新闻综合简报。

【严格规则】你的回复必须以 ## 今日要闻 开头，禁止输出任何分析过程。

【输出格式】：

## 今日要闻

（5～8句话概述今日AI领域的整体趋势和重要动态，覆盖多个分类）

## 重点新闻

### 新闻标题（中文）

新闻内容摘要（3～6句话）

[阅读原文](原文链接)

---

（选取 8-10 条最重要的新闻，从各分类中精选）

【要求】
- 从各分类（llm/agent/multimodal/coding/infra/robotics/research/apps/industry/cloud_native）中精选最重要的新闻
- 优先选择：重大发布、突破性进展、行业影响大的事件
- 全部使用中文（简体）
- 中文、数字、英文之间用空格隔开
- 链接必须使用原文的真实 URL"###;

        let user_prompt = format!(
            "Today is {}. Generate a comprehensive daily briefing selecting the 8-10 most important news from these classified articles:\n\n{}",
            today, articles_text
        );

        self.call_llm(&system_prompt, &user_prompt).await
    }

    /// Generate category-specific briefing (5-10 articles for one category)
    pub async fn generate_category_briefing(&self, category: &str, category_name: &str, articles: &[ClassifiedArticle]) -> Result<String> {
        if articles.is_empty() {
            return Ok(format!("今日没有 {} 相关新闻。", category_name));
        }

        info!("Generating {} briefing from {} articles", category, articles.len());

        // Prepare articles
        let articles_text = articles
            .iter()
            .take(15) // Limit per category
            .enumerate()
            .map(|(i, a)| {
                format!(
                    "{}. [{}] {}\nURL: {}\n摘要: {}",
                    i + 1,
                    a.source_name,
                    a.title,
                    a.url,
                    a.summary
                )
            })
            .collect::<Vec<_>>()
            .join("\n\n---\n\n");

        let system_prompt = format!(
            r###"你是一名AI新闻编辑，负责生成 {} 领域的新闻简报。

【输出格式】：

## {} 今日动态

（2～4句话概述今日该领域的整体趋势）

## 详细新闻

### 新闻标题（中文）

新闻内容摘要（2～4句话）

[阅读原文](原文链接)

---

（选取 5-10 条该分类最重要的新闻）

【要求】
- 只关注 {} 领域的新闻
- 全部使用中文（简体）
- 中文、数字、英文之间用空格隔开
- 链接必须使用原文的真实 URL
- 摘要简洁有信息量"###,
            category_name, category_name, category_name
        );

        let user_prompt = format!(
            "Generate a {} news briefing from these articles:\n\n{}",
            category_name, articles_text
        );

        self.call_llm(&system_prompt, &user_prompt).await
    }

    /// Internal method to call LLM API
    async fn call_llm(&self, system_prompt: &str, user_prompt: &str) -> Result<String> {
        let request = ChatRequest {
            model: self.model.clone(),
            messages: vec![
                Message {
                    role: "system".to_string(),
                    content: system_prompt.to_string(),
                },
                Message {
                    role: "user".to_string(),
                    content: user_prompt.to_string(),
                },
            ],
            temperature: 0.7,
            max_tokens: 4000,
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

