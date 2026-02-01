# Webhook Implementation for Async AI Processing

## Current Architecture Issue
The Edge Function `/process-drawing` currently:
1. Processes images synchronously (blocks until AI processing completes)
2. Has timeout limitations (Edge Functions max 30 seconds)
3. Cannot handle long-running 3D generation (can take 60+ seconds)

## Solution: Async Processing with Webhooks

### Architecture
```
1. Frontend → Edge Function (quick validation)
2. Edge Function → Replicate API (async prediction)
3. Replicate API → Webhook URL (callback on completion)
4. Webhook Handler → Update database + notifications
```

### Implementation Steps

## Step 1: Create Webhook Edge Function

**File:** `supabase/functions/process-webhook/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface WebhookPayload {
  id: string;
  status: "succeeded" | "failed" | "canceled";
  output?: string | string[];
  error?: string;
  metrics?: {
    predict_time?: number;
  };
  version: string;
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
    console.log("Webhook received:", payload.id, payload.status);

    // Extract drawing_id from prediction metadata
    // We need to store prediction_id -> drawing_id mapping
    const { data: prediction } = await supabase
      .from("ai_predictions")
      .select("drawing_id, prediction_type")
      .eq("prediction_id", payload.id)
      .single();

    if (!prediction) {
      console.error("No prediction found for ID:", payload.id);
      return new Response(JSON.stringify({ error: "Prediction not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { drawing_id, prediction_type } = prediction;

    if (payload.status === "succeeded") {
      let updateData: Record<string, unknown> = {};
      
      if (prediction_type === "background_removal" && payload.output) {
        // Download and store processed image
        const imageUrl = Array.isArray(payload.output) ? payload.output[0] : payload.output;
        updateData.processed_image_url = await processAndStoreImage(
          imageUrl,
          drawing_id,
          "drawings-processed",
          supabase
        );
        
        // Trigger 3D generation if background removal succeeded
        await trigger3DGeneration(drawing_id, updateData.processed_image_url, supabase);
        
      } else if (prediction_type === "3d_generation" && payload.output) {
        // Download and store 3D model
        const modelUrl = Array.isArray(payload.output) ? payload.output[0] : payload.output;
        updateData.model_3d_url = await processAndStoreModel(
          modelUrl,
          drawing_id,
          "models-3d",
          supabase
        );
        
        // Update drawing status to completed
        updateData.model_status = "completed";
        updateData.processing_completed_at = new Date().toISOString();
      }

      // Update drawing with results
      await supabase
        .from("drawings")
        .update(updateData)
        .eq("id", drawing_id);

      // Create notification
      await supabase.from("notifications").insert({
        user_id: prediction.user_id,
        type: "drawing_processed",
        title: "Your drawing is ready!",
        message: prediction_type === "3d_generation" 
          ? "3D model generated successfully!" 
          : "Background removed successfully!",
        action_url: `/viewer/${drawing_id}`,
      });

    } else if (payload.status === "failed") {
      // Update drawing as failed
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
        output: payload.output,
        error: payload.error,
        completed_at: new Date().toISOString(),
        processing_time: payload.metrics?.predict_time,
      })
      .eq("prediction_id", payload.id);

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("Webhook error:", error);
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

async function processAndStoreImage(
  imageUrl: string,
  drawingId: string,
  bucket: string,
  supabase: ReturnType<typeof createClient>
): Promise<string> {
  const response = await fetch(imageUrl);
  const imageData = await response.arrayBuffer();
  
  const path = `${drawingId}/processed.png`;
  await supabase.storage
    .from(bucket)
    .upload(path, new Uint8Array(imageData), {
      contentType: "image/png",
      upsert: true,
    });

  const { data: urlData } = supabase.storage
    .from(bucket)
    .getPublicUrl(path);
  
  return urlData.publicUrl;
}

async function processAndStoreModel(
  modelUrl: string,
  drawingId: string,
  bucket: string,
  supabase: ReturnType<typeof createClient>
): Promise<string> {
  const response = await fetch(modelUrl);
  const modelData = await response.arrayBuffer();
  
  const path = `${drawingId}/model.glb`;
  await supabase.storage
    .from(bucket)
    .upload(path, new Uint8Array(modelData), {
      contentType: "model/gltf-binary",
      upsert: true,
    });

  const { data: urlData } = supabase.storage
    .from(bucket)
    .getPublicUrl(path);
  
  return urlData.publicUrl;
}

async function trigger3DGeneration(
  drawingId: string,
  processedImageUrl: string,
  supabase: ReturnType<typeof createClient>
) {
  // Get drawing details
  const { data: drawing } = await supabase
    .from("drawings")
    .select("user_id")
    .eq("id", drawingId)
    .single();

  if (!drawing) return;

  // Call Replicate for 3D generation
  const replicateToken = Deno.env.get("REPLICATE_API_TOKEN");
  const response = await fetch("https://api.replicate.com/v1/predictions", {
    method: "POST",
    headers: {
      "Authorization": `Token ${replicateToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      version: "ecd9d615e9efb7fd2a5e26bb51fc53e652b61ff7f5aac6bca7e16c2e4edba5f5", // TripoSR
      input: {
        image: processedImageUrl,
        mc_resolution: 256,
        foreground_ratio: 0.9,
      },
      webhook: `${Deno.env.get("SUPABASE_URL")}/functions/v1/process-webhook`,
      webhook_events_filter: ["completed"],
    }),
  });

  const prediction = await response.json();

  // Store prediction mapping
  await supabase.from("ai_predictions").insert({
    prediction_id: prediction.id,
    drawing_id: drawingId,
    user_id: drawing.user_id,
    prediction_type: "3d_generation",
    status: "starting",
    created_at: new Date().toISOString(),
  });
}
```

## Step 2: Create AI Predictions Table

**SQL Migration:**
```sql
CREATE TABLE IF NOT EXISTS public.ai_predictions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  prediction_id TEXT NOT NULL UNIQUE, -- Replicate prediction ID
  drawing_id UUID NOT NULL REFERENCES public.drawings(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  prediction_type TEXT NOT NULL, -- 'background_removal' or '3d_generation'
  status TEXT NOT NULL DEFAULT 'starting', -- starting, processing, succeeded, failed, canceled
  output TEXT,
  error TEXT,
  processing_time DECIMAL(10, 2), -- seconds
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ
);

CREATE INDEX idx_ai_predictions_drawing ON public.ai_predictions(drawing_id);
CREATE INDEX idx_ai_predictions_user ON public.ai_predictions(user_id);
CREATE INDEX idx_ai_predictions_status ON public.ai_predictions(status);
```

## Step 3: Update Process-Drawing Edge Function

Modify `supabase/functions/process-drawing/index.ts` to:
1. Create initial prediction record
2. Trigger async Replicate prediction with webhook
3. Return immediately with prediction ID

**Key Changes:**
```typescript
// Instead of synchronous processing:
async function processDrawingAsync(drawingId: string, userId: string) {
  // 1. Create prediction record
  const { data: prediction } = await supabase
    .from("ai_predictions")
    .insert({
      drawing_id: drawingId,
      user_id: userId,
      prediction_type: "background_removal",
      status: "starting",
    })
    .select()
    .single();

  // 2. Trigger Replicate async
  const replicateResponse = await fetch("https://api.replicate.com/v1/predictions", {
    method: "POST",
    headers: {
      "Authorization": `Token ${replicateToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      version: "fb8af171cfa1616ddcf1242c093f9c46bcada5ad4cf6f2fbe8b81b330ec5c003", // rembg
      input: {
        image: imageUrl,
        model: "u2net",
      },
      webhook: `${supabaseUrl}/functions/v1/process-webhook`,
      webhook_events_filter: ["completed"],
    }),
  });

  const replicatePrediction = await replicateResponse.json();

  // 3. Update prediction record with Replicate ID
  await supabase
    .from("ai_predictions")
    .update({
      prediction_id: replicatePrediction.id,
      status: replicatePrediction.status,
    })
    .eq("id", prediction.id);

  return {
    success: true,
    prediction_id: replicatePrediction.id,
    status: "processing",
    message: "AI processing started. You'll be notified when complete.",
  };
}
```

## Step 4: Frontend Integration

**Flutter/Dart Code:**
```dart
Future<void> processDrawing(String drawingId) async {
  final response = await supabase.functions.invoke('process-drawing', {
    body: {
      'drawing_id': drawingId,
      'user_id': currentUser.id,
    },
  });

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    
    if (data['status'] == 'processing') {
      // Show processing indicator
      showProcessingDialog(drawingId, data['prediction_id']);
      
      // Subscribe to real-time updates
      supabase
        .from('drawings')
        .stream(primaryKey: ['id'])
        .eq('id', drawingId)
        .listen((List<Map<String, dynamic>> updates) {
          final drawing = updates.first;
          if (drawing['model_status'] == 'completed') {
            // Show success and navigate to viewer
            showSuccessNotification();
            navigateToViewer(drawingId);
          } else if (drawing['model_status'] == 'failed') {
            // Show error
            showErrorNotification(drawing['processing_error']);
          }
        });
    }
  }
}
```

## Step 5: Deployment

```bash
# Deploy webhook function
supabase functions deploy process-webhook

# Set webhook URL in Replicate dashboard
# Or pass as parameter in API calls

# Deploy updated process-drawing function
supabase functions deploy process-drawing

# Run migration for ai_predictions table
supabase db push
```

## Benefits

1. **No Timeout Issues:** Processing can take minutes without blocking
2. **Better UX:** Immediate feedback + real-time updates
3. **Reliability:** Webhook ensures completion even if client disconnects
4. **Monitoring:** Track all AI predictions and their status
5. **Retry Logic:** Easy to implement retry for failed predictions

## Monitoring & Debugging

**Key Metrics to Track:**
- Average processing time per prediction type
- Success/failure rates
- Webhook delivery success rate
- Storage usage for processed images/models

**Debugging Tools:**
- Logs in Supabase Dashboard
- Replicate prediction status page
- Database queries on `ai_predictions` table
- Webhook delivery testing with tools like webhook.site