use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use serde_json;
use tracing::{debug, info, warn};
use uuid::Uuid;

use super::utils::markdown_to_plain_text;

/// Volcengine TTS client (Long text async API)
/// Doc: https://www.volcengine.com/docs/6561/1096680
/// Auth: https://www.volcengine.com/docs/6561/1105162
pub struct VolcengineTTS {
    client: reqwest::Client,
    base_url: String,
    appid: String,
    access_token: String,
    voice_type: String,
}

// Fixed Resource-Id for long text TTS service
const RESOURCE_ID: &str = "volc.tts_async.default";

// API endpoints
const SUBMIT_PATH: &str = "/api/v1/tts_async/submit";
const QUERY_PATH: &str = "/api/v1/tts_async/query";

#[derive(Debug, Serialize)]
struct SubmitRequest {
    appid: String,
    reqid: String,
    text: String,
    voice_type: String,
    format: String,
    speed_ratio: f32,
}

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct SubmitResponse {
    task_id: Option<String>,
    code: Option<i32>,
    message: Option<String>,
}

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct QueryResponse {
    task_id: Option<String>,
    task_status: Option<i32>, // 0-processing, 1-success, 2-failed
    audio_url: Option<String>,
    text_length: Option<i32>,
    code: Option<i32>,
    message: Option<String>,
}

/// TTS synthesis result
pub struct TTSResult {
    pub audio_data: Vec<u8>,
    pub duration_seconds: i32,
}

impl VolcengineTTS {
    /// Create a new Volcengine TTS client
    ///
    /// # Arguments
    /// * `base_url` - API base URL (e.g., "https://openspeech.bytedance.com")
    /// * `appid` - App ID from Volcengine console
    /// * `access_token` - Access token for authorization
    /// * `voice_type` - Voice type (e.g., "zh_female_cancan")
    pub fn new(base_url: String, appid: String, access_token: String, voice_type: String) -> Self {
        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(300))
            .build()
            .expect("Failed to create HTTP client");

        Self {
            client,
            base_url,
            appid,
            access_token,
            voice_type,
        }
    }

    /// Submit a text synthesis task
    async fn submit_task(&self, text: &str) -> Result<String> {
        let url = format!("{}{}", self.base_url, SUBMIT_PATH);
        let reqid = Uuid::new_v4().to_string();

        let request = SubmitRequest {
            appid: self.appid.clone(),
            reqid,
            text: text.to_string(),
            voice_type: self.voice_type.clone(),
            format: "mp3".to_string(),
            speed_ratio: 1.0,
        };

        debug!("Submitting TTS task for {} characters", text.len());
        debug!("URL: {}, AppID: {}, VoiceType: {}", url, self.appid, self.voice_type);

        let response = self
            .client
            .post(&url)
            .header("Resource-Id", RESOURCE_ID)
            .header("Authorization", format!("Bearer; {}", self.access_token))
            .header("Content-Type", "application/json")
            .json(&request)
            .send()
            .await
            .context("Failed to submit TTS task")?;

        let status = response.status();
        if !status.is_success() {
            let error_text = response.text().await.unwrap_or_default();
            anyhow::bail!("Volcengine TTS submit error ({}): {}", status, error_text);
        }

        let resp: SubmitResponse = response
            .json()
            .await
            .context("Failed to parse submit response")?;

        if let Some(code) = resp.code {
            if code != 0 {
                anyhow::bail!(
                    "Volcengine TTS error: {} (code: {})",
                    resp.message.unwrap_or_default(),
                    code
                );
            }
        }

        resp.task_id.context("No task_id in response")
    }

    /// Query task status and get result
    async fn query_task(&self, task_id: &str) -> Result<QueryResponse> {
        let url = format!(
            "{}{}?appid={}&task_id={}",
            self.base_url, QUERY_PATH, self.appid, task_id
        );
        debug!("Query URL: {}", url);

        let response = self
            .client
            .get(&url)
            .header("Resource-Id", RESOURCE_ID)
            .header("Authorization", format!("Bearer; {}", self.access_token))
            .send()
            .await
            .context("Failed to query TTS task")?;

        let response_text = response.text().await.context("Failed to read query response")?;
        debug!("Query response: {}", response_text);

        let resp: QueryResponse = serde_json::from_str(&response_text)
            .context("Failed to parse query response")?;

        Ok(resp)
    }

    /// Download audio from URL
    async fn download_audio(&self, url: &str) -> Result<Vec<u8>> {
        let response = self
            .client
            .get(url)
            .send()
            .await
            .context("Failed to download audio")?;

        let bytes = response
            .bytes()
            .await
            .context("Failed to read audio bytes")?;

        Ok(bytes.to_vec())
    }

    /// Synthesize text to speech (async with polling)
    pub async fn synthesize(&self, text: &str) -> Result<TTSResult> {
        // Submit task
        let task_id = self.submit_task(text).await?;
        info!("TTS task submitted: {}", task_id);

        // Poll for result (max 10 minutes, check every 10 seconds)
        let max_attempts = 60;
        let poll_interval = std::time::Duration::from_secs(10);

        for attempt in 1..=max_attempts {
            tokio::time::sleep(poll_interval).await;

            let result = self.query_task(&task_id).await?;

            match result.task_status {
                Some(1) => {
                    // Success
                    let audio_url = result.audio_url.context("No audio_url in success response")?;
                    info!("TTS task completed, downloading audio");

                    let audio_data = self.download_audio(&audio_url).await?;
                    let text_length = result.text_length.unwrap_or(text.len() as i32);

                    // Estimate duration (rough: ~5 characters per second for Chinese)
                    let duration_seconds = (text_length as f32 / 5.0).ceil() as i32;

                    info!(
                        "Downloaded audio: {} bytes, ~{}s",
                        audio_data.len(),
                        duration_seconds
                    );

                    return Ok(TTSResult {
                        audio_data,
                        duration_seconds,
                    });
                }
                Some(2) => {
                    // Failed
                    anyhow::bail!(
                        "TTS task failed: {}",
                        result.message.unwrap_or_else(|| "Unknown error".to_string())
                    );
                }
                Some(0) | None => {
                    // Still processing
                    debug!("TTS task still processing (attempt {}/{})", attempt, max_attempts);
                }
                Some(status) => {
                    warn!("Unknown task status: {}", status);
                }
            }
        }

        anyhow::bail!("TTS task timed out after {} attempts", max_attempts)
    }

    /// Synthesize long text (converts markdown to plain text first)
    pub async fn synthesize_long_text(&self, text: &str) -> Result<TTSResult> {
        // Convert markdown to plain text for TTS
        let plain_text = markdown_to_plain_text(text);

        info!("Synthesizing {} characters of text", plain_text.len());

        self.synthesize(&plain_text).await
    }
}

