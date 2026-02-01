// ============================================================================
// Edge Function: Create Admin User
// Description: Creates admin user automatically if it doesn't exist
// Invoke: curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/create-admin
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const ADMIN_EMAIL = "giovanni.sapere@witup.ai";
const ADMIN_PASSWORD = "Gnotti2025!";
const ADMIN_NAME = "Giovanni Sapere";

Deno.serve(async (req) => {
  try {
    // Create Supabase admin client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Check if admin user already exists
    const { data: existingUsers, error: listError } = await supabaseAdmin.auth.admin.listUsers();

    if (listError) {
      throw new Error(`Failed to list users: ${listError.message}`);
    }

    const adminExists = existingUsers?.users.some((user) => user.email === ADMIN_EMAIL);

    if (adminExists) {
      return new Response(
        JSON.stringify({
          success: true,
          message: "Admin user already exists",
          email: ADMIN_EMAIL,
        }),
        {
          headers: { "Content-Type": "application/json" },
          status: 200,
        }
      );
    }

    // Create admin user
    const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
      email_confirm: true, // Auto-confirm email
      user_metadata: {
        name: ADMIN_NAME,
      },
    });

    if (createError) {
      throw new Error(`Failed to create admin user: ${createError.message}`);
    }

    // Insert into users table if it doesn't exist
    const { error: insertError } = await supabaseAdmin
      .from("users")
      .upsert(
        {
          id: newUser.user!.id,
          email: ADMIN_EMAIL,
          created_at: new Date().toISOString(),
        },
        {
          onConflict: "id",
        }
      );

    if (insertError) {
      console.error("Warning: Failed to insert into users table:", insertError.message);
      // Don't fail - user was created in auth, which is what matters
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Admin user created successfully",
        email: ADMIN_EMAIL,
        userId: newUser.user!.id,
      }),
      {
        headers: { "Content-Type": "application/json" },
        status: 201,
      }
    );
  } catch (error) {
    console.error("Error creating admin user:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "Unknown error occurred",
      }),
      {
        headers: { "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});
