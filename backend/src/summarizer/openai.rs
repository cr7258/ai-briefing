use anyhow::{Context, Result};
use chrono::Local;
use serde::{Deserialize, Serialize};
use std::time::Duration;
use tokio_retry::strategy::{jitter, ExponentialBackoff};
use tokio_retry::Retry;
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
            .timeout(std::time::Duration::from_secs(600)) // 10 minutes timeout
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

### 原文标题

新闻内容摘要（3～6句话）

[阅读原文](原文链接)

---

（选取 8-10 条最重要的新闻，从各分类中精选）

【要求】
- 中文、数字、英文之间必须用空格隔开（如：发布 GPT-5 模型、提升 30% 性能）
- 新闻标题：中文标题保留原样，英文标题翻译成中文
- 从各分类（LLM/Agent/Multimodal/Coding/Infra/Robotics/App/Industry/Cloud Native）中精选最重要的新闻
- 优先选择：重大发布、突破性进展、行业影响大的事件
- 摘要使用中文（简体）
- 链接必须使用原文的真实 URL
- [阅读原文] 链接单独一行显示"###;

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
            r###"你是一名 AI 新闻编辑，负责生成 {} 领域的新闻简报。

【输出格式】：

## {} 今日动态

（5～8 句话概述今日该领域的整体趋势）

## 详细新闻

### 原文标题

新闻内容摘要（3～6 句话）

[阅读原文](原文链接)

---

【要求】
- 中文、数字、英文之间必须用空格隔开（如：发布 GPT-5 模型、提升 30% 性能）
- 新闻标题：中文标题保留原样，英文标题翻译成中文
- 有多少条新闻就展示多少条（最多 10 条）
- 只输出新闻内容，禁止添加任何解释、说明、注释或请求更多内容的文字
- 摘要使用中文（简体）
- 链接必须使用原文的真实 URL
- [阅读原文] 链接单独一行显示"###,
            category_name, category_name
        );

        let user_prompt = format!(
            "Generate a {} news briefing from these articles:\n\n{}",
            category_name, articles_text
        );

        self.call_llm(&system_prompt, &user_prompt).await
    }

    /// Internal method to call LLM API with retry
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
        };

        let url = format!("{}/chat/completions", self.base_url);
        debug!("Sending request to: {}", url);

        let retry_strategy = ExponentialBackoff::from_millis(2000)
            .max_delay(Duration::from_secs(30))
            .map(jitter)
            .take(5); // Retry up to 5 times

        let summary = Retry::spawn(retry_strategy, || async {
            let response = self.client
                .post(&url)
                .header("Authorization", format!("Bearer {}", self.api_key))
                .json(&request)
                .send()
                .await
                .map_err(|e| anyhow::anyhow!("Request failed: {}", e))?;

            let status = response.status();
            if !status.is_success() {
                let error_text = response.text().await.unwrap_or_default();
                return Err(anyhow::anyhow!("API error ({}): {}", status, error_text));
            }

            let chat_response: ChatResponse = response
                .json()
                .await
                .map_err(|e| anyhow::anyhow!("Failed to parse response: {}", e))?;

            let content = chat_response
                .choices
                .first()
                .map(|c| c.message.content.clone())
                .unwrap_or_default();
            
            if content.is_empty() {
                return Err(anyhow::anyhow!("Empty response from LLM"));
            }
            
            Ok(content)
        })
        .await
        .context("Failed to call LLM API after retries")?;

        info!("Generated summary with {} characters", summary.len());
        Ok(summary)
    }
}

