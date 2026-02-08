/**
 * Supabase Edge Function: customer-portal
 *
 * Generates a Creem customer portal link for the authenticated user.
 * The portal allows customers to manage their subscription and billing.
 *
 * Request: POST (no body required)
 * Response: { portal_url: string }
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { getCreemBaseUrl, getCreemHeaders } from "../_shared/creem.ts";
import { createUserClient, getUser } from "../_shared/supabase.ts";

serve(async (req: Request) => {
  // Handle CORS preflight
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    // 1. Authenticate user
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const user = await getUser(authHeader);

    // 2. Get user's creem_customer_id from database
    const supabase = createUserClient(authHeader);
    const { data: subscription, error: dbError } = await supabase
      .from("user_subscriptions")
      .select("creem_customer_id")
      .eq("user_id", user.id)
      .maybeSingle();

    if (dbError) {
      console.error("Database error:", dbError);
      throw new Error("Failed to fetch subscription data");
    }

    if (!subscription?.creem_customer_id) {
      return new Response(
        JSON.stringify({ error: "No active subscription found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 3. Call Creem API to generate portal link
    const baseUrl = getCreemBaseUrl();
    const response = await fetch(`${baseUrl}/v1/customers/billing`, {
      method: "POST",
      headers: getCreemHeaders(),
      body: JSON.stringify({
        customer_id: subscription.creem_customer_id,
      }),
    });

    const portal = await response.json();

    if (!response.ok) {
      console.error("Creem portal error:", JSON.stringify(portal));
      return new Response(
        JSON.stringify({
          error: "Failed to generate portal link",
          details: portal,
        }),
        {
          status: response.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 4. Return portal URL
    return new Response(
      JSON.stringify({
        portal_url: portal.customer_portal_link,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("customer-portal error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
