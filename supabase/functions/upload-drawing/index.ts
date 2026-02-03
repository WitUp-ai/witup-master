// Supabase Edge Function: Upload Drawing
// Handles image upload bypassing Storage RLS policies
// Required because modifying Storage RLS directly is restricted

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";
import { decode as base64Decode } from "https://deno.land/std@0.168.0/encoding/base64.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Client for auth verification
    const supabaseAuth = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: req.headers.get("Authorization")! } },
    });

    // Verify user is authenticated
    const {
      data: { user },
      error: authError,
    } = await supabaseAuth.auth.getUser();

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized", details: authError?.message }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse request body
    const { image_base64, file_name, content_type } = await req.json();

    if (!image_base64 || !file_name) {
      return new Response(
        JSON.stringify({ error: "Missing image_base64 or file_name" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Decode base64 image
    const imageBytes = base64Decode(image_base64);

    // Client with service role to bypass RLS
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // Construct storage path: {user_id}/{filename}
    const storagePath = `${user.id}/${file_name}`;

    // Upload to Storage
    const { data, error: uploadError } = await supabaseAdmin.storage
      .from("drawings-original")
      .upload(storagePath, imageBytes, {
        contentType: content_type || "image/jpeg",
        upsert: true,
      });

    if (uploadError) {
      throw uploadError;
    }

    // Get signed URL (optional, but useful)
    const { data: signedUrlData } = await supabaseAdmin.storage
      .from("drawings-original")
      .createSignedUrl(storagePath, 3600);

    return new Response(
      JSON.stringify({
        success: true,
        storage_path: storagePath,
        public_url: signedUrlData?.signedUrl,
        file_name: file_name
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Upload error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
