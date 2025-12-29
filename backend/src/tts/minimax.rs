use anyhow::{Context, Result};
use pulldown_cmark::{Event, Parser, Tag, TagEnd};
use serde::{Deserialize, Serialize};
use tracing::{debug, info};

/// MiniMax TTS client
pub struct MiniMaxTTS {
    client: reqwest::Client,
    api_key: String,
    model: String,
    voice_id: String,
}

#[derive(Debug, Serialize)]
struct TTSRequest {
    model: String,
    text: String,
    voice_setting: VoiceSetting,
    audio_setting: AudioSetting,
}

#[derive(Debug, Serialize)]
struct VoiceSetting {
    voice_id: String,
    speed: f32,
    vol: f32,
    pitch: i32,
}

#[derive(Debug, Serialize)]
struct AudioSetting {
    sample_rate: u32,
    bitrate: u32,
    format: String,
}

#[derive(Debug, Deserialize)]
struct TTSResponse {
    data: Option<TTSData>,
    base_resp: Option<BaseResponse>,
}

#[derive(Debug, Deserialize)]
struct TTSData {
    audio: String, // Base64 encoded audio
}

#[derive(Debug, Deserialize)]
struct BaseResponse {
    status_code: i32,
    status_msg: String,
}

/// TTS synthesis result
pub struct TTSResult {
    pub audio_data: Vec<u8>,
    pub duration_seconds: i32,
}

impl MiniMaxTTS {
    /// Create a new MiniMax TTS client
    pub fn new(api_key: String, model: String, voice_id: String) -> Self {
        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(300))
            .build()
            .expect("Failed to create HTTP client");

        Self {
            client,
            api_key,
            model,
            voice_id,
        }
    }

    /// Synthesize text to speech
    pub async fn synthesize(&self, text: &str) -> Result<TTSResult> {
        let url = "https://api.minimax.io/v1/t2a_v2";

        let request = TTSRequest {
            model: self.model.clone(),
            text: text.to_string(),
            voice_setting: VoiceSetting {
                voice_id: self.voice_id.clone(),
                speed: 1.0,
                vol: 1.0,
                pitch: 0,
            },
            audio_setting: AudioSetting {
                sample_rate: 32000,
                bitrate: 128000,
                format: "mp3".to_string(),
            },
        };

        debug!("Sending TTS request for {} characters", text.len());

        let response = self
            .client
            .post(url)
            .header("Authorization", format!("Bearer {}", self.api_key))
            .header("Content-Type", "application/json")
            .json(&request)
            .send()
            .await
            .context("Failed to send TTS request")?;

        let status = response.status();
        if !status.is_success() {
            let error_text = response.text().await.unwrap_or_default();
            anyhow::bail!("MiniMax TTS API error ({}): {}", status, error_text);
        }

        let tts_response: TTSResponse = response
            .json()
            .await
            .context("Failed to parse TTS response")?;

        // Check for API errors
        if let Some(base_resp) = &tts_response.base_resp {
            if base_resp.status_code != 0 {
                anyhow::bail!("MiniMax TTS error: {}", base_resp.status_msg);
            }
        }

        let audio_base64 = tts_response
            .data
            .map(|d| d.audio)
            .context("No audio data in response")?;

        // Decode base64 audio
        use base64::Engine;
        let audio_data = base64::engine::general_purpose::STANDARD
            .decode(&audio_base64)
            .context("Failed to decode base64 audio")?;

        // Estimate duration (rough: ~10 characters per second for Chinese)
        let duration_seconds = (text.chars().count() as f32 / 10.0).ceil() as i32;

        info!(
            "Generated audio: {} bytes, ~{}s",
            audio_data.len(),
            duration_seconds
        );

        Ok(TTSResult {
            audio_data,
            duration_seconds,
        })
    }

    /// Synthesize long text by splitting into chunks
    pub async fn synthesize_long_text(&self, text: &str) -> Result<TTSResult> {
        const MAX_CHARS: usize = 5000;

        // Convert markdown to plain text for TTS
        let plain_text = markdown_to_plain_text(text);

        if plain_text.len() <= MAX_CHARS {
            return self.synthesize(&plain_text).await;
        }

        info!(
            "Splitting long text ({} chars) into chunks",
            plain_text.len()
        );

        // Split by paragraphs
        let chunks = split_text_into_chunks(&plain_text, MAX_CHARS);
        let mut all_audio: Vec<u8> = Vec::new();
        let mut total_duration = 0;

        for (i, chunk) in chunks.iter().enumerate() {
            debug!("Processing chunk {}/{}", i + 1, chunks.len());
            let result = self.synthesize(chunk).await?;
            all_audio.extend(result.audio_data);
            total_duration += result.duration_seconds;
        }

        Ok(TTSResult {
            audio_data: all_audio,
            duration_seconds: total_duration,
        })
    }
}

/// Convert markdown to plain text suitable for TTS
fn markdown_to_plain_text(markdown: &str) -> String {
    let parser = Parser::new(markdown);
    let mut text = String::new();
    let mut in_link = false;

    for event in parser {
        match event {
            Event::Text(t) => {
                if !in_link {
                    text.push_str(&t);
                }
            }
            Event::SoftBreak | Event::HardBreak => {
                text.push(' ');
            }
            Event::Start(Tag::Link { .. }) => {
                in_link = true;
            }
            Event::End(TagEnd::Link) => {
                in_link = false;
            }
            Event::Start(Tag::Paragraph) => {
                if !text.is_empty() {
                    text.push_str("\n\n");
                }
            }
            Event::Start(Tag::Heading { .. }) => {
                if !text.is_empty() {
                    text.push_str("\n\n");
                }
            }
            Event::End(TagEnd::Heading(_)) => {
                text.push_str("。\n");
            }
            Event::Start(Tag::Item) => {
                text.push_str("\n");
            }
            _ => {}
        }
    }

    // Clean up multiple spaces/newlines
    let mut result = String::new();
    let mut prev_char = ' ';
    for c in text.chars() {
        if c.is_whitespace() {
            if !prev_char.is_whitespace() {
                result.push(' ');
            }
        } else {
            result.push(c);
        }
        prev_char = c;
    }

    result.trim().to_string()
}

/// Split text into chunks at sentence boundaries
fn split_text_into_chunks(text: &str, max_chars: usize) -> Vec<String> {
    let mut chunks = Vec::new();
    let mut current_chunk = String::new();

    // Split by sentences (Chinese punctuation)
    let sentences: Vec<&str> = text
        .split_inclusive(|c| c == '。' || c == '！' || c == '？' || c == '\n')
        .collect();

    for sentence in sentences {
        if current_chunk.len() + sentence.len() > max_chars && !current_chunk.is_empty() {
            chunks.push(current_chunk.trim().to_string());
            current_chunk = String::new();
        }
        current_chunk.push_str(sentence);
    }

    if !current_chunk.is_empty() {
        chunks.push(current_chunk.trim().to_string());
    }

    chunks
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_markdown_to_plain_text() {
        let markdown = "## 今日要闻\n\n这是**重要**新闻。\n\n[阅读原文](https://example.com)";
        let plain = markdown_to_plain_text(markdown);
        assert!(plain.contains("今日要闻"));
        assert!(plain.contains("重要"));
        assert!(!plain.contains("https://"));
    }
}

