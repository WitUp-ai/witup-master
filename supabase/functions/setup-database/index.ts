// ============================================================================
// Edge Function: Setup Database
// Description: Inserts default configurations into system_config table
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

    // Check if tables exist by trying to query them
    let tablesExist = { system_config: false, usage_logs: false };

    try {
      await supabase.from("system_config").select("key").limit(1);
      tablesExist.system_config = true;
    } catch (e) {
      console.log("system_config table doesn't exist yet");
    }

    try {
      await supabase.from("usage_logs").select("id").limit(1);
      tablesExist.usage_logs = true;
    } catch (e) {
      console.log("usage_logs table doesn't exist yet");
    }

    if (!tablesExist.system_config) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "system_config table doesn't exist. Run migration 20260131200000_admin_saas_foundation.sql first",
          tables_exist: tablesExist,
        }),
        { headers: { "Content-Type": "application/json" }, status: 400 }
      );
    }

    // Insert default configurations
    const defaultConfigs = [
      {
        key: "REPLICATE_API_TOKEN",
        value: "",
        description: "Token API principale Replicate - INSERISCI IL TUO TOKEN",
        is_secret: true,
      },
      {
        key: "STYLE_PROMPT_CUPPY",
        value:
          "A cute 3D toy character, claymation style, made of plasticine, play-doh texture, cute, puffy, volumetric, soft studio lighting, octane render, high quality, isometric view, smooth vinyl toy, tactile feeling, clean white background",
        description: "Prompt per stilizzazione Cuppy",
        is_secret: false,
      },
      {
        key: "MONTHLY_SPEND_LIMIT",
        value: "10.0",
        description: "Limite budget mensile USD",
        is_secret: false,
      },
      {
        key: "COST_VISION_VALIDATION",
        value: "0.002",
        description: "Costo stimato per validazione vision (USD)",
        is_secret: false,
      },
      {
        key: "COST_BACKGROUND_REMOVAL",
        value: "0.005",
        description: "Costo stimato per rimozione sfondo (USD)",
        is_secret: false,
      },
      {
        key: "COST_STYLIZATION",
        value: "0.02",
        description: "Costo stimato per stilizzazione SDXL (USD)",
        is_secret: false,
      },
      {
        key: "COST_3D_GENERATION",
        value: "0.05",
        description: "Costo stimato per generazione 3D (USD)",
        is_secret: false,
      },
    ];

    const results = [];
    for (const config of defaultConfigs) {
      const { data, error } = await supabase.from("system_config").upsert(config, {
        onConflict: "key",
        ignoreDuplicates: true,
      });
      results.push({
        key: config.key,
        success: !error,
        error: error?.message,
      });
    }

    // Check current state
    const { data: configs, count: configCount } = await supabase
      .from("system_config")
      .select("*", { count: "exact" });

    const { count: logsCount } = await supabase
      .from("usage_logs")
      .select("*", { count: "exact", head: true });

    return new Response(
      JSON.stringify({
        success: true,
        message: "Database setup completed",
        tables_exist: tablesExist,
        config_insertion_results: results,
        verification: {
          system_config_rows: configCount,
          usage_logs_rows: logsCount,
        },
        current_configs: configs?.map((c) => ({
          key: c.key,
          value: c.is_secret ? "***" : c.value,
          description: c.description,
        })),
      }),
      {
        headers: { "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("Setup error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "Unknown error",
        stack: error.stack,
      }),
      {
        headers: { "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});
