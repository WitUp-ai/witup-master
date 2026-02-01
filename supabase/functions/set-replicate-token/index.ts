// ============================================================================
// Edge Function: Set Replicate Token
// Description: Sets the Replicate API token from request
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

Deno.serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Get token from request body
    const { token } = await req.json();

    if (!token || !token.startsWith("r8_")) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Invalid token format. Must start with 'r8_'",
        }),
        { headers: { "Content-Type": "application/json" }, status: 400 }
      );
    }

    // Update the token in system_config
    const { data, error } = await supabase
      .from("system_config")
      .update({ value: token, updated_at: new Date().toISOString() })
      .eq("key", "REPLICATE_API_TOKEN")
      .select();

    if (error) {
      throw error;
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Replicate API token updated successfully",
        updated: data?.length || 0,
      }),
      { headers: { "Content-Type": "application/json" }, status: 200 }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "Unknown error",
      }),
      { headers: { "Content-Type": "application/json" }, status: 500 }
    );
  }
});
