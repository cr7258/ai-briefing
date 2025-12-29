use anyhow::{Context, Result};
use tracing::{debug, info};

/// Supabase Storage client for uploading audio files
pub struct SupabaseStorage {
    client: reqwest::Client,
    supabase_url: String,
    secret_key: String,
    bucket_name: String,
}

impl SupabaseStorage {
    /// Create a new Supabase Storage client
    pub fn new(supabase_url: String, secret_key: String) -> Self {
        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(120))
            .build()
            .expect("Failed to create HTTP client");

        Self {
            client,
            supabase_url,
            secret_key,
            bucket_name: "briefing-audio".to_string(),
        }
    }

    /// Upload audio file to Supabase Storage
    /// Returns the public URL of the uploaded file
    pub async fn upload_audio(&self, filename: &str, audio_data: Vec<u8>) -> Result<String> {
        let url = format!(
            "{}/storage/v1/object/{}/{}",
            self.supabase_url, self.bucket_name, filename
        );

        debug!("Uploading audio to: {}", url);

        let response = self
            .client
            .post(&url)
            .header("Authorization", format!("Bearer {}", self.secret_key))
            .header("Content-Type", "audio/mpeg")
            .header("x-upsert", "true") // Overwrite if exists
            .body(audio_data)
            .send()
            .await
            .context("Failed to upload audio to Supabase")?;

        let status = response.status();
        if !status.is_success() {
            let error_text = response.text().await.unwrap_or_default();
            anyhow::bail!("Supabase Storage error ({}): {}", status, error_text);
        }

        // Construct public URL
        let public_url = format!(
            "{}/storage/v1/object/public/{}/{}",
            self.supabase_url, self.bucket_name, filename
        );

        info!("Uploaded audio: {}", public_url);

        Ok(public_url)
    }

    /// Ensure the storage bucket exists
    pub async fn ensure_bucket_exists(&self) -> Result<()> {
        let url = format!("{}/storage/v1/bucket", self.supabase_url);

        // Try to get bucket info
        let response = self
            .client
            .get(&format!("{}/{}", url, self.bucket_name))
            .header("Authorization", format!("Bearer {}", self.secret_key))
            .send()
            .await?;

        if response.status().is_success() {
            debug!("Bucket '{}' already exists", self.bucket_name);
            return Ok(());
        }

        // Create bucket if it doesn't exist
        info!("Creating storage bucket: {}", self.bucket_name);

        let body = serde_json::json!({
            "id": self.bucket_name,
            "name": self.bucket_name,
            "public": true,
            "file_size_limit": 52428800  // 50MB
        });

        let response = self
            .client
            .post(&url)
            .header("Authorization", format!("Bearer {}", self.secret_key))
            .header("Content-Type", "application/json")
            .json(&body)
            .send()
            .await?;

        if !response.status().is_success() {
            let error_text = response.text().await.unwrap_or_default();
            // Ignore "already exists" error
            if !error_text.contains("already exists") {
                anyhow::bail!("Failed to create bucket: {}", error_text);
            }
        }

        Ok(())
    }
}

