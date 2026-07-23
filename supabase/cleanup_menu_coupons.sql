-- Cleanup script: Clear menu_items and coupons tables for fresh sync
-- Run this in Supabase SQL Editor to reset the data

BEGIN;

-- Disable foreign key constraints temporarily
ALTER TABLE public.coupons DISABLE TRIGGER ALL;
ALTER TABLE public.menu_items DISABLE TRIGGER ALL;
ALTER TABLE public.item_health_analysis DISABLE TRIGGER ALL;
ALTER TABLE public.saved_menu_items DISABLE TRIGGER ALL;

-- Clear tables
TRUNCATE TABLE public.coupons CASCADE;
TRUNCATE TABLE public.menu_items CASCADE;
TRUNCATE TABLE public.item_health_analysis CASCADE;

-- Re-enable triggers
ALTER TABLE public.coupons ENABLE TRIGGER ALL;
ALTER TABLE public.menu_items ENABLE TRIGGER ALL;
ALTER TABLE public.item_health_analysis ENABLE TRIGGER ALL;
ALTER TABLE public.saved_menu_items ENABLE TRIGGER ALL;

COMMIT;

-- Verify cleanup
SELECT 'menu_items' as table_name, COUNT(*) as rows FROM public.menu_items
UNION ALL
SELECT 'coupons', COUNT(*) FROM public.coupons
UNION ALL
SELECT 'item_health_analysis', COUNT(*) FROM public.item_health_analysis;
