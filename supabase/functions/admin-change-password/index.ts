import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const { email, currentPassword, newPassword } = await req.json();

    if (!email || !currentPassword || !newPassword) {
      return new Response(
        JSON.stringify({ error: "Email, current password, and new password required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Create admin client with service role
    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Verify current password by attempting to sign in
    const { data: signInData, error: signInError } = await adminClient.auth.signInWithPassword({
      email,
      password: currentPassword,
    });

    if (signInError || !signInData.user) {
      console.error("[admin-change-password] Sign in failed:", signInError);
      return new Response(
        JSON.stringify({ error: "Current password is incorrect" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    // Update password using admin API
    const { data, error } = await adminClient.auth.admin.updateUserById(
      signInData.user.id,
      { password: newPassword }
    );

    if (error) {
      console.error("[admin-change-password] Update error:", error);
      return new Response(
        JSON.stringify({ error: error.message || "Failed to update password" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log("[admin-change-password] Password updated successfully for:", email);
    return new Response(
      JSON.stringify({ success: true, message: "Password changed successfully" }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[admin-change-password] Error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message || "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
