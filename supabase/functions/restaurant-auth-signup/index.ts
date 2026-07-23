import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const { email, password, businessName } = await req.json();

    // Validate input
    if (!email || !password || !businessName) {
      return new Response(
        JSON.stringify({ error: "Email, password, and business name required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    if (password.length < 8) {
      return new Response(
        JSON.stringify({ error: "Password must be at least 8 characters" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    // 1. Sign up with Supabase Auth
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password,
    });

    if (authError) {
      return new Response(JSON.stringify({ error: authError.message }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!authData.user) {
      return new Response(
        JSON.stringify({ error: "Failed to create user" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Wait for user to be fully created in auth
    await new Promise(resolve => setTimeout(resolve, 500));

    // 2. Create restaurant_owners record with service role
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    console.log("[restaurant-auth-signup] Service key status:", serviceKey ? "present" : "MISSING");

    const supabaseService = createClient(
      SUPABASE_URL,
      serviceKey!
    );

    const { error: ownerError } = await supabaseService
      .from("restaurant_owners")
      .insert({
        id: authData.user.id,
        email,
        business_name: businessName,
      });

    if (ownerError) {
      console.error("[restaurant-auth-signup] Failed to create owner record:", JSON.stringify(ownerError, null, 2));
      return new Response(
        JSON.stringify({ error: ownerError?.message || "Failed to create owner account" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Restaurant owner account created. Check your email to confirm.",
        userId: authData.user.id,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[restaurant-auth-signup] Error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
