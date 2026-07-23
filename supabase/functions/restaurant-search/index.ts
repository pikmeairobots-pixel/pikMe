import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const GOOGLE_PLACES_KEY = Deno.env.get("GOOGLE_PLACES_KEY")!;

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const { query } = await req.json();

    if (!query || typeof query !== "string") {
      return new Response(
        JSON.stringify({ error: "Query is required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Search Google Places
    const searchUrl = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(query)}&type=restaurant&key=${GOOGLE_PLACES_KEY}`;

    const response = await fetch(searchUrl);
    const data = await response.json();

    if (data.status !== "OK") {
      return new Response(
        JSON.stringify({ error: "No restaurants found" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    // Return results in expected format
    const results = (data.results || []).map((place: any) => ({
      place_id: place.place_id,
      name: place.name,
      formatted_address: place.formatted_address,
    }));

    return new Response(
      JSON.stringify({ results }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[restaurant-search] Error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
