-- Migration: 010_restaurant_menu_items
-- Purpose: Store cached menu items for restaurants (for owner coupon management)
-- Date: 2026-06-22

CREATE TABLE IF NOT EXISTS public.restaurant_menu_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL,
  name TEXT NOT NULL,
  serving_weight_grams NUMERIC,
  calories NUMERIC,
  total_fat_g NUMERIC,
  saturated_fat_g NUMERIC,
  sodium_mg NUMERIC,
  total_carbs_g NUMERIC,
  protein_g NUMERIC,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  -- Constraints
  CONSTRAINT unique_item_per_restaurant UNIQUE(restaurant_id, item_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_restaurant_menu_items_restaurant_id ON public.restaurant_menu_items(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_menu_items_item_id ON public.restaurant_menu_items(item_id);

-- Enable RLS
ALTER TABLE public.restaurant_menu_items ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Restaurant owners can view their own menu items
CREATE POLICY "Owners can view own menu items"
  ON public.restaurant_menu_items
  FOR SELECT
  USING (
    restaurant_id IN (
      SELECT id FROM public.restaurants
      WHERE owner_id = auth.uid()
    )
  );

-- RLS Policy: Service role has full access
CREATE POLICY "Service role full access"
  ON public.restaurant_menu_items
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Add comment
COMMENT ON TABLE public.restaurant_menu_items IS 'Cached menu items for each restaurant, used by owner for creating item-specific coupons';
COMMENT ON COLUMN public.restaurant_menu_items.item_id IS 'Nutritionix item ID for matching to menu items';

-- Grant permissions
GRANT SELECT ON public.restaurant_menu_items TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.restaurant_menu_items TO authenticated;
GRANT ALL ON public.restaurant_menu_items TO public;
GRANT ALL ON public.restaurant_menu_items TO service_role;
