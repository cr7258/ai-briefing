/**
 * Supabase Edge Function: revenuecat-webhook
 *
 * Handles RevenueCat webhook events for Apple IAP subscriptions.
 * Updates user_subscriptions table based on subscription lifecycle events.
 *
 * RevenueCat event types handled:
 *   - INITIAL_PURCHASE / RENEWAL / UNCANCELLATION -> grant access
 *   - CANCELLATION -> keep access until period end
 *   - EXPIRATION / BILLING_ISSUE -> revoke access
 *   - SUBSCRIBER_ALIAS -> ignored
 *
 * Auth: RevenueCat sends an Authorization header with a shared secret.
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createServiceClient } from "../_shared/supabase.ts";

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    // 1. Verify authorization
    const authHeader = req.headers.get("authorization");
    const expectedKey = Deno.env.get("REVENUECAT_WEBHOOK_AUTH_KEY");

    if (!expectedKey || authHeader !== `Bearer ${expectedKey}`) {
      console.error("Invalid or missing authorization header");
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }

    // 2. Parse webhook body
    const body = await req.json();
    const event = body.event;

    if (!event) {
      console.error("No event in webhook body");
      return new Response(
        JSON.stringify({ error: "No event found" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const eventType = event.type as string;
    const appUserId = event.app_user_id as string;

    console.log(`Processing RevenueCat event: ${eventType} for user ${appUserId}`);

    if (!appUserId) {
      console.error("No app_user_id in event");
      return new Response(
        JSON.stringify({ error: "Missing app_user_id" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    // 3. Handle event
    const supabase = createServiceClient();

    const hasPremium = (event.entitlement_ids as string[] | undefined)?.includes("AI Briefing Pro") ?? false;
    const expirationDate = event.expiration_at_ms
      ? new Date(event.expiration_at_ms as number).toISOString()
      : null;
    const originalTransactionId = event.original_transaction_id as string | undefined;

    switch (eventType) {
      case "INITIAL_PURCHASE":
      case "RENEWAL":
      case "UNCANCELLATION":
      case "NON_RENEWING_PURCHASE":
        await upsertSubscription(supabase, appUserId, {
          status: "active",
          subscription_source: "apple",
          revenuecat_customer_id: appUserId,
          apple_original_transaction_id: originalTransactionId ?? null,
          current_period_end: expirationDate,
          canceled_at: null,
        });
        break;

      case "CANCELLATION":
        await upsertSubscription(supabase, appUserId, {
          status: "canceled",
          subscription_source: "apple",
          current_period_end: expirationDate,
          canceled_at: new Date().toISOString(),
        });
        break;

      case "EXPIRATION":
        await upsertSubscription(supabase, appUserId, {
          status: "expired",
          subscription_source: "apple",
        });
        break;

      case "BILLING_ISSUE":
        console.log(`Billing issue for user ${appUserId}, keeping current status`);
        break;

      case "PRODUCT_CHANGE":
        if (hasPremium) {
          await upsertSubscription(supabase, appUserId, {
            status: "active",
            subscription_source: "apple",
            current_period_end: expirationDate,
          });
        }
        break;

      case "SUBSCRIBER_ALIAS":
      case "TRANSFER":
        console.log(`Ignoring event type: ${eventType}`);
        break;

      default:
        console.log(`Unhandled RevenueCat event type: ${eventType}`);
    }

    return new Response(
      JSON.stringify({ received: true }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("RevenueCat webhook processing error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

// ─── Helpers ───────────────────────────────────────────────

// deno-lint-ignore no-explicit-any
async function upsertSubscription(supabase: any, userId: string, data: Record<string, unknown>) {
  const { error } = await supabase
    .from("user_subscriptions")
    .upsert(
      {
        user_id: userId,
        ...data,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id" },
    );

  if (error) {
    console.error("Failed to upsert subscription:", error);
    throw error;
  }

  console.log(`Subscription updated for user ${userId}:`, JSON.stringify(data));
}
