-- Cleanup procedure to drop all tables and functions
-- Run this manually in Supabase SQL Editor when you need to reset the database
-- Usage: CALL public.cleanup_all_objects();

CREATE OR REPLACE PROCEDURE public.cleanup_all_objects()
LANGUAGE plpgsql
AS $$
BEGIN
  -- Drop functions
  DROP FUNCTION IF EXISTS public.create_coupon CASCADE;
  DROP FUNCTION IF EXISTS public.update_coupon CASCADE;
  DROP FUNCTION IF EXISTS public.delete_coupon CASCADE;
  DROP FUNCTION IF EXISTS public.get_restaurant_coupons CASCADE;
  DROP FUNCTION IF EXISTS public.get_active_coupons_for_restaurant CASCADE;
  DROP FUNCTION IF EXISTS public.get_coupons_for_menu_item CASCADE;
  DROP FUNCTION IF EXISTS public.record_user_agreement CASCADE;
  DROP FUNCTION IF EXISTS public.has_user_agreed CASCADE;
  DROP FUNCTION IF EXISTS public.get_user_agreement_history CASCADE;
  DROP FUNCTION IF EXISTS public.admin_get_all_agreements CASCADE;
  DROP PROCEDURE IF EXISTS public.delete_user_account CASCADE;

  -- Drop tables in public schema
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

  -- Delete auth users (but don't drop the auth schema table)
  DELETE FROM auth.users;

  RAISE NOTICE 'All objects and auth users deleted successfully';
END;
$$;
