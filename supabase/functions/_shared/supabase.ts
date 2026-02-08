/**
 * Shared Supabase client utilities for Edge Functions.
 */
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/** Create a Supabase client with service role (bypasses RLS) */
export function createServiceClient() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error(
      "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required",
    );
  }

  return createClient(supabaseUrl, serviceRoleKey);
}

/** Create a Supabase client with the user's JWT (respects RLS) */
export function createUserClient(authHeader: string) {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");

  if (!supabaseUrl || !anonKey) {
    throw new Error("SUPABASE_URL and SUPABASE_ANON_KEY are required");
  }

  return createClient(supabaseUrl, anonKey, {
    global: {
      headers: { Authorization: authHeader },
    },
  });
}

/** Extract user from JWT auth header */
export async function getUser(authHeader: string) {
  const client = createUserClient(authHeader);
  const {
    data: { user },
    error,
  } = await client.auth.getUser();

  if (error || !user) {
    throw new Error("Unauthorized: invalid or expired token");
  }

  return user;
}
