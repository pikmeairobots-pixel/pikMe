import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    // 1. Verify the caller is authenticated. We only ever act on the verified
    //    caller id — the client sends no user id, so a user can only delete
    //    their own account.
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const token = authHeader.replace("Bearer ", "");
    const callerClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: caller, error: callerError } = await callerClient.auth.getUser(token);
    if (callerError || !caller.user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!SUPABASE_SERVICE_ROLE_KEY) {
      console.error("[delete-user] SUPABASE_SERVICE_ROLE_KEY is not set");
      return new Response(
        JSON.stringify({ error: "Server misconfigured: missing service role key" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const userId = caller.user.id;
    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 2. Delete all public-schema data for this user.
    const { error: dataError } = await adminClient.rpc("delete_user_data", {
      p_user_id: userId,
    });

    if (dataError) {
      console.error("[delete-user] Failed to delete user data:", dataError);
      return new Response(
        JSON.stringify({ error: dataError.message || "Failed to delete account data" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // 3. Delete the auth record (also revokes sessions and refresh tokens).
    const { error: authDeleteError } = await adminClient.auth.admin.deleteUser(userId);

    if (authDeleteError) {
      console.error("[delete-user] Failed to delete auth user:", authDeleteError);
      return new Response(
        JSON.stringify({ error: authDeleteError.message || "Failed to delete account" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log("[delete-user] Deleted account", userId);

    return new Response(
      JSON.stringify({ success: true, message: "Account deleted" }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[delete-user] Error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
