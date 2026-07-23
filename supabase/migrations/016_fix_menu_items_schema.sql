-- Migration: 016_fix_menu_items_schema
-- Purpose: Ensure restaurant_menu_items table has correct schema
-- Date: 2026-06-27

-- Drop old column if it still exists
ALTER TABLE public.restaurant_menu_items
DROP COLUMN IF EXISTS nix_item_id;

-- Ensure item_id column exists and has correct properties
ALTER TABLE public.restaurant_menu_items
ADD COLUMN IF NOT EXISTS item_id TEXT;

-- Update the comment
COMMENT ON COLUMN public.restaurant_menu_items.item_id IS 'Item ID for matching to menu items';

-- Recreate index if needed
CREATE INDEX IF NOT EXISTS idx_restaurant_menu_items_item_id
ON public.restaurant_menu_items(item_id);
