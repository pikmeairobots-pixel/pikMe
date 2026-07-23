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
    const { restaurantId, restaurantName } = await req.json();

    if (!restaurantId || !restaurantName) {
      return new Response(
        JSON.stringify({ error: "restaurantId and restaurantName required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Use service role for database access
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Fetch menu items from Claude via fetch-menu-items-ai function
    const menuResponse = await fetch(
      `${SUPABASE_URL}/functions/v1/fetch-menu-items-ai`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        },
        body: JSON.stringify({ restaurantName }),
      }
    );

    if (!menuResponse.ok) {
      const errorBody = await menuResponse.json();
      throw new Error(errorBody.error || "Failed to fetch menu items");
    }

    const menuItems = await menuResponse.json();

    // Clear existing menu items for this restaurant
    console.log("[refresh-restaurant-menu] Deleting existing items for restaurant:", restaurantId);
    const { error: deleteError, count: deletedCount } = await supabase
      .from("restaurant_menu_items")
      .delete()
      .eq("restaurant_id", restaurantId);

    if (deleteError) {
      console.error("[refresh-restaurant-menu] Delete error:", deleteError);
    } else {
      console.log("[refresh-restaurant-menu] Deleted", deletedCount, "existing items");
    }

    // Insert new menu items
    if (menuItems && menuItems.length > 0) {
      console.log("[refresh-restaurant-menu] Received items:", JSON.stringify(menuItems.slice(0, 2), null, 2));

      const itemsToInsert = menuItems.map((item: any) => {
        if (!item.itemId) {
          console.error("[refresh-restaurant-menu] Item missing itemId:", JSON.stringify(item, null, 2));
        }
        return {
          restaurant_id: restaurantId,
          item_id: item.itemId || `auto_${Math.random().toString(36).substr(2, 9)}`,
          name: item.name,
          serving_weight_grams: item.nutrition?.servingWeightGrams || null,
          calories: item.nutrition?.calories || null,
          total_fat_g: item.nutrition?.totalFat_g || null,
          saturated_fat_g: item.nutrition?.saturatedFat_g || null,
          sodium_mg: item.nutrition?.sodium_mg || null,
          total_carbs_g: item.nutrition?.totalCarbs_g || null,
          protein_g: item.nutrition?.protein_g || null,
          image_url: item.imageUrl || null,
        };
      });

      console.log("[refresh-restaurant-menu] Inserting items:", JSON.stringify(itemsToInsert.slice(0, 1), null, 2));

      const { error: insertError } = await supabase
        .from("restaurant_menu_items")
        .insert(itemsToInsert);

      if (insertError) {
        console.error("[refresh-restaurant-menu] Insert error:", JSON.stringify(insertError, null, 2));
        throw new Error(`Failed to save menu items: ${insertError.message}`);
      }

      console.log("[refresh-restaurant-menu] Successfully inserted items into restaurant_menu_items");

      // Also insert into global menu_items table for customers to see
      const globalMenuItems = menuItems.map((item: any, idx: number) => {
        try {
          const obj = {
            item_id: String(item.itemId || `auto_${Math.random().toString(36).substr(2, 9)}`).replace(/[^\w-]/g, '').trim(),
            restaurant_name: String(restaurantName || '').substring(0, 255),
            name: String(item.name || '').substring(0, 255),
            serving_weight_grams: item.nutrition?.servingWeightGrams ? Number(item.nutrition.servingWeightGrams) : null,
            calories: item.nutrition?.calories ? Number(item.nutrition.calories) : null,
            total_fat_g: item.nutrition?.totalFat_g ? Number(item.nutrition.totalFat_g) : null,
            saturated_fat_g: item.nutrition?.saturatedFat_g ? Number(item.nutrition.saturatedFat_g) : null,
            sodium_mg: item.nutrition?.sodium_mg ? Number(item.nutrition.sodium_mg) : null,
            total_carbs_g: item.nutrition?.totalCarbs_g ? Number(item.nutrition.totalCarbs_g) : null,
            protein_g: item.nutrition?.protein_g ? Number(item.nutrition.protein_g) : null,
            image_url: String(item.imageUrl || '').substring(0, 500) || null,
            is_verified: false,
            cached_at: new Date().toISOString(),
          };
          // Validate JSON serialization
          JSON.stringify(obj);
          return obj;
        } catch (e) {
          console.error("[refresh-restaurant-menu] Item", idx, "JSON error:", e);
          throw e;
        }
      });

      // Insert into global menu_items (ignore duplicates)
      console.log("[refresh-restaurant-menu] Attempting to insert", globalMenuItems.length, "items into menu_items");
      console.log("[refresh-restaurant-menu] First item sample:", JSON.stringify(globalMenuItems[0], null, 2));
      const { error: globalError, data: insertData } = await supabase
        .from("menu_items")
        .insert(globalMenuItems, { onConflict: "ignore" });

      if (globalError) {
        console.error("[refresh-restaurant-menu] Global menu_items error:", JSON.stringify(globalError, null, 2));
        console.error("[refresh-restaurant-menu] Error code:", globalError.code, "Message:", globalError.message);
        // Don't throw - this is non-critical, items still in restaurant_menu_items
        console.log("[refresh-restaurant-menu] Warning: Failed to sync to menu_items, but restaurant_menu_items updated");
      } else {
        console.log("[refresh-restaurant-menu] Successfully inserted items into menu_items, inserted rows:", insertData?.length);
      }

      // Cleanup: Remove items from restaurant_menu_items that don't have a matching item_id in menu_items
      if (menuItems.length > 0) {
        console.log("[refresh-restaurant-menu] Syncing restaurant_menu_items with menu_items");
        const itemIds = menuItems.map((item: any) => item.itemId);
        console.log("[refresh-restaurant-menu] Valid item IDs:", itemIds);

        // Delete items from restaurant_menu_items for this restaurant that don't match menu_items
        const { count: syncedCount, error: syncError } = await supabase
          .from("restaurant_menu_items")
          .delete()
          .eq("restaurant_id", restaurantId)
          .not("item_id", "in", `(${itemIds.map((id: string) => `"${id}"`).join(",")})`);

        if (syncError) {
          console.log("[refresh-restaurant-menu] Sync info (non-critical):", syncError.message);
        } else {
          console.log("[refresh-restaurant-menu] Synced menu items - removed", syncedCount || 0, "orphaned items");
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Menu refreshed with ${menuItems?.length || 0} items`,
        itemCount: menuItems?.length || 0,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[refresh-restaurant-menu] Error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message || "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
