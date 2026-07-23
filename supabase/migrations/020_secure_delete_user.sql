-- Migration: 020_secure_delete_user
-- Purpose: Close a privilege-escalation hole in delete_user_account and provide a
--          service-role-only helper the delete-user edge function calls.
-- Date: 2026-07-14
--
-- Background: 004_delete_user_procedure granted EXECUTE on
-- delete_user_account(UUID) to `authenticated`. Because it takes an arbitrary
-- p_user_id, any signed-in user could delete ANY account by passing another
-- user's id. Account deletion now goes through the `delete-user` edge function,
-- which verifies the caller's JWT and only ever deletes their own id.

-- 1. Revoke the dangerous direct grant. Clients can no longer call this at all.
REVOKE EXECUTE ON PROCEDURE public.delete_user_account(UUID) FROM authenticated;

-- 2. Data-only deletion helper. Removes all public-schema rows for a user but
--    NOT the auth.users record — the edge function deletes that via the auth
--    admin API (which also revokes sessions/refresh tokens). Not granted to
--    `authenticated`; only the service-role key (used by the edge function)
--    can invoke it.
CREATE OR REPLACE FUNCTION public.delete_user_data(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.chat_messages            WHERE user_id = p_user_id;
  DELETE FROM public.saved_restaurants        WHERE user_id = p_user_id;
  DELETE FROM public.saved_menu_items         WHERE user_id = p_user_id;
  DELETE FROM public.user_allergens           WHERE user_id = p_user_id;
  DELETE FROM public.user_cuisine_preferences WHERE user_id = p_user_id;
  DELETE FROM public.user_dietary_restrictions WHERE user_id = p_user_id;
  DELETE FROM public.user_health_goals        WHERE user_id = p_user_id;
  DELETE FROM public.user_nutrition_targets   WHERE user_id = p_user_id;
  DELETE FROM public.user_profiles            WHERE id = p_user_id;
  DELETE FROM public.user_agreements          WHERE user_id = p_user_id;
END;
$$;

-- Lock the function down to service_role only. A new function grants EXECUTE to
-- PUBLIC by default, so we revoke that first, then grant it back solely to
-- service_role (used by the delete-user edge function). anon/authenticated
-- clients cannot call it.
REVOKE ALL ON FUNCTION public.delete_user_data(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_user_data(UUID) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.delete_user_data(UUID) TO service_role;

COMMENT ON FUNCTION public.delete_user_data(UUID) IS
  'Deletes all public-schema data for a user. Service-role only; called by the delete-user edge function after JWT verification. Does not touch auth.users.';
