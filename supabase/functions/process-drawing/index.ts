// Supabase Edge Function: Process Drawing
// Handles background removal and 3D model generation
// Supports: Replicate, Remove.bg, Rodin, CSM APIs

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";
import { encode as base64Encode } from "https://deno.land/std@0.168.0/encoding/base64.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
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
  model_3d_url?: string;
  thumbnail_url?: string;
  processing_time_ms?: number;
  error?: string;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const startTime = Date.now();

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const replicateToken = Deno.env.get("REPLICATE_API_TOKEN");
    const removeBgApiKey = Deno.env.get("REMOVE_BG_API_KEY");
    const rodinApiKey = Deno.env.get("RODIN_API_KEY");

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

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
        console.warn("Vision validation failed, proceeding anyway:", e);
      }
    }

    // =========================================
    // STEP 1: BACKGROUND REMOVAL
    // =========================================
    let processedImageBytes: Uint8Array | null = null;

    // Try Replicate first (rembg model)
    if (replicateToken) {
      try {
        console.log("Attempting background removal with Replicate...");
        processedImageBytes = await removeBackgroundReplicate(imageBytes, replicateToken);
        console.log("Replicate background removal succeeded");
      } catch (e) {
        console.error("Replicate background removal failed:", e);
      }
    }

    // Fallback to Remove.bg
    if (!processedImageBytes && removeBgApiKey) {
      try {
        console.log("Attempting background removal with Remove.bg...");
        processedImageBytes = await removeBackgroundRemoveBg(imageBytes, removeBgApiKey);
        console.log("Remove.bg background removal succeeded");
      } catch (e) {
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
    // STEP 2: 3D MODEL GENERATION (ASYNC WITH WEBHOOK)
    // =========================================
    const imageForModel = processedImageBytes || imageBytes;
    
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
      } catch (e) {
        console.error("Failed to start 3D generation:", e);
      }
    }

    // =========================================
    // STEP 3: GENERATE THUMBNAIL
    // =========================================
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

    // =========================================
    // STEP 4: UPDATE DATABASE
    // =========================================
    const processingTimeMs = Date.now() - startTime;

    // If 3D generation was started async (webhook), keep status as "processing_3d"
    // Only mark "completed" if no 3D generation was attempted or if model URL is available
    const has3DPending = replicateToken && imageForModel; // 3D was kicked off async
    const finalStatus = has3DPending && !model3dUrl ? "processing_3d" : "completed";

    console.log(`Setting drawing status to: ${finalStatus}`);

    const updateData: Record<string, unknown> = {
      model_status: finalStatus,
      processing_completed_at: finalStatus === "completed" ? new Date().toISOString() : undefined,
    };

    if (processedImageUrl) {
      updateData.processed_image_url = processedImageUrl;
    }
    if (model3dUrl) {
      updateData.model_3d_url = model3dUrl;
    }
    if (thumbnailUrl) {
      updateData.thumbnail_url = thumbnailUrl;
    }

    await supabase
      .from("drawings")
      .update(updateData)
      .eq("id", drawing_id);

    // =========================================
    // STEP 5: CREATE NOTIFICATION
    // =========================================
    try {
      await supabase.from("notifications").insert({
        user_id: user_id,
        type: "drawing_processed",
        title: "Your drawing is ready!",
        message: model3dUrl
          ? "Your drawing has been transformed into 3D! Tap to view in AR!"
          : "Your drawing has been processed. Tap to view!",
        action_url: `/viewer/${drawing_id}`,
        metadata: { drawing_id, has_3d: !!model3dUrl },
      });
    } catch (notifError) {
      console.error("Failed to create notification:", notifError);
    }

    console.log(`Processing complete in ${processingTimeMs}ms`);

    const result: ProcessingResult = {
      success: true,
      processed_image_url: processedImageUrl || undefined,
      model_3d_url: model3dUrl || undefined,
      thumbnail_url: thumbnailUrl || undefined,
      processing_time_ms: processingTimeMs,
    };

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("Processing error:", error);

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
            processing_error: error.message,
          })
          .eq("id", drawing_id);
      }
    } catch {
      // Ignore update error
    }

    return new Response(
      JSON.stringify({ success: false, error: error.message }),
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
  const response = await fetch("https://api.replicate.com/v1/predictions", {
    method: "POST",
    headers: {
      "Authorization": `Token ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      version: "cdda81e2bd1a78618ddc1fb5c6a3e2888a41023f49467dafeb589ea1de1d650c", // moondream2
      input: {
        image: `data:image/png;base64,${base64Image}`,
        prompt: "Is this image a drawing or sketch made by a child on paper? Answer with YES or NO followed by a brief reason.",
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`Replicate vision API error: ${response.status}`);
  }

  const prediction = await response.json();

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

  const response = await fetch("https://api.replicate.com/v1/predictions", {
    method: "POST",
    headers: {
      "Authorization": `Token ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      version: "fb8af171cfa1616ddcf1242c093f9c46bcada5ad4cf6f2fbe8b81b330ec5c003",
      input: {
        image: `data:image/png;base64,${base64Image}`,
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`Replicate API error: ${response.status}`);
  }

  const prediction = await response.json();

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

  const response = await fetch("https://api.replicate.com/v1/predictions", {
    method: "POST",
    headers: {
      "Authorization": `Token ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      version: "ecd9d615e9efb7fd2a5e26bb51fc53e652b61ff7f5aac6bca7e16c2e4edba5f5", // TripoSR
      input: {
        image: `data:image/png;base64,${base64Image}`,
        mc_resolution: 256,
        foreground_ratio: 0.9,
      },
      webhook: webhookUrl,
      webhook_events_filter: ["completed"],
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Replicate API error: ${response.status} - ${errorText}`);
  }

  const prediction = await response.json();
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
