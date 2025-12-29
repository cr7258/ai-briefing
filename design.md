# AI 日报 - 设计文档

## 📋 项目概述

### 产品定位

每天自动抓取 AI 领域新闻，生成一份精炼的 AI 新闻摘要，支持语音播报。

### 核心功能

- 🕷️ 自动爬取 AI 新闻（RSS + 网页）
- 🤖 AI 生成每日摘要（OpenAI）
- 🔊 语音播报（MiniMax TTS）
- 📱 多平台客户端（iOS / Android / Web / macOS / Windows）

### 支持平台

| 平台 | 技术 |
|------|------|
| iOS | Flutter |
| Android | Flutter |
| Web | Flutter |
| macOS | Flutter |
| Windows | Flutter |

---

## 🏗️ 技术架构

```
┌─────────────────────────────────────────────────────────────┐
│                      整体架构                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────────────────────────────────────────────────┐  │
│   │  Rust 后端 (定时任务)                                 │  │
│   │  ├── 爬取新闻（从 Supabase 读取新闻源配置）            │  │
│   │  ├── OpenAI 生成文字摘要                              │  │
│   │  ├── MiniMax 生成语音                                 │  │
│   │  ├── 上传音频到 Supabase Storage                      │  │
│   │  └── 写入摘要到 Supabase Database                     │  │
│   └─────────────────────────────────────────────────────┘  │
│                       │    ▲                                │
│                       ▼    │ 读取新闻源                      │
│   ┌─────────────────────────────────────────────────────┐  │
│   │  Supabase                                            │  │
│   │  ├── Database (PostgreSQL)                           │  │
│   │  │   ├── daily_briefings (每日摘要)                  │  │
│   │  │   └── news_sources (新闻源配置)                   │  │
│   │  └── Storage (音频文件)                              │  │
│   └─────────────────────────────────────────────────────┘  │
│                            │                                │
│                            │ 直接读取（无需后端 API）         │
│                            ▼                                │
│   ┌─────────────────────────────────────────────────────┐  │
│   │  Flutter 客户端                                      │  │
│   │  ├── 显示今日摘要                                    │  │
│   │  ├── 播放语音                                        │  │
│   │  ├── 浏览历史摘要                                    │  │
│   │  └── 查看新闻源列表（只读）                           │  │
│   └─────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| **后端** | Rust | 定时任务、爬虫、AI 调用 |
| **数据库** | Supabase (PostgreSQL) | 托管数据库，自动 API |
| **存储** | Supabase Storage | 存放音频文件 |
| **前端** | Flutter (Dart) | 一套代码，多平台 |
| **AI 摘要** | OpenAI API | gpt-4o-mini |
| **语音合成** | MiniMax API | speech-2.6-hd |

### 设计原则

1. **简单优先** - 不做用户系统，打开即用
2. **直连 Supabase** - 前端直接读取数据库，无需后端 API
3. **Rust 后端最小化** - 只负责定时任务，不提供 API

---

## 🗄️ 数据库设计

### 表结构

#### 表 1: `daily_briefings` - 每日摘要

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| date | DATE | 日期（唯一） |
| title | VARCHAR(200) | 今日标题 |
| summary | TEXT | AI 生成的摘要（**Markdown 格式**） |
| audio_url | VARCHAR(500) | 语音播报 URL |
| audio_duration | INT | 音频时长（秒） |
| created_at | TIMESTAMPTZ | 创建时间 |

#### 表 2: `news_sources` - 新闻源

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| name | VARCHAR(100) | 源名称 |
| url | VARCHAR(1000) | RSS/网站 URL |
| feed_type | VARCHAR(20) | 类型：rss / website |
| category | VARCHAR(50) | 分类 |
| is_active | BOOLEAN | 是否启用 |
| created_at | TIMESTAMPTZ | 创建时间 |

### 数据访问

| 表 | Rust 后端 | Flutter 客户端 |
|------|----------|----------------|
| daily_briefings | **写入** | 读取 |
| news_sources | 读取 | 读取 |

### RLS 策略

```sql
-- 所有人可以读取（公开数据）
CREATE POLICY "公开读取" ON daily_briefings FOR SELECT USING (true);
CREATE POLICY "公开读取" ON news_sources FOR SELECT USING (true);
```

### 默认新闻源

| 名称 | 类型 | URL |
|------|------|-----|
| TechCrunch AI | rss | `https://techcrunch.com/category/artificial-intelligence/feed/` |
| The Verge AI | rss | `https://www.theverge.com/ai-artificial-intelligence/rss/index.xml` |
| VentureBeat AI | rss | `https://venturebeat.com/category/ai/feed/` |
| AI News | rss | `https://www.artificialintelligence-news.com/feed/` |
| Hacker News AI | rss | `https://hnrss.org/newest?q=AI+OR+LLM+OR+GPT` |
| OpenAI Blog | rss | `https://openai.com/blog/rss/` |
| Hugging Face Blog | rss | `https://huggingface.co/blog/feed.xml` |
| vLLM Blog | rss | `https://blog.vllm.ai/feed.xml` |

> **提示**：大多数新闻网站都提供 RSS feed，通常在以下位置：
> - `/feed/`
> - `/rss/`
> - `/feed.xml`
> - 或在网页 `<head>` 中的 `<link rel="alternate" type="application/rss+xml">` 标签

### Twitter/X 数据源

#### AI 领域知名人物

| 名称 | Twitter | 身份 |
|------|---------|------|
| Andrej Karpathy | [@karpathy](https://x.com/karpathy) | 前 Tesla AI 总监, 前 OpenAI |
| Yann LeCun | [@ylecun](https://x.com/ylecun) | Meta AI 首席科学家 |
| Sam Altman | [@sama](https://x.com/sama) | OpenAI CEO |
| Demis Hassabis | [@demaboris](https://x.com/demaboris) | Google DeepMind CEO |
| Jim Fan | [@DrJimFan](https://x.com/DrJimFan) | NVIDIA AI 研究员 |
| François Chollet | [@fchollet](https://x.com/fchollet) | Keras 创建者 |
| Harrison Chase | [@hwchase17](https://x.com/hwchase17) | LangChain 创始人 |
| Swyx | [@swyx](https://x.com/swyx) | AI 开发者, Latent Space |
| Simon Willison | [@simonw](https://x.com/simonw) | AI 工具开发者 |

#### 获取 Twitter 数据的方式

| 方式 | 说明 | 成本 |
|------|------|------|
| **Twitter/X API** | 官方 API，需申请开发者账号 | 免费版限制严格，付费版 $100+/月 |
| **Nitter RSS** | 开源 Twitter 前端，提供 RSS | 免费，但不稳定 |
| **RSSHub** | 开源 RSS 生成器，支持 Twitter | 免费，可自建 |
| **第三方服务** | RSS.app, Feedbin 等 | 付费 |

#### 方案 1: 使用 RSSHub（推荐）

[RSSHub](https://docs.rsshub.app/) 是开源的 RSS 生成器，支持 Twitter：

```
# Twitter 用户时间线
https://rsshub.app/twitter/user/karpathy

# Twitter 搜索
https://rsshub.app/twitter/search/AI%20LLM
```

可以自建 RSSHub 服务，或使用公共实例。

#### 方案 2: 使用 Nitter

[Nitter](https://github.com/zedeus/nitter) 是开源的 Twitter 前端：

```
# Nitter RSS (需要找可用实例)
https://nitter.net/karpathy/rss
```

> ⚠️ **注意**：Nitter 公共实例不稳定，Twitter 经常封锁。建议自建或使用 RSSHub。

#### 方案 3: Twitter/X API

如果需要更稳定的数据，可以使用官方 API：

```rust
// crawler/twitter.rs
pub async fn fetch_twitter_timeline(username: &str, bearer_token: &str) -> Result<Vec<Tweet>> {
    let url = format!(
        "https://api.twitter.com/2/users/by/username/{}/tweets",
        username
    );
    
    let response = reqwest::Client::new()
        .get(&url)
        .bearer_auth(bearer_token)
        .query(&[("max_results", "10"), ("tweet.fields", "created_at,text")])
        .send()
        .await?;
    
    // 解析响应...
}
```

#### 数据库配置

```sql
-- news_sources 表添加 Twitter 源
INSERT INTO news_sources (name, url, feed_type, category) VALUES
    ('Andrej Karpathy', 'https://rsshub.app/twitter/user/karpathy', 'rss', 'twitter'),
    ('Yann LeCun', 'https://rsshub.app/twitter/user/ylecun', 'rss', 'twitter'),
    ('Sam Altman', 'https://rsshub.app/twitter/user/sama', 'rss', 'twitter'),
    ('AI Search', 'https://rsshub.app/twitter/search/AI%20AGI%20LLM', 'rss', 'twitter');
```

#### 推荐方案

```
┌─────────────────────────────────────────────────────────────┐
│                   Twitter 数据获取推荐                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   初期：使用 RSSHub 公共实例                                  │
│   └── 免费、简单、够用                                       │
│                                                             │
│   后期：自建 RSSHub 或使用 Twitter API                       │
│   └── 更稳定、可控                                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🕷️ 数据源处理

### 支持的数据源类型

| 类型 | feed_type | 处理方式 | 说明 |
|------|-----------|---------|------|
| **RSS/Atom** | `rss` | feed-rs 库解析 | 标准格式，最简单 |
| **网页爬取** | `website` | scraper 库解析 HTML | 需要配置选择器 |
| **API** | `api` | 直接 HTTP 请求 | 需要适配不同 API |

### RSS 处理流程

```
RSS URL → HTTP 请求 → XML 响应 → feed-rs 解析 → 文章列表
```

```rust
// crawler/rss.rs
use feed_rs::parser;

pub async fn crawl_rss(url: &str) -> Result<Vec<Article>> {
    // 1. 请求 RSS
    let response = reqwest::get(url).await?;
    let content = response.bytes().await?;
    
    // 2. 解析 RSS/Atom
    let feed = parser::parse(&content[..])?;
    
    // 3. 提取文章
    let articles: Vec<Article> = feed.entries
        .into_iter()
        .map(|entry| Article {
            title: entry.title.map(|t| t.content).unwrap_or_default(),
            url: entry.links.first().map(|l| l.href.clone()).unwrap_or_default(),
            content: entry.summary.map(|s| s.content),
            published_at: entry.published.or(entry.updated),
        })
        .collect();
    
    Ok(articles)
}
```

### 网页爬取处理流程

```
网页 URL → HTTP 请求 → HTML 响应 → CSS 选择器提取 → 文章列表
```

```rust
// crawler/website.rs
use scraper::{Html, Selector};

pub async fn crawl_website(url: &str, config: &ScrapeConfig) -> Result<Vec<Article>> {
    // 1. 请求网页
    let response = reqwest::get(url).await?;
    let html = response.text().await?;
    
    // 2. 解析 HTML
    let document = Html::parse_document(&html);
    
    // 3. 用 CSS 选择器提取文章
    let article_selector = Selector::parse(&config.article_selector)?;
    let title_selector = Selector::parse(&config.title_selector)?;
    let link_selector = Selector::parse(&config.link_selector)?;
    
    let articles: Vec<Article> = document
        .select(&article_selector)
        .filter_map(|el| {
            let title = el.select(&title_selector).next()?.text().collect();
            let url = el.select(&link_selector).next()?.value().attr("href")?;
            Some(Article { title, url: url.to_string(), .. })
        })
        .collect();
    
    Ok(articles)
}
```

### 网页爬取配置

对于 `feed_type = website` 的源，需要在数据库中存储 CSS 选择器配置：

```sql
-- news_sources 表额外字段
scrape_config JSONB  -- 网页爬取配置
```

```json
{
  "article_selector": "article.post",
  "title_selector": "h2.title",
  "link_selector": "a.read-more",
  "content_selector": "div.summary"
}
```

### 统一处理入口

```rust
// crawler/mod.rs
pub async fn crawl_source(source: &NewsSource) -> Result<Vec<Article>> {
    match source.feed_type.as_str() {
        "rss" => rss::crawl_rss(&source.url).await,
        "website" => {
            let config = source.scrape_config.as_ref()
                .ok_or_else(|| anyhow!("网页源缺少 scrape_config"))?;
            website::crawl_website(&source.url, config).await
        },
        "api" => api::crawl_api(&source.url, &source.api_config).await,
        _ => Err(anyhow!("未知的 feed_type: {}", source.feed_type)),
    }
}

pub async fn crawl_all_sources(sources: &[NewsSource]) -> Vec<Article> {
    let mut all_articles = Vec::new();
    
    for source in sources {
        match crawl_source(source).await {
            Ok(articles) => {
                tracing::info!("✅ {} - 获取 {} 篇文章", source.name, articles.len());
                all_articles.extend(articles);
            }
            Err(e) => {
                tracing::warn!("❌ {} - 爬取失败: {}", source.name, e);
            }
        }
    }
    
    // 去重（按 URL）
    all_articles.sort_by(|a, b| a.url.cmp(&b.url));
    all_articles.dedup_by(|a, b| a.url == b.url);
    
    all_articles
}
```

### 文章数据结构

```rust
// db/models.rs
pub struct Article {
    pub title: String,
    pub url: String,
    pub source_name: String,
    pub content: Option<String>,
    pub published_at: Option<DateTime<Utc>>,
}
```

---

## 📝 摘要内容格式

### 存储格式

摘要内容（`summary` 字段）使用 **Markdown 格式** 存储，便于前端渲染富文本。

### Markdown 结构

```markdown
## 今日要闻

（2-3段整体概述，描述今天 AI 领域的主要动态）

## 重点新闻

### 新闻标题 1

新闻摘要内容，包含关键信息...

[阅读原文](https://techcrunch.com/xxx)

---

### 新闻标题 2

新闻摘要内容，包含关键信息...

[阅读原文](https://theverge.com/xxx)

---

### 新闻标题 3

新闻摘要内容，包含关键信息...

[阅读原文](https://venturebeat.com/xxx)
```

> **说明**：每条新闻末尾的"阅读原文"是可点击的链接，点击后在浏览器中打开原始文章。

### AI Prompt 模板

```text
你是一位专业的 AI 领域新闻编辑。请根据以下新闻列表，生成一份今日 AI 新闻摘要。

要求：
1. 使用 Markdown 格式
2. 包含"今日要闻"概述（2-3段）
3. 包含"重点新闻"详情（每条新闻单独一个三级标题）
4. 每条新闻末尾附上原文链接
5. 语言简洁专业，突出关键信息

输出格式：

## 今日要闻

（整体概述）

## 重点新闻

### 新闻标题

新闻摘要...

[阅读原文](原文链接)

---

（更多新闻...）
```

### 前端渲染

使用 `flutter_markdown` 库渲染 Markdown 内容：

```dart
import 'package:flutter_markdown/flutter_markdown.dart';

MarkdownBody(
  data: briefing.summary,
  onTapLink: (text, href, title) {
    if (href != null) launchUrl(Uri.parse(href));
  },
)
```

---

## 🦀 Rust 后端设计

### 职责

1. **定时任务** - 每天 8:00 执行
2. **新闻爬取** - RSS 解析、网页爬取
3. **AI 摘要** - 调用 OpenAI 生成摘要
4. **语音合成** - 调用 MiniMax 生成音频
5. **数据存储** - 写入 Supabase

### 模块划分

```
backend/src/
├── main.rs              # 入口
├── config.rs            # 配置
├── error.rs             # 错误处理
│
├── db/                  # 数据库
│   ├── mod.rs
│   ├── pool.rs          # 连接池
│   └── models.rs        # 数据模型
│
├── crawler/             # 爬虫
│   ├── mod.rs
│   ├── rss.rs           # RSS 爬取
│   ├── website.rs       # 网页爬取
│   └── sources.rs       # 新闻源配置
│
├── summarizer/          # 摘要生成
│   ├── mod.rs
│   ├── openai.rs        # OpenAI 客户端
│   └── prompts.rs       # Prompt 模板
│
├── tts/                 # 语音合成
│   ├── mod.rs
│   └── minimax.rs       # MiniMax TTS
│
├── storage/             # 存储
│   ├── mod.rs
│   └── supabase.rs      # Supabase Storage
│
└── jobs/                # 定时任务
    ├── mod.rs
    └── daily_briefing.rs
```

### 每日任务流程

```
1. 从 Supabase 读取活跃的新闻源
2. 爬取所有新闻源
3. 去重、清洗
4. 调用 OpenAI 生成摘要
5. 调用 MiniMax 生成语音
6. 上传音频到 Supabase Storage
7. 写入摘要到 Supabase Database
```

### 依赖

```toml
[dependencies]
# Web
axum = "0.7"
tokio = { version = "1", features = ["full"] }

# Database
sqlx = { version = "0.7", features = ["runtime-tokio", "postgres", "chrono", "uuid", "json"] }

# HTTP
reqwest = { version = "0.11", features = ["json", "gzip"] }

# Parsing
feed-rs = "1.4"          # RSS
scraper = "0.18"         # HTML

# AI
async-openai = "0.18"

# Scheduling
tokio-cron-scheduler = "0.10"

# Utils
serde = { version = "1", features = ["derive"] }
serde_json = "1"
chrono = { version = "0.4", features = ["serde"] }
uuid = { version = "1", features = ["serde", "v4"] }
base64 = "0.21"
tracing = "0.1"
tracing-subscriber = "0.3"
anyhow = "1"
dotenvy = "0.15"
```

---

## 📱 Flutter 客户端设计

### 职责

1. **显示摘要** - 今日摘要、历史摘要
2. **播放语音** - 音频播放器
3. **查看新闻源** - 展示系统内置的新闻源（只读）

### 数据获取方式

**直接连接 Supabase**，不通过 Rust 后端 API：

```dart
// 直接查询 Supabase
final data = await supabase
    .from('daily_briefings')
    .select()
    .eq('date', today)
    .single();
```

### 模块划分

```
app/lib/
├── main.dart            # 入口
├── app.dart             # App 配置
│
├── config/              # 配置
│   ├── constants.dart
│   ├── supabase.dart    # Supabase 初始化
│   ├── theme.dart       # 主题
│   └── routes.dart      # 路由
│
├── models/              # 数据模型
│   ├── briefing.dart    # 摘要
│   └── news_source.dart # 新闻源
│
├── services/            # 服务层（Supabase 交互）
│   ├── briefing_service.dart
│   └── source_service.dart
│
├── screens/             # 页面
│   ├── home/            # 首页（今日摘要）
│   ├── briefing/        # 摘要详情、历史
│   ├── sources/         # 新闻源列表
│   └── settings/        # 设置
│
├── widgets/             # 组件
│   ├── briefing_card.dart
│   ├── article_item.dart
│   ├── audio_player.dart
│   ├── loading_widget.dart
│   └── error_widget.dart
│
└── utils/               # 工具
    ├── date_utils.dart
    └── url_utils.dart
```

### 页面列表

| 页面 | 功能 |
|------|------|
| HomeScreen | 首页，显示今日摘要 |
| BriefingDetailScreen | 摘要详情，语音播放 |
| BriefingHistoryScreen | 历史摘要列表 |
| SourcesScreen | 新闻源列表（只读） |
| SettingsScreen | 设置、关于 |

### 依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Supabase
  supabase_flutter: ^2.3.0
  
  # 状态管理
  flutter_riverpod: ^2.4.0
  
  # 音频播放
  just_audio: ^0.9.36
  
  # Markdown 渲染
  flutter_markdown: ^0.6.18
  
  # UI
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  
  # 工具
  url_launcher: ^6.2.0
  intl: ^0.18.0
```

---

## 💰 成本估算

| 服务 | 费用/月 | 说明 |
|------|---------|------|
| Supabase | $0 | 免费版足够 |
| 服务器 (Rust) | ~$5 | Fly.io / Railway |
| OpenAI API | ~$3 | 每天调用一次 |
| MiniMax TTS | ~$5-10 | 按字符计费 |
| **总计** | **~$13-18** | |

---

## 📁 完整目录结构

```
ai-briefing/
│
├── README.md
├── design.md                      # 本文档
├── .gitignore
│
├── backend/                       # Rust 后端
│   ├── Cargo.toml
│   ├── .env.example
│   ├── Dockerfile
│   └── src/
│       ├── main.rs
│       ├── config.rs
│       ├── error.rs
│       ├── db/
│       ├── crawler/
│       ├── summarizer/
│       ├── tts/
│       ├── storage/
│       └── jobs/
│
├── app/                           # Flutter 客户端
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── app.dart
│       ├── config/
│       ├── models/
│       │   ├── briefing.dart      # 摘要模型
│       │   └── news_source.dart   # 新闻源模型
│       ├── services/
│       ├── screens/
│       ├── widgets/
│       └── utils/
│
└── supabase/                      # Supabase 配置
    └── migrations/
        ├── 001_create_tables.sql
        └── 002_seed_sources.sql
```

---

## 🔮 未来扩展（暂不实现）

- [ ] 用户系统（登录、注册）
- [ ] 用户自定义新闻源
- [ ] 收藏功能
- [ ] 推送通知
- [ ] 多语言支持
- [ ] 个性化推荐

---

## 📝 备注

1. **暂不实现用户系统** - 简化开发，打开即用
2. **前端直连 Supabase** - 不通过 Rust 后端 API 读取数据
3. **Rust 后端最小化** - 只负责定时任务，不提供 REST API
4. **语音合成** - 使用 MiniMax speech-2.6-hd 模型
5. **摘要格式** - 使用 Markdown 格式存储，前端用 flutter_markdown 渲染

