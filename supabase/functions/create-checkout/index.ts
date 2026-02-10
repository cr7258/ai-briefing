/**
 * Supabase Edge Function: create-checkout
 *
 * Creates a Creem checkout session for the authenticated user.
 * Returns a checkout URL to redirect the user to Creem's hosted payment page.
 *
 * Request: POST with JSON body (optional fields)
 *   - success_url: override default success redirect
 *   - discount_code: pre-apply a discount
 *
 * Response: { checkout_url: string }
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { getCreemBaseUrl, getCreemHeaders } from "../_shared/creem.ts";
import { getUser } from "../_shared/supabase.ts";

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

    // 2. Parse optional request body
    let body: Record<string, unknown> = {};
    try {
      body = await req.json();
    } catch {
      // Empty body is fine - all fields are optional
    }

    // 3. Build checkout request
    const productId = Deno.env.get("CREEM_PRODUCT_ID");
    if (!productId) {
      throw new Error("CREEM_PRODUCT_ID environment variable is not set");
    }

    const defaultSuccessUrl = body.success_url as string ||
      "https://app.ai-briefing.cc/?subscription=success";

    const checkoutPayload: Record<string, unknown> = {
      product_id: productId,
      success_url: defaultSuccessUrl,
      customer: {
        email: user.email,
      },
      metadata: {
        userId: user.id,
        source: "flutter_app",
      },
    };

    if (body.discount_code) {
      checkoutPayload.discount_code = body.discount_code;
    }

    // 4. Call Creem API
    const baseUrl = getCreemBaseUrl();
    const response = await fetch(`${baseUrl}/v1/checkouts`, {
      method: "POST",
      headers: getCreemHeaders(),
      body: JSON.stringify(checkoutPayload),
    });

    const checkout = await response.json();

    if (!response.ok) {
      console.error("Creem checkout error:", JSON.stringify(checkout));
      return new Response(
        JSON.stringify({
          error: "Failed to create checkout session",
          details: checkout,
        }),
        {
          status: response.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 5. Return checkout URL
    return new Response(
      JSON.stringify({
        checkout_url: checkout.checkout_url,
        checkout_id: checkout.id,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("create-checkout error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
