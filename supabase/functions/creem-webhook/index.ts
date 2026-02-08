/**
 * Supabase Edge Function: creem-webhook
 *
 * Handles Creem webhook events with signature verification.
 * Updates user_subscriptions table based on subscription lifecycle events.
 *
 * Events handled:
 *   - checkout.completed -> create/activate subscription record
 *   - subscription.active / subscription.paid / subscription.trialing -> grant access
 *   - subscription.canceled / subscription.expired -> revoke access
 *   - subscription.paused -> pause access
 *   - refund.created -> revoke access
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { verifyWebhookSignature } from "../_shared/creem.ts";
import { createServiceClient } from "../_shared/supabase.ts";

serve(async (req: Request) => {
  // Only accept POST
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    // 1. Get signature and raw body
    const signature = req.headers.get("creem-signature");
    if (!signature) {
      console.error("Missing creem-signature header");
      return new Response(
        JSON.stringify({ error: "Missing signature" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }

    const rawBody = await req.text();

    // 2. Verify signature
    const isValid = await verifyWebhookSignature(rawBody, signature);
    if (!isValid) {
      console.error("Invalid webhook signature");
      return new Response(
        JSON.stringify({ error: "Invalid signature" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }

    // 3. Parse event
    const event = JSON.parse(rawBody);
    const eventType = event.eventType as string;
    const eventObject = event.object;

    console.log(`Processing webhook event: ${eventType} (${event.id})`);

    // 4. Handle event
    const supabase = createServiceClient();

    switch (eventType) {
      case "checkout.completed":
        await handleCheckoutCompleted(supabase, eventObject);
        break;

      case "subscription.active":
      case "subscription.paid":
        await handleSubscriptionActive(supabase, eventObject);
        break;

      case "subscription.trialing":
        await handleSubscriptionTrialing(supabase, eventObject);
        break;

      case "subscription.canceled":
        await handleSubscriptionCanceled(supabase, eventObject);
        break;

      case "subscription.expired":
        await handleSubscriptionExpired(supabase, eventObject);
        break;

      case "subscription.paused":
        await handleSubscriptionPaused(supabase, eventObject);
        break;

      case "refund.created":
        await handleRefundCreated(supabase, eventObject);
        break;

      default:
        console.log(`Unhandled event type: ${eventType}`);
    }

    return new Response(
      JSON.stringify({ received: true }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("Webhook processing error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

// ─── Event Handlers ───────────────────────────────────────────

/**
 * Extract userId from event metadata.
 * The userId is passed as metadata.userId when creating the checkout.
 */
function getUserIdFromEvent(eventObject: Record<string, unknown>): string | null {
  // Try metadata directly on the object
  const metadata = eventObject.metadata as Record<string, unknown> | undefined;
  if (metadata?.userId) {
    return metadata.userId as string;
  }

  // Try nested subscription metadata
  const subscription = eventObject.subscription as Record<string, unknown> | undefined;
  if (subscription?.metadata) {
    const subMetadata = subscription.metadata as Record<string, unknown>;
    if (subMetadata.userId) return subMetadata.userId as string;
  }

  return null;
}

/** Get subscription and customer IDs from event */
function getSubscriptionInfo(eventObject: Record<string, unknown>): {
  subscriptionId: string | null;
  customerId: string | null;
  productId: string | null;
  periodEnd: string | null;
} {
  // For checkout.completed, subscription is nested
  const subscription = (eventObject.subscription || eventObject) as Record<string, unknown>;
  const customer = eventObject.customer as Record<string, unknown> | undefined;
  const product = eventObject.product as Record<string, unknown> | undefined;

  return {
    subscriptionId: (subscription?.id || eventObject.id) as string | null,
    customerId: (customer?.id ||
      (typeof eventObject.customer === "string" ? eventObject.customer : null)) as string | null,
    productId: (product?.id ||
      (typeof eventObject.product === "string" ? eventObject.product : null)) as string | null,
    periodEnd: (subscription?.current_period_end_date ||
      eventObject.current_period_end_date) as string | null,
  };
}

/** Upsert subscription record */
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

// deno-lint-ignore no-explicit-any
async function handleCheckoutCompleted(supabase: any, eventObject: Record<string, unknown>) {
  const userId = getUserIdFromEvent(eventObject);
  if (!userId) {
    console.error("No userId in checkout.completed metadata:", JSON.stringify(eventObject.metadata));
    return;
  }

  const { subscriptionId, customerId, productId, periodEnd } =
    getSubscriptionInfo(eventObject);

  await upsertSubscription(supabase, userId, {
    creem_customer_id: customerId,
    creem_subscription_id: subscriptionId,
    product_id: productId,
    status: "active",
    current_period_end: periodEnd ? new Date(periodEnd).toISOString() : null,
    canceled_at: null,
  });
}

// deno-lint-ignore no-explicit-any
async function handleSubscriptionActive(supabase: any, eventObject: Record<string, unknown>) {
  const userId = getUserIdFromEvent(eventObject);
  if (!userId) {
    // Try to find by creem_subscription_id
    const subId = eventObject.id as string;
    await updateBySubscriptionId(supabase, subId, {
      status: "active",
      current_period_end: eventObject.current_period_end_date
        ? new Date(eventObject.current_period_end_date as string).toISOString()
        : null,
      canceled_at: null,
    });
    return;
  }

  const { periodEnd } = getSubscriptionInfo(eventObject);
  await upsertSubscription(supabase, userId, {
    status: "active",
    current_period_end: periodEnd ? new Date(periodEnd).toISOString() : null,
    canceled_at: null,
  });
}

// deno-lint-ignore no-explicit-any
async function handleSubscriptionTrialing(supabase: any, eventObject: Record<string, unknown>) {
  const userId = getUserIdFromEvent(eventObject);
  if (!userId) {
    const subId = eventObject.id as string;
    await updateBySubscriptionId(supabase, subId, { status: "trialing" });
    return;
  }

  const { periodEnd } = getSubscriptionInfo(eventObject);
  await upsertSubscription(supabase, userId, {
    status: "trialing",
    current_period_end: periodEnd ? new Date(periodEnd).toISOString() : null,
  });
}

// deno-lint-ignore no-explicit-any
async function handleSubscriptionCanceled(supabase: any, eventObject: Record<string, unknown>) {
  const userId = getUserIdFromEvent(eventObject);
  const canceledAt = eventObject.canceled_at as string | null;
  const periodEnd = eventObject.current_period_end_date as string | null;

  const updateData: Record<string, unknown> = {
    status: "canceled",
    canceled_at: canceledAt ? new Date(canceledAt).toISOString() : new Date().toISOString(),
    current_period_end: periodEnd ? new Date(periodEnd).toISOString() : null,
  };

  if (!userId) {
    const subId = eventObject.id as string;
    await updateBySubscriptionId(supabase, subId, updateData);
    return;
  }

  await upsertSubscription(supabase, userId, updateData);
}

// deno-lint-ignore no-explicit-any
async function handleSubscriptionExpired(supabase: any, eventObject: Record<string, unknown>) {
  const userId = getUserIdFromEvent(eventObject);
  const updateData = { status: "expired" };

  if (!userId) {
    const subId = eventObject.id as string;
    await updateBySubscriptionId(supabase, subId, updateData);
    return;
  }

  await upsertSubscription(supabase, userId, updateData);
}

// deno-lint-ignore no-explicit-any
async function handleSubscriptionPaused(supabase: any, eventObject: Record<string, unknown>) {
  const userId = getUserIdFromEvent(eventObject);
  const updateData = { status: "paused" };

  if (!userId) {
    const subId = eventObject.id as string;
    await updateBySubscriptionId(supabase, subId, updateData);
    return;
  }

  await upsertSubscription(supabase, userId, updateData);
}

// deno-lint-ignore no-explicit-any
async function handleRefundCreated(supabase: any, eventObject: Record<string, unknown>) {
  // Find the subscription from the refund event
  const subscription = eventObject.subscription as Record<string, unknown> | undefined;
  if (!subscription) {
    console.log("No subscription in refund event, skipping");
    return;
  }

  const subId = subscription.id as string;
  await updateBySubscriptionId(supabase, subId, {
    status: "expired",
  });
}

/** Fallback: update subscription by creem_subscription_id when userId is not in metadata */
// deno-lint-ignore no-explicit-any
async function updateBySubscriptionId(supabase: any, subscriptionId: string, data: Record<string, unknown>) {
  const { error } = await supabase
    .from("user_subscriptions")
    .update({
      ...data,
      updated_at: new Date().toISOString(),
    })
    .eq("creem_subscription_id", subscriptionId);

  if (error) {
    console.error(`Failed to update subscription ${subscriptionId}:`, error);
    throw error;
  }

  console.log(`Subscription ${subscriptionId} updated:`, JSON.stringify(data));
}
