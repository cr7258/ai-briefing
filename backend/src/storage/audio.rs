use anyhow::{Context, Result};
use async_trait::async_trait;
use futures_core::future::BoxFuture;
use std::future::Future;
use std::time::Duration;
use tokio::runtime::Handle;
use tracing::info;
use ve_tos_rust_sdk::asynchronous::object::ObjectAPI;
use ve_tos_rust_sdk::asynchronous::tos;
use ve_tos_rust_sdk::asynchronous::tos::AsyncRuntime;
use ve_tos_rust_sdk::object::PutObjectFromBufferInput;

/// Tokio runtime adapter for TOS SDK
#[derive(Debug, Default, Clone)]
pub struct TokioRuntime {}

#[async_trait]
impl AsyncRuntime for TokioRuntime {
    type JoinError = tokio::task::JoinError;

    async fn sleep(&self, duration: Duration) {
        tokio::time::sleep(duration).await;
    }

    fn spawn<'a, F>(&self, future: F) -> BoxFuture<'a, Result<F::Output, Self::JoinError>>
    where
        F: Future + Send + 'static,
        F::Output: Send + 'static,
    {
        Box::pin(Handle::current().spawn(future))
    }

    fn block_on<F: Future>(&self, future: F) -> F::Output {
        Handle::current().block_on(future)
    }
}

/// Volcengine TOS storage configuration
pub struct AudioStorage {
    access_key: String,
    secret_key: String,
    endpoint: String,
    region: String,
    bucket_name: String,
}

impl AudioStorage {
    /// Create a new Volcengine TOS client configuration
    ///
    /// # Arguments
    /// * `access_key` - Volcengine Access Key ID
    /// * `secret_key` - Volcengine Secret Access Key
    /// * `endpoint` - TOS endpoint (e.g., "https://tos-cn-shanghai.volces.com")
    /// * `region` - Region (e.g., "cn-shanghai")
    /// * `bucket_name` - Bucket name for storing audio files
    pub async fn new(
        access_key: String,
        secret_key: String,
        endpoint: String,
        region: String,
        bucket_name: String,
    ) -> Result<Self> {
        Ok(Self {
            access_key,
            secret_key,
            endpoint,
            region,
            bucket_name,
        })
    }

    /// Upload audio file to Volcengine TOS
    /// Returns the public URL of the uploaded file
    pub async fn upload(&self, filename: &str, audio_data: Vec<u8>) -> Result<String> {
        // Create TOS client for this upload
        let client = tos::builder::<TokioRuntime>()
            .connection_timeout(10000)
            .request_timeout(300000) // 5 minutes for large audio files
            .max_connections(10)
            .max_retry_count(3)
            .ak(&self.access_key)
            .sk(&self.secret_key)
            .region(&self.region)
            .endpoint(&self.endpoint)
            .build()
            .context("Failed to create TOS client")?;

        let mut input = PutObjectFromBufferInput::new(&self.bucket_name, filename);
        input.set_content(audio_data);

        client
            .put_object_from_buffer(&input)
            .await
            .map_err(|e| anyhow::anyhow!("Failed to upload audio to TOS: {:?}", e))?;

        // Construct public URL
        // Format: https://{bucket}.{endpoint-without-https}/{key}
        let endpoint_host = self.endpoint.trim_start_matches("https://");
        let public_url = format!("https://{}.{}/{}", self.bucket_name, endpoint_host, filename);

        info!("Uploaded audio: {}", public_url);

        Ok(public_url)
    }
}
