// Supabase Edge Function: Process Webhook
// Handles async callbacks from Replicate API for 3D generation

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface WebhookPayload {
  id: string;
  status: "succeeded" | "failed" | "canceled" | "processing" | "starting";
  output?: string | string[] | { glb?: string; obj?: string };
  error?: string;
  metrics?: {
    predict_time?: number;
  };
  version: string;
}

// Retry helper for fetch operations
async function fetchWithRetry(url: string, maxRetries = 3): Promise<Response> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const response = await fetch(url);
      if (response.ok) return response;
      console.warn(`Fetch attempt ${attempt}/${maxRetries} failed: ${response.status}`);
    } catch (e) {
      console.warn(`Fetch attempt ${attempt}/${maxRetries} error: ${e}`);
    }
    if (attempt < maxRetries) {
      await new Promise((r) => setTimeout(r, 1000 * attempt)); // backoff
    }
  }
  throw new Error(`Failed to fetch ${url} after ${maxRetries} attempts`);
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const payload: WebhookPayload = await req.json();
    console.log(`Webhook received: ${payload.id} - Status: ${payload.status}`);

    // Extract drawing_id from prediction metadata
    // We store prediction_id -> drawing_id mapping in ai_predictions table
    const { data: prediction, error: predictionError } = await supabase
      .from("ai_predictions")
      .select("drawing_id, user_id, prediction_type")
      .eq("prediction_id", payload.id)
      .single();

    if (predictionError || !prediction) {
      console.error("No prediction found for ID:", payload.id, predictionError);
      return new Response(
        JSON.stringify({ success: false, error: "Prediction not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { drawing_id, user_id, prediction_type } = prediction;
    console.log(`Processing webhook for drawing: ${drawing_id}, type: ${prediction_type}`);

    // Handle different statuses
    if (payload.status === "succeeded") {
      const updateData: Record<string, unknown> = {};

      if (prediction_type === "background_removal" && payload.output) {
        // Download and store processed image
        const imageUrl = Array.isArray(payload.output) ? payload.output[0] : String(payload.output);
        console.log("Downloading processed image:", imageUrl);

        const imageResponse = await fetchWithRetry(imageUrl);
        const imageData = await imageResponse.arrayBuffer();

        const processedPath = `${user_id}/processed_${drawing_id}.png`;
        const { error: uploadError } = await supabase.storage
          .from("drawings-processed")
          .upload(processedPath, new Uint8Array(imageData), {
            contentType: "image/png",
            upsert: true,
          });

        if (!uploadError) {
          const { data: urlData } = supabase.storage
            .from("drawings-processed")
            .getPublicUrl(processedPath);
          updateData.processed_image_url = urlData.publicUrl;
          console.log("Processed image uploaded:", urlData.publicUrl);
        }
      } else if (prediction_type === "3d_generation" && payload.output) {
        // Download and store 3D model
        let modelUrl: string | null = null;

        // Handle different output formats
        if (typeof payload.output === "string") {
          modelUrl = payload.output;
        } else if (Array.isArray(payload.output)) {
          modelUrl = payload.output[0];
        } else if (typeof payload.output === "object" && payload.output.glb) {
          modelUrl = payload.output.glb;
        }

        if (modelUrl) {
          console.log("Downloading 3D model:", modelUrl);

          const modelResponse = await fetchWithRetry(modelUrl);
          const modelData = await modelResponse.arrayBuffer();

          const modelPath = `${drawing_id}/model.glb`;
          const { error: uploadError } = await supabase.storage
            .from("models-3d")
            .upload(modelPath, new Uint8Array(modelData), {
              contentType: "model/gltf-binary",
              upsert: true,
            });

          if (!uploadError) {
            const { data: urlData } = supabase.storage
              .from("models-3d")
              .getPublicUrl(modelPath);
            updateData.model_3d_url = urlData.publicUrl;
            updateData.model_status = "completed";
            updateData.processing_step = "done";
            updateData.processing_completed_at = new Date().toISOString();
            console.log("3D model uploaded:", urlData.publicUrl);
          }
        }
      }

      // Update drawing with results
      if (Object.keys(updateData).length > 0) {
        await supabase.from("drawings").update(updateData).eq("id", drawing_id);
        console.log("Drawing updated:", updateData);
      }

      // Create notification for 3D completion
      if (prediction_type === "3d_generation" && updateData.model_3d_url) {
        await supabase.from("notifications").insert({
          user_id: user_id,
          type: "drawing_processed",
          title: "Your 3D model is ready!",
          message: "Your drawing has been transformed into 3D! Tap to view in AR!",
          action_url: `/viewer/${drawing_id}`,
          metadata: { drawing_id, has_3d: true },
        });
        console.log("Notification created for user:", user_id);
      }
    } else if (payload.status === "failed") {
      // Update drawing as failed
      console.error("Prediction failed:", payload.error);
      await supabase
        .from("drawings")
        .update({
          model_status: "failed",
          processing_error: payload.error || "AI processing failed",
          processing_completed_at: new Date().toISOString(),
        })
        .eq("id", drawing_id);
    }

    // Update prediction record
    await supabase
      .from("ai_predictions")
      .update({
        status: payload.status,
        output: typeof payload.output === "string" ? payload.output : JSON.stringify(payload.output),
        error: payload.error,
        completed_at: new Date().toISOString(),
        processing_time: payload.metrics?.predict_time,
      })
      .eq("prediction_id", payload.id);

    console.log("Webhook processing complete");

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Webhook error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
