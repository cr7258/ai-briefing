/**
 * Shared Creem API utilities for Supabase Edge Functions.
 */

/** Creem API base URL based on test mode */
export function getCreemBaseUrl(): string {
  const testMode = Deno.env.get("CREEM_TEST_MODE") === "true";
  return testMode
    ? "https://test-api.creem.io"
    : "https://api.creem.io";
}

/** Standard headers for Creem API calls */
export function getCreemHeaders(): Record<string, string> {
  const apiKey = Deno.env.get("CREEM_API_KEY");
  if (!apiKey) {
    throw new Error("CREEM_API_KEY environment variable is not set");
  }
  return {
    "x-api-key": apiKey,
    "Content-Type": "application/json",
  };
}

/** Verify Creem webhook signature using HMAC-SHA256 */
export async function verifyWebhookSignature(
  rawBody: string,
  signature: string,
): Promise<boolean> {
  const secret = Deno.env.get("CREEM_WEBHOOK_SECRET");
  if (!secret) {
    throw new Error("CREEM_WEBHOOK_SECRET environment variable is not set");
  }

  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signatureBytes = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(rawBody),
  );

  const computed = Array.from(new Uint8Array(signatureBytes))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  // Timing-safe comparison
  if (computed.length !== signature.length) return false;
  let result = 0;
  for (let i = 0; i < computed.length; i++) {
    result |= computed.charCodeAt(i) ^ signature.charCodeAt(i);
  }
  return result === 0;
}
