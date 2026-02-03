// Supabase Edge Function: Process Drawing
// Handles background removal and 3D model generation
// Supports: Replicate, Remove.bg, Rodin, CSM APIs

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";
import { encode as base64Encode } from "https://deno.land/std@0.168.0/encoding/base64.ts";

const FUNCTION_VERSION = "2026-02-03-v12-FINAL";

/** Log an AI operation to usage_logs for cost tracking */
async function logUsage(
  supabase: ReturnType<typeof createClient>,
  params: {
    drawing_id?: string;
    user_id?: string;
    provider: string;
    model?: string;
    operation: string;
    status: string;
    cost_estimated?: number;
    latency_ms?: number;
    error_message?: string;
    metadata?: Record<string, unknown>;
  }
) {
  try {
    await supabase.from("usage_logs").insert({
      drawing_id: params.drawing_id || null,
      user_id: params.user_id || null,
      provider: params.provider,
      model: params.model || null,
      operation: params.operation,
      status: params.status,
      cost_estimated: params.cost_estimated || null,
      latency_ms: params.latency_ms || null,
      error_message: params.error_message || null,
      metadata: params.metadata || null,
    });
  } catch (e) {
    console.error("Failed to log usage:", e);
  }
}

/** Load a cost config value from system_config */
async function getCostConfig(
  supabase: ReturnType<typeof createClient>,
  key: string,
  fallback: number
): Promise<number> {
  try {
    const { data } = await supabase
      .from("system_config")
      .select("value")
      .eq("key", key)
      .maybeSingle();
    return data ? parseFloat(data.value) || fallback : fallback;
  } catch {
    return fallback;
  }
}

// CORS Headers - Must be included in ALL responses
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

interface ProcessRequest {
  drawing_id: string;
  user_id: string;
  style?: string;
  quality?: string;
}

interface ProcessingResult {
  success: boolean;
  processed_image_url?: string;
  concept_url?: string;
  model_3d_url?: string;
  thumbnail_url?: string;
  processing_time_ms?: number;
  est_time_seconds?: number;
  error?: string;
}

class BillingError extends Error {
  constructor() {
    super("Credito Replicate esaurito. Ricarica su replicate.com/account/billing.");
    this.name = "BillingError";
  }
}

/** Create a Replicate prediction, throwing BillingError on 402 */
async function createReplicatePrediction(
  token: string,
  version: string,
  input: Record<string, unknown>,
  extra?: Record<string, unknown>
): Promise<Record<string, unknown>> {
  const response = await fetch("https://api.replicate.com/v1/predictions", {
    method: "POST",
    headers: {
      "Authorization": `Token ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ version, input, ...extra }),
  });

  if (response.status === 402) {
    throw new BillingError();
  }
  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Replicate API error: ${response.status} - ${errText}`);
  }
  return await response.json();
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const startTime = Date.now();

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // User-context client: uses anon key + user's JWT for RLS-respecting queries
    const supabaseUser = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: req.headers.get("Authorization")! } },
    });

    // Service-role client: bypasses RLS for storage and admin operations
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Load API keys: prefer Deno env, fallback to system_config table
    // IMPORTANT: trim empty strings to treat them as null for proper fallback
    const rawReplicateToken = Deno.env.get("REPLICATE_API_TOKEN");
    console.log(`[${FUNCTION_VERSION}] Raw REPLICATE_API_TOKEN from env:`, rawReplicateToken ? `EXISTS (${rawReplicateToken.substring(0, 12)}...)` : "DOES NOT EXIST");

    let replicateToken = rawReplicateToken?.trim() || null;
    let removeBgApiKey = Deno.env.get("REMOVE_BG_API_KEY")?.trim() || null;
    let rodinApiKey = Deno.env.get("RODIN_API_KEY")?.trim() || null;

    console.log(`[${FUNCTION_VERSION}] Initial API keys from env:`, {
      replicate: replicateToken ? `${replicateToken.substring(0, 8)}...` : "NULL",
      removebg: removeBgApiKey ? "SET" : "NULL",
      rodin: rodinApiKey ? "SET" : "NULL"
    });

    // Always check system_config as fallback (even if env vars are set but empty)
    if (!replicateToken || !removeBgApiKey || !rodinApiKey) {
      console.log("Checking system_config table for missing API keys...");
      console.log("Service key available:", supabaseServiceKey ? "YES" : "NO");
      console.log("Supabase client created:", supabase ? "YES" : "NO");

      const { data: configs, error: configError } = await supabase
        .from("system_config")
        .select("key, value")
        .in("key", ["REPLICATE_API_TOKEN", "REMOVE_BG_API_KEY", "RODIN_API_KEY"]);

      console.log("Query result - error:", configError);
      console.log("Query result - data:", configs);
      console.log("Query result - data length:", configs?.length);

      if (configError) {
        console.error("Failed to read system_config:", JSON.stringify(configError));
      } else if (configs && configs.length > 0) {
        console.log(`Found ${configs.length} config entries in system_config`);
        for (const cfg of configs) {
          console.log(`Processing config: key=${cfg.key}, value=${cfg.value ? 'HAS_VALUE' : 'NO_VALUE'}`);
          if (cfg.key === "REPLICATE_API_TOKEN" && !replicateToken) {
            replicateToken = cfg.value?.trim() || null;
            console.log(`✅ Loaded REPLICATE_API_TOKEN from system_config: ${replicateToken?.substring(0, 8)}...`);
          }
          if (cfg.key === "REMOVE_BG_API_KEY" && !removeBgApiKey) {
            removeBgApiKey = cfg.value?.trim() || null;
            console.log(`✅ Loaded REMOVE_BG_API_KEY from system_config`);
          }
          if (cfg.key === "RODIN_API_KEY" && !rodinApiKey) {
            rodinApiKey = cfg.value?.trim() || null;
            console.log(`✅ Loaded RODIN_API_KEY from system_config`);
          }
        }
      } else {
        console.error("❌ system_config query returned no data or empty array");
      }
    }

    if (!replicateToken) {
      console.error("REPLICATE_API_TOKEN not found in env or system_config!");
      return new Response(
        JSON.stringify({ success: false, error: "api_config_missing", error_message: "REPLICATE_API_TOKEN not configured. Add it to system_config table or Edge Function secrets." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`[${FUNCTION_VERSION}] Final API keys status:`, {
      replicate: replicateToken ? `${replicateToken.substring(0, 8)}...` : "MISSING",
      removebg: removeBgApiKey ? "SET" : "MISSING (will skip)",
      rodin: rodinApiKey ? "SET" : "MISSING (will skip)"
    });

    // CRITICAL: Log if token is missing to help debug
    if (!replicateToken) {
      console.error(`[${FUNCTION_VERSION}] ❌ CRITICAL: Replicate token is NULL - processing will be skipped!`);
    } else {
      console.log(`[${FUNCTION_VERSION}] ✅ Replicate token loaded successfully`);
    }

    // Load cost estimates from system_config
    const costVision = await getCostConfig(supabase, "COST_VISION_VALIDATION", 0.002);
    const costBgRemoval = await getCostConfig(supabase, "COST_BACKGROUND_REMOVAL", 0.005);
    const costStylization = await getCostConfig(supabase, "COST_STYLIZATION", 0.02);
    const cost3D = await getCostConfig(supabase, "COST_3D_GENERATION", 0.05);

    // Quick credit check: try creating a prediction with a real model to verify billing
    if (replicateToken) {
      const testRes = await fetch("https://api.replicate.com/v1/predictions", {
        method: "POST",
        headers: {
          "Authorization": `Token ${replicateToken}`,
          "Content-Type": "application/json",
        },
        // Use rembg version with minimal dummy input — will fail on input validation but AFTER billing check
        body: JSON.stringify({
          version: "fb8af171cfa1616ddcf1242c093f9c46bcada5ad4cf6f2fbe8b81b330ec5c003",
          input: { image: "https://example.com/nonexistent.png" },
        }),
      });
      console.log(`Billing check response: ${testRes.status}`);
      if (testRes.status === 402) {
        console.error("BILLING CHECK FAILED: Replicate has no credit");
        return new Response(JSON.stringify({
          success: false,
          error: "billing_error",
          error_message: "Credito Replicate esaurito. Ricarica su replicate.com/account/billing.",
        }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      // Cancel the test prediction if it was created (201)
      if (testRes.status === 201) {
        try {
          const testPred = await testRes.json();
          if (testPred.id) {
            await fetch(`https://api.replicate.com/v1/predictions/${testPred.id}/cancel`, {
              method: "POST",
              headers: { "Authorization": `Token ${replicateToken}` },
            });
          }
        } catch { /* ignore */ }
      }
    }

    const { drawing_id, user_id, style = "cartoon", quality = "standard" }: ProcessRequest = await req.json();

    if (!drawing_id || !user_id) {
      return new Response(
        JSON.stringify({ error: "Missing drawing_id or user_id" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`Processing drawing: ${drawing_id} for user: ${user_id}`);

    // 1. Update status to processing
    await supabase
      .from("drawings")
      .update({
        model_status: "processing",
        processing_step: "uploading",
        processing_started_at: new Date().toISOString(),
      })
      .eq("id", drawing_id)
      .eq("user_id", user_id);

    // 2. Get drawing details
    const { data: drawing, error: fetchError } = await supabase
      .from("drawings")
      .select("*")
      .eq("id", drawing_id)
      .single();

    if (fetchError || !drawing) {
      throw new Error(`Drawing not found: ${fetchError?.message}`);
    }

    // 3. Download original image from storage
    const originalImagePath = drawing.original_image_url;
    const { data: imageData, error: downloadError } = await supabase.storage
      .from("drawings-original")
      .download(originalImagePath);

    if (downloadError || !imageData) {
      throw new Error(`Failed to download image: ${downloadError?.message}`);
    }

    const imageBytes = new Uint8Array(await imageData.arrayBuffer());
    let processedImageUrl: string | null = null;
    let model3dUrl: string | null = null;
    let thumbnailUrl: string | null = null;

    // =========================================
    // STEP 0: VISION VALIDATION (is this a drawing?)
    // =========================================
    await supabase.from("drawings").update({ processing_step: "validating" }).eq("id", drawing_id);

    if (replicateToken) {
      try {
        console.log("Validating drawing with vision model...");
        const validationResult = await validateDrawingWithVision(imageBytes, replicateToken);
        console.log("Vision validation result:", JSON.stringify(validationResult));

        await supabase.from("drawings").update({
          validation_status: validationResult.is_drawing ? "valid" : "invalid",
          validation_reason: validationResult.reason,
          validation_completed_at: new Date().toISOString(),
        }).eq("id", drawing_id);

        await logUsage(supabase, {
          drawing_id, user_id, provider: "replicate", model: "moondream2",
          operation: "vision_validation", status: "success",
          cost_estimated: costVision, latency_ms: Date.now() - startTime,
        });

        if (!validationResult.is_drawing) {
          await supabase.from("drawings").update({
            model_status: "failed",
            processing_error: `Not a drawing: ${validationResult.reason}`,
          }).eq("id", drawing_id);

          return new Response(JSON.stringify({
            success: false,
            error: "not_a_drawing",
            error_message: validationResult.reason || "The uploaded image does not appear to be a drawing.",
          }), {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }
        console.log("Drawing validation passed");
      } catch (e) {
        if (e instanceof BillingError) throw e;
        await logUsage(supabase, {
          drawing_id, user_id, provider: "replicate", model: "moondream2",
          operation: "vision_validation", status: "error",
          cost_estimated: 0, latency_ms: Date.now() - startTime,
          error_message: e instanceof Error ? e.message : String(e),
        });
        console.warn("Vision validation failed, proceeding anyway:", e);
      }
    }

    // =========================================
    // STEP 1: BACKGROUND REMOVAL
    // =========================================
    await supabase.from("drawings").update({ processing_step: "removing_background" }).eq("id", drawing_id);

    let processedImageBytes: Uint8Array | null = null;

    // Try Replicate first (rembg model)
    if (replicateToken) {
      try {
        console.log("Attempting background removal with Replicate...");
        const bgStart = Date.now();
        processedImageBytes = await removeBackgroundReplicate(imageBytes, replicateToken);
        console.log("Replicate background removal succeeded");
        await logUsage(supabase, {
          drawing_id, user_id, provider: "replicate", model: "rembg",
          operation: "background_removal", status: "success",
          cost_estimated: costBgRemoval, latency_ms: Date.now() - bgStart,
        });
      } catch (e: unknown) {
        if (e instanceof BillingError) throw e;
        await logUsage(supabase, {
          drawing_id, user_id, provider: "replicate", model: "rembg",
          operation: "background_removal", status: "error",
          cost_estimated: 0, error_message: e instanceof Error ? e.message : String(e),
        });
        console.error("Replicate background removal failed:", e instanceof Error ? e.message : String(e));
      }
    }

    // Fallback to Remove.bg
    if (!processedImageBytes && removeBgApiKey) {
      try {
        console.log("Attempting background removal with Remove.bg...");
        const bgStart2 = Date.now();
        processedImageBytes = await removeBackgroundRemoveBg(imageBytes, removeBgApiKey);
        console.log("Remove.bg background removal succeeded");
        await logUsage(supabase, {
          drawing_id, user_id, provider: "removebg", model: "removebg-v1",
          operation: "background_removal", status: "success",
          cost_estimated: costBgRemoval, latency_ms: Date.now() - bgStart2,
        });
      } catch (e) {
        await logUsage(supabase, {
          drawing_id, user_id, provider: "removebg", model: "removebg-v1",
          operation: "background_removal", status: "error",
          cost_estimated: 0, error_message: e instanceof Error ? e.message : String(e),
        });
        console.error("Remove.bg background removal failed:", e);
      }
    }

    // Upload processed image if we have it
    if (processedImageBytes) {
      const processedPath = `${user_id}/processed_${drawing_id}.png`;
      const { error: uploadError } = await supabase.storage
        .from("drawings-processed")
        .upload(processedPath, processedImageBytes, {
          contentType: "image/png",
          upsert: true,
        });

      if (!uploadError) {
        const { data: urlData } = supabase.storage
          .from("drawings-processed")
          .getPublicUrl(processedPath);
        processedImageUrl = urlData.publicUrl;
        console.log("Processed image uploaded:", processedImageUrl);
      }
    }

    // =========================================
    // STEP 1.5: CUPPY STYLIZATION (img2img with Flux Schnell)
    // =========================================
    let stylizedImageUrl: string | null = null;

    if (processedImageBytes && replicateToken) {
      await supabase.from("drawings").update({ processing_step: "stylizing" }).eq("id", drawing_id);

      const stylizeStart = Date.now();
      try {
        console.log("Stylizing with Flux Schnell (Cuppy style)...");
        const stylizedBytes = await stylizeWithFlux(processedImageBytes, replicateToken);

        if (stylizedBytes) {
          const stylizedPath = `${user_id}/stylized_${drawing_id}.png`;
          const { error: stylizeUploadError } = await supabase.storage
            .from("drawings-processed")
            .upload(stylizedPath, stylizedBytes, {
              contentType: "image/png",
              upsert: true,
            });

          if (!stylizeUploadError) {
            const { data: stylizedUrlData } = supabase.storage
              .from("drawings-processed")
              .getPublicUrl(stylizedPath);
            stylizedImageUrl = stylizedUrlData.publicUrl;
            console.log("Stylized image uploaded:", stylizedImageUrl);
          }
        }
        await logUsage(supabase, {
          drawing_id, user_id, provider: "replicate", model: "sdxl",
          operation: "stylization", status: "success",
          cost_estimated: costStylization, latency_ms: Date.now() - stylizeStart,
        });
      } catch (e) {
        if (e instanceof BillingError) throw e;
        await logUsage(supabase, {
          drawing_id, user_id, provider: "replicate", model: "sdxl",
          operation: "stylization", status: "error",
          cost_estimated: 0, latency_ms: Date.now() - stylizeStart,
          error_message: e instanceof Error ? e.message : String(e),
        });
        console.error("SDXL stylization failed, using plain bg-removed image:", e);
      }
    }

    // =========================================
    // STEP 2: 3D MODEL GENERATION (ASYNC WITH WEBHOOK)
    // =========================================
    await supabase.from("drawings").update({ processing_step: "generating_3d" }).eq("id", drawing_id);

    const imageForModel = processedImageBytes || imageBytes;
    let has3DPending = false;

    if (replicateToken && imageForModel) {
      try {
        console.log("Starting async 3D generation with Replicate TripoSR...");
        const predictionId = await start3DGenerationAsync(
          imageForModel,
          replicateToken,
          drawing_id,
          user_id,
          supabase
        );
        console.log("3D generation started async, prediction ID:", predictionId);
        has3DPending = true;
        await logUsage(supabase, {
          drawing_id, user_id, provider: "replicate", model: "triposr",
          operation: "3d_generation", status: "success",
          cost_estimated: cost3D,
          metadata: { prediction_id: predictionId, async: true },
        });
      } catch (e) {
        if (e instanceof BillingError) throw e;
        await logUsage(supabase, {
          drawing_id, user_id, provider: "replicate", model: "triposr",
          operation: "3d_generation", status: "error",
          cost_estimated: 0, error_message: e instanceof Error ? e.message : String(e),
        });
        console.error("Failed to start 3D generation:", e);
      }
    }

    // =========================================
    // STEP 3: CRITICAL DB UPDATE (before thumbnail — must not be blocked)
    // =========================================
    const processingTimeMs = Date.now() - startTime;
    const finalStatus = has3DPending && !model3dUrl ? "processing_3d" : "completed";
    const conceptUrl = stylizedImageUrl || processedImageUrl || null;

    console.log(`Setting drawing status to: ${finalStatus}, concept: ${conceptUrl ? "YES" : "NO"}`);

    const updateData: Record<string, unknown> = {
      model_status: finalStatus,
      processing_step: has3DPending ? "waiting_3d" : "done",
    };

    if (finalStatus === "completed") {
      updateData.processing_completed_at = new Date().toISOString();
    }
    if (processedImageUrl) {
      updateData.processed_image_url = processedImageUrl;
    }
    if (model3dUrl) {
      updateData.model_3d_url = model3dUrl;
    }

    await supabase
      .from("drawings")
      .update(updateData)
      .eq("id", drawing_id);

    console.log("Critical DB update done — UI should transition now");

    // =========================================
    // STEP 4: THUMBNAIL (non-critical, best-effort)
    // =========================================
    try {
      const thumbBytes = processedImageBytes || imageBytes;
      const thumbPath = `${drawing_id}/thumbnail.png`;
      await supabase.storage
        .from("models-thumbnails")
        .upload(thumbPath, thumbBytes, {
          contentType: "image/png",
          upsert: true,
        });
      const { data: thumbUrlData } = supabase.storage
        .from("models-thumbnails")
        .getPublicUrl(thumbPath);
      thumbnailUrl = thumbUrlData.publicUrl;

      if (thumbnailUrl) {
        await supabase.from("drawings").update({ thumbnail_url: thumbnailUrl }).eq("id", drawing_id);
      }
    } catch (thumbError) {
      console.error("Thumbnail upload failed (non-critical):", thumbError);
    }

    // =========================================
    // STEP 5: NOTIFICATION (non-critical, best-effort)
    // =========================================
    try {
      await supabase.from("notifications").insert({
        user_id: user_id,
        type: "drawing_processed",
        title: "Your drawing is ready!",
        message: has3DPending
          ? "Your drawing concept is ready! 3D model is generating..."
          : "Your drawing has been processed. Tap to view!",
        action_url: `/viewer/${drawing_id}`,
        metadata: { drawing_id, has_3d: !!model3dUrl },
      });
    } catch (notifError) {
      console.error("Failed to create notification:", notifError);
    }

    console.log(`Processing complete in ${processingTimeMs}ms`);

    const result: ProcessingResult & { fn_version?: string } = {
      success: true,
      fn_version: FUNCTION_VERSION,
      processed_image_url: processedImageUrl || undefined,
      concept_url: conceptUrl || undefined,
      model_3d_url: model3dUrl || undefined,
      thumbnail_url: thumbnailUrl || undefined,
      processing_time_ms: processingTimeMs,
      est_time_seconds: has3DPending ? 120 : 0,
    };

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error: unknown) {
    console.error("Processing error:", error);

    const errMsg = error instanceof Error ? error.message : String(error);
    const isBilling = error instanceof BillingError;
    const errorKey = isBilling ? "billing_error" : errMsg;

    // Try to update status to failed
    try {
      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
      const supabase = createClient(supabaseUrl, supabaseServiceKey);

      const body = await req.clone().json().catch(() => ({}));
      const { drawing_id } = body;

      if (drawing_id) {
        await supabase
          .from("drawings")
          .update({
            model_status: "failed",
            processing_error: errMsg,
          })
          .eq("id", drawing_id);
      }
    } catch {
      // Ignore update error
    }

    return new Response(
      JSON.stringify({ success: false, error: errorKey, error_message: errMsg }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// =========================================
// VISION VALIDATION FUNCTION
// =========================================

async function validateDrawingWithVision(
  imageBytes: Uint8Array,
  token: string
): Promise<{ is_drawing: boolean; reason: string }> {
  const base64Image = base64Encode(imageBytes);

  // Use Moondream vision model to check if the image is a child's drawing
  // deno-lint-ignore no-explicit-any
  const prediction: any = await createReplicatePrediction(
    token,
    "cdda81e2bd1a78618ddc1fb5c6a3e2888a41023f49467dafeb589ea1de1d650c", // moondream2
    {
      image: `data:image/png;base64,${base64Image}`,
      prompt: "Is this image a drawing or sketch made by a child on paper? Answer with YES or NO followed by a brief reason.",
    }
  );

  // Poll for completion (vision models are fast, ~5s)
  let result = prediction;
  const maxWait = 10000;
  const startTime = Date.now();

  while (result.status === "starting" || result.status === "processing") {
    if (Date.now() - startTime > maxWait) {
      throw new Error("Vision validation timeout");
    }
    await new Promise((resolve) => setTimeout(resolve, 1000));
    const statusResponse = await fetch(result.urls.get, {
      headers: { "Authorization": `Token ${token}` },
    });
    result = await statusResponse.json();
  }

  if (result.status === "failed" || !result.output) {
    throw new Error("Vision prediction failed");
  }

  // Parse the model output
  const output = (typeof result.output === "string"
    ? result.output
    : Array.isArray(result.output) ? result.output.join("") : String(result.output)
  ).trim().toLowerCase();

  const isDrawing = output.startsWith("yes");

  return {
    is_drawing: isDrawing,
    reason: typeof result.output === "string" ? result.output.trim() : String(result.output).trim(),
  };
}

// =========================================
// BACKGROUND REMOVAL FUNCTIONS
// =========================================

async function removeBackgroundReplicate(imageBytes: Uint8Array, token: string): Promise<Uint8Array> {
  const base64Image = base64Encode(imageBytes);

  // deno-lint-ignore no-explicit-any
  const prediction: any = await createReplicatePrediction(
    token,
    "fb8af171cfa1616ddcf1242c093f9c46bcada5ad4cf6f2fbe8b81b330ec5c003",
    { image: `data:image/png;base64,${base64Image}` }
  );

  // Poll for completion with timeout to avoid Edge Function timeout
  let result = prediction;
  const maxWait = 15000; // 15 seconds max (Edge Functions timeout at 30s)
  const startTime = Date.now();
  
  while (result.status === "starting" || result.status === "processing") {
    if (Date.now() - startTime > maxWait) {
      console.warn("Background removal taking too long, returning without processed image");
      throw new Error("Background removal timeout");
    }
    await new Promise((resolve) => setTimeout(resolve, 1000));
    const statusResponse = await fetch(result.urls.get, {
      headers: { "Authorization": `Token ${token}` },
    });
    result = await statusResponse.json();
  }

  if (result.status === "failed" || !result.output) {
    throw new Error("Replicate prediction failed");
  }

  // Download result image
  const imageResponse = await fetch(result.output);
  const arrayBuffer = await imageResponse.arrayBuffer();
  return new Uint8Array(arrayBuffer);
}

async function removeBackgroundRemoveBg(imageBytes: Uint8Array, apiKey: string): Promise<Uint8Array> {
  const blob = new Blob([imageBytes], { type: "image/png" });
  const formData = new FormData();
  formData.append("image_file", blob);
  formData.append("size", "auto");
  formData.append("format", "png");

  const response = await fetch("https://api.remove.bg/v1.0/removebg", {
    method: "POST",
    headers: {
      "X-Api-Key": apiKey,
    },
    body: formData,
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Remove.bg API error: ${response.status} - ${errorText}`);
  }

  const arrayBuffer = await response.arrayBuffer();
  return new Uint8Array(arrayBuffer);
}

// =========================================
// 3D GENERATION FUNCTIONS
// =========================================

// Start async 3D generation with webhook
async function start3DGenerationAsync(
  imageBytes: Uint8Array,
  token: string,
  drawingId: string,
  userId: string,
  supabase: ReturnType<typeof createClient>
): Promise<string> {
  const base64Image = base64Encode(imageBytes);
  const webhookUrl = `${Deno.env.get("SUPABASE_URL")}/functions/v1/process-webhook`;

  console.log("Calling Replicate API for 3D generation...");
  console.log("Webhook URL:", webhookUrl);

  // deno-lint-ignore no-explicit-any
  const prediction: any = await createReplicatePrediction(
    token,
    "ecd9d615e9efb7fd2a5e26bb51fc53e652b61ff7f5aac6bca7e16c2e4edba5f5", // TripoSR
    {
      image: `data:image/png;base64,${base64Image}`,
      mc_resolution: 256,
      foreground_ratio: 0.9,
    },
    {
      webhook: webhookUrl,
      webhook_events_filter: ["completed"],
    }
  );
  console.log("Replicate prediction created:", prediction.id);

  // Store prediction mapping in ai_predictions table
  await supabase.from("ai_predictions").insert({
    prediction_id: prediction.id,
    drawing_id: drawingId,
    user_id: userId,
    prediction_type: "3d_generation",
    status: prediction.status || "starting",
  });

  return prediction.id;
}

async function generate3DRodin(
  imageUrl: string,
  apiKey: string,
  drawingId: string,
  supabase: ReturnType<typeof createClient>
): Promise<string> {
  const response = await fetch("https://api.hyper3d.ai/v1/generate", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      image_url: imageUrl,
      output_format: "glb",
      quality: "high",
    }),
  });

  if (!response.ok) {
    throw new Error(`Rodin API error: ${response.status}`);
  }

  const result = await response.json();

  // Download and store the GLB file
  const glbResponse = await fetch(result.model_url);
  const glbArrayBuffer = await glbResponse.arrayBuffer();

  const glbPath = `${drawingId}/model.glb`;
  await supabase.storage
    .from("models-3d")
    .upload(glbPath, new Uint8Array(glbArrayBuffer), {
      contentType: "model/gltf-binary",
      upsert: true,
    });

  const { data: urlData } = supabase.storage
    .from("models-3d")
    .getPublicUrl(glbPath);

  return urlData.publicUrl;
}

// =========================================
// CUPPY STYLIZATION (SDXL img2img)
// =========================================

async function stylizeWithFlux(imageBytes: Uint8Array, token: string): Promise<Uint8Array> {
  const base64Image = base64Encode(imageBytes);

  const STYLE_PROMPT = "A cute 3D toy character, claymation style, made of plasticine, play-doh texture, cute, puffy, volumetric, soft studio lighting, octane render, high quality, isometric view, smooth vinyl toy, tactile feeling, clean white background";

  console.log("Starting SDXL img2img stylization...");

  // deno-lint-ignore no-explicit-any
  const prediction: any = await createReplicatePrediction(
    token,
    "39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b", // stability-ai/sdxl (supports img2img)
    {
      image: `data:image/png;base64,${base64Image}`,
      prompt: STYLE_PROMPT,
      negative_prompt: "ugly, blurry, low quality, deformed, text, watermark, realistic photo",
      prompt_strength: 0.65,
      num_inference_steps: 25,
      guidance_scale: 7.5,
      scheduler: "K_EULER",
      disable_safety_checker: true,
    }
  );
  console.log("SDXL prediction created:", prediction.id);

  // Poll for completion (~10-20s for SDXL with 25 steps)
  let result = prediction;
  const maxWait = 30000;
  const pollStart = Date.now();

  while (result.status === "starting" || result.status === "processing") {
    if (Date.now() - pollStart > maxWait) {
      throw new Error("SDXL stylization timeout (30s)");
    }
    await new Promise((resolve) => setTimeout(resolve, 1500));
    const statusResponse = await fetch(result.urls.get, {
      headers: { "Authorization": `Token ${token}` },
    });
    result = await statusResponse.json();
  }

  if (result.status === "failed" || !result.output) {
    throw new Error(`SDXL prediction failed: ${result.error || "no output"}`);
  }

  console.log("SDXL stylization completed successfully");

  // SDXL returns an array of image URLs
  const outputUrl = Array.isArray(result.output) ? result.output[0] : result.output;
  const imageResponse = await fetch(outputUrl);
  const arrayBuffer = await imageResponse.arrayBuffer();
  return new Uint8Array(arrayBuffer);
}
