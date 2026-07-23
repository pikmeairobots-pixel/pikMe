-- Migration: 011_rename_nix_item_id
-- Purpose: Rename nix_item_id to item_id for clarity in both tables
-- Date: 2026-06-22

-- Rename in restaurant_menu_items
ALTER TABLE public.restaurant_menu_items
RENAME COLUMN nix_item_id TO item_id;

-- Update index name
ALTER INDEX IF EXISTS idx_restaurant_menu_items_nix_item_id
RENAME TO idx_restaurant_menu_items_item_id;

-- Rename in menu_items (if column exists)
ALTER TABLE public.menu_items
RENAME COLUMN nix_item_id TO item_id;

-- Update comments
COMMENT ON COLUMN public.restaurant_menu_items.item_id IS 'Item ID for matching to menu items';
COMMENT ON COLUMN public.menu_items.item_id IS 'Unique menu item identifier';
