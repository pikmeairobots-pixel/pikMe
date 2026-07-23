-- Cleanup script: Remove ALL PikMe tables and functions (migrations 001-009)
-- Use this for a complete database reset before reapplying all migrations
-- Date: 2026-06-21

-- ─── Drop all functions (009, 005) ────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.get_coupons_for_menu_item CASCADE;
DROP FUNCTION IF EXISTS public.get_active_coupons_for_restaurant CASCADE;
DROP FUNCTION IF EXISTS public.get_restaurant_coupons CASCADE;
DROP FUNCTION IF EXISTS public.delete_coupon CASCADE;
DROP FUNCTION IF EXISTS public.update_coupon CASCADE;
DROP FUNCTION IF EXISTS public.create_coupon CASCADE;
DROP FUNCTION IF EXISTS public.admin_get_all_agreements CASCADE;
DROP FUNCTION IF EXISTS public.get_user_agreement_history CASCADE;
DROP FUNCTION IF EXISTS public.has_user_agreed CASCADE;
DROP FUNCTION IF EXISTS public.record_user_agreement CASCADE;
DROP PROCEDURE IF EXISTS public.delete_user_account CASCADE;

-- ─── Drop all tables (006-009, 005, 004, 001-003) ──────────────────────────────
DROP TABLE IF EXISTS public.coupons CASCADE;
DROP TABLE IF EXISTS public.restaurants CASCADE;
DROP TABLE IF EXISTS public.restaurant_owners CASCADE;
DROP TABLE IF EXISTS public.user_agreements CASCADE;
DROP TABLE IF EXISTS public.recommendation_logs CASCADE;
DROP TABLE IF EXISTS public.chat_messages CASCADE;
DROP TABLE IF EXISTS public.saved_menu_items CASCADE;
DROP TABLE IF EXISTS public.saved_restaurants CASCADE;
DROP TABLE IF EXISTS public.item_health_analysis CASCADE;
DROP TABLE IF EXISTS public.menu_items CASCADE;
DROP TABLE IF EXISTS public.user_nutrition_targets CASCADE;
DROP TABLE IF EXISTS public.user_cuisine_preferences CASCADE;
DROP TABLE IF EXISTS public.user_allergens CASCADE;
DROP TABLE IF EXISTS public.user_health_goals CASCADE;
DROP TABLE IF EXISTS public.user_dietary_restrictions CASCADE;
DROP TABLE IF EXISTS public.user_profiles CASCADE;

-- Verify cleanup
SELECT
  'Cleanup complete. Remaining PikMe tables:' AS status,
  COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'restaurant_owners', 'restaurants', 'coupons', 'user_agreements',
    'user_profiles', 'user_dietary_restrictions', 'user_health_goals',
    'user_allergens', 'user_cuisine_preferences', 'user_nutrition_targets',
    'saved_restaurants', 'saved_menu_items', 'chat_messages',
    'recommendation_logs', 'menu_items', 'item_health_analysis'
  );
