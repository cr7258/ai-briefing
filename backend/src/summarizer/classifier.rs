use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use tracing::{debug, info, warn};

use crate::crawler::Article;

/// Available article categories
pub const CATEGORIES: &[&str] = &[
    "llm",         // Large Language Models
    "agent",       // AI Agents
    "multimodal",  // Image/Video/Audio generation
    "coding",      // AI Coding assistants
    "infra",       // AI Infrastructure (GPU, frameworks)
    "robotics",    // Robotics & Embodied AI
    "research",    // Academic research
    "apps",        // AI Applications
    "industry",    // Industry news (funding, policy)
    "cloud_native", // Cloud Native (K8s, containers)
];

/// Classified article with category and summary
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClassifiedArticle {
    pub title: String,
    pub url: String,
    pub summary: String,
    pub category: String,
    pub source_name: String,
    pub published_at: Option<chrono::DateTime<chrono::Utc>>,
}

/// AI-powered article classifier
pub struct ArticleClassifier {
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
    #[serde(skip_serializing_if = "Option::is_none")]
    reasoning_split: Option<bool>, // MiniMax: separate thinking from content
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

#[derive(Debug, Deserialize)]
struct ClassificationResult {
    index: usize,
    category: String,
    summary: String,
}

impl ArticleClassifier {
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

    /// Classify articles and generate one-line summaries
    pub async fn classify(&self, articles: &[Article]) -> Result<Vec<ClassifiedArticle>> {
        if articles.is_empty() {
            return Ok(vec![]);
        }

        info!("Classifying {} articles", articles.len());

        // Prepare articles text for the prompt
        let articles_text = articles
            .iter()
            .enumerate()
            .map(|(i, a)| {
                let content = a.get_content_for_summary();
                format!(
                    "{}. [{}] {}\n{}",
                    i, a.source_name, a.title, content
                )
            })
            .collect::<Vec<_>>()
            .join("\n\n---\n\n");

        let system_prompt = format!(
            r#"你是一个 AI 新闻分类专家。请对以下文章进行分类并生成一句话摘要。

可选分类：
- llm: 大语言模型（GPT、Claude、Gemini、Llama、模型发布/更新/评测）
- agent: AI 代理（AutoGPT、LangChain、MCP、工作流自动化、多智能体）
- multimodal: 多模态（图像/视频/音频生成、DALL-E、Sora、Runway）
- coding: AI 编程（Copilot、Cursor、Devin、代码生成）
- infra: 基础设施（GPU、芯片、推理框架、MLOps、云服务）
- robotics: 机器人（具身智能、自动驾驶）
- research: 研究（学术论文、新算法、AI 安全）
- apps: 应用（产品发布、AI 搜索、企业应用）
- industry: 行业（融资、收购、人事、政策法规）
- cloud_native: 云原生（Kubernetes、容器、Serverless、DevOps、CNCF）

请返回 JSON 数组，格式如下：
[
  {{"index": 0, "category": "llm", "summary": "一句话中文摘要（30-60字）"}},
  {{"index": 1, "category": "agent", "summary": "一句话中文摘要（30-60字）"}}
]

要求：
1. category 只能从上述 10 个分类中选择，禁止使用其他分类
2. 每篇文章必须分配一个分类
3. 摘要必须用中文，简洁有信息量
4. 中文、数字、英文之间用空格隔开
5. 只返回 JSON 数组，不要其他内容"#
        );

        let user_prompt = format!("请分类以下 {} 篇文章：\n\n{}", articles.len(), articles_text);

        let request = ChatRequest {
            model: self.model.clone(),
            messages: vec![
                Message {
                    role: "system".to_string(),
                    content: system_prompt,
                },
                Message {
                    role: "user".to_string(),
                    content: user_prompt,
                },
            ],
            temperature: 0.3,
            max_tokens: 4000,
            reasoning_split: Some(true), // MiniMax: put thinking in separate field
        };

        let url = format!("{}/chat/completions", self.base_url);
        debug!("Sending classification request to: {}", url);

        let response = self
            .client
            .post(&url)
            .header("Authorization", format!("Bearer {}", self.api_key))
            .json(&request)
            .send()
            .await
            .context("Failed to send classification request")?;

        let status = response.status();
        if !status.is_success() {
            let error_text = response.text().await.unwrap_or_default();
            anyhow::bail!("Classification API error ({}): {}", status, error_text);
        }

        let chat_response: ChatResponse = response
            .json()
            .await
            .context("Failed to parse classification response")?;

        let content = chat_response
            .choices
            .first()
            .map(|c| c.message.content.clone())
            .unwrap_or_default();

        debug!("LLM classification response:\n{}", content);

        if content.is_empty() {
            anyhow::bail!("LLM returned empty response");
        }

        // Parse JSON response
        let results: Vec<ClassificationResult> = self.parse_classification_json(&content)
            .with_context(|| format!("Failed to parse JSON from:\n{}", content))?;

        // Build classified articles
        let mut classified = Vec::new();
        for result in results {
            if result.index >= articles.len() {
                warn!("Invalid article index: {}", result.index);
                continue;
            }

            let article = &articles[result.index];
            let category = if CATEGORIES.contains(&result.category.as_str()) {
                result.category
            } else {
                warn!("Unknown category '{}', defaulting to 'industry'", result.category);
                "industry".to_string()
            };

            classified.push(ClassifiedArticle {
                title: article.title.clone(),
                url: article.url.clone(),
                summary: result.summary,
                category,
                source_name: article.source_name.clone(),
                published_at: article.published_at,
            });
        }

        info!("Classified {} articles into categories", classified.len());
        Ok(classified)
    }

    /// Parse JSON from AI response (handles markdown code blocks)
    fn parse_classification_json(&self, content: &str) -> Result<Vec<ClassificationResult>> {
        // Try to extract JSON from markdown code block
        let json_str = if content.contains("```json") {
            content
                .split("```json")
                .nth(1)
                .and_then(|s| s.split("```").next())
                .unwrap_or(content)
                .trim()
        } else if content.contains("```") {
            content
                .split("```")
                .nth(1)
                .unwrap_or(content)
                .trim()
        } else {
            content.trim()
        };

        serde_json::from_str(json_str)
            .context("Failed to parse classification JSON")
    }

    /// Group classified articles by category
    pub fn group_by_category(articles: &[ClassifiedArticle]) -> std::collections::HashMap<String, Vec<ClassifiedArticle>> {
        let mut groups: std::collections::HashMap<String, Vec<ClassifiedArticle>> = std::collections::HashMap::new();
        
        for article in articles {
            groups
                .entry(article.category.clone())
                .or_default()
                .push(article.clone());
        }

        // Sort each group by published_at (newest first)
        for articles in groups.values_mut() {
            articles.sort_by(|a, b| {
                b.published_at
                    .unwrap_or(chrono::Utc::now())
                    .cmp(&a.published_at.unwrap_or(chrono::Utc::now()))
            });
        }

        groups
    }
}

