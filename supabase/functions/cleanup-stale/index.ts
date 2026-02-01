// Supabase Edge Function: Cleanup Stale Processing
// Marks drawings stuck in processing_3d for >10 minutes as failed
// Can be called manually or via cron (Supabase pg_cron or external scheduler)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const STALE_TIMEOUT_MINUTES = 10;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const cutoff = new Date(Date.now() - STALE_TIMEOUT_MINUTES * 60 * 1000).toISOString();

    // Find drawings stuck in processing or processing_3d for too long
    const { data: staleDrawings, error } = await supabase
      .from("drawings")
      .select("id, user_id, model_status, processing_started_at")
      .in("model_status", ["processing", "processing_3d"])
      .lt("processing_started_at", cutoff);

    if (error) {
      throw new Error(`Query error: ${error.message}`);
    }

    if (!staleDrawings || staleDrawings.length === 0) {
      return new Response(
        JSON.stringify({ success: true, cleaned: 0, message: "No stale drawings found" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`Found ${staleDrawings.length} stale drawings`);

    let cleaned = 0;
    for (const drawing of staleDrawings) {
      await supabase
        .from("drawings")
        .update({
          model_status: "failed",
          processing_error: `Processing timeout: stuck in ${drawing.model_status} for over ${STALE_TIMEOUT_MINUTES} minutes`,
          processing_step: "timeout",
        })
        .eq("id", drawing.id);

      // Notify user
      await supabase.from("notifications").insert({
        user_id: drawing.user_id,
        type: "processing_failed",
        title: "Elaborazione scaduta",
        message: "Il tuo disegno non è stato completato in tempo. Riprova!",
        action_url: `/home`,
        metadata: { drawing_id: drawing.id, reason: "timeout" },
      });

      cleaned++;
      console.log(`Cleaned drawing ${drawing.id} (was ${drawing.model_status})`);
    }

    return new Response(
      JSON.stringify({ success: true, cleaned, stale_ids: staleDrawings.map((d: { id: string }) => d.id) }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Cleanup error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
