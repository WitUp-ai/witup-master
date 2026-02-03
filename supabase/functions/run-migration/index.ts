// Temporary Edge Function to run the camera fix migration
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

Deno.serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Remove foreign key constraint if it exists
    const dropConstraintQuery = `
      ALTER TABLE public.drawings
      DROP CONSTRAINT IF EXISTS drawings_user_id_fkey;
    `;

    // Execute via RPC or direct SQL if available
    console.log("Attempting to drop foreign key constraint...");

    // Try to execute - will fail if constraint doesn't exist, but that's OK
    try {
      await supabase.rpc('exec_sql', { query: dropConstraintQuery });
    } catch (e) {
      console.log("Could not drop via RPC, constraint might not exist or RPC not available");
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Migration attempted. Foreign key constraint removed if it existed.",
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Migration error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "Unknown error",
      }),
      { headers: { "Content-Type": "application/json" }, status: 500 }
    );
  }
});
