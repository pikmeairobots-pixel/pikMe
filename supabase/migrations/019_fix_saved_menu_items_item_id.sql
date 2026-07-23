-- Migration: 019_fix_saved_menu_items_item_id
-- Purpose: Migration 011 renamed nix_item_id -> item_id in menu_items and
--          restaurant_menu_items but missed saved_menu_items, leaving it with
--          the old column name. This breaks toggle_saved_menu_item and
--          get_saved_items (both reference saved_menu_items.item_id -> 42703).
-- Date: 2026-06-27

DO $$
BEGIN
  IF to_regclass('public.saved_menu_items') IS NULL THEN
    RETURN;
  END IF;

  -- Rename the stale column only if needed.
  IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'saved_menu_items'
          AND column_name = 'nix_item_id'
      )
     AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'saved_menu_items'
          AND column_name = 'item_id'
      )
  THEN
    ALTER TABLE public.saved_menu_items RENAME COLUMN nix_item_id TO item_id;
  END IF;
END $$;
