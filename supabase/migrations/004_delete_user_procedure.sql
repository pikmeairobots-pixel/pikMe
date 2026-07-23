-- Migration: 004_delete_user_procedure
-- Purpose: Create stored procedure to completely delete a user and all associated data
-- Date: 2026-06-19

-- Drop existing procedure if it exists
DROP PROCEDURE IF EXISTS public.delete_user_account(UUID);

-- Create procedure to delete user and all cascading data
CREATE OR REPLACE PROCEDURE public.delete_user_account(p_user_id UUID)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Delete chat messages
  DELETE FROM public.chat_messages WHERE user_id = p_user_id;

  -- Delete saved items
  DELETE FROM public.saved_restaurants WHERE user_id = p_user_id;
  DELETE FROM public.saved_menu_items WHERE user_id = p_user_id;

  -- Delete user profile data
  DELETE FROM public.user_allergens WHERE user_id = p_user_id;
  DELETE FROM public.user_cuisine_preferences WHERE user_id = p_user_id;
  DELETE FROM public.user_dietary_restrictions WHERE user_id = p_user_id;
  DELETE FROM public.user_health_goals WHERE user_id = p_user_id;
  DELETE FROM public.user_nutrition_targets WHERE user_id = p_user_id;

  -- Delete user profile
  DELETE FROM public.user_profiles WHERE id = p_user_id;

  -- Delete user agreements
  DELETE FROM public.user_agreements WHERE user_id = p_user_id;

  -- Delete from auth.users (cascades to auth.identities automatically)
  DELETE FROM auth.users WHERE id = p_user_id;

  -- Log deletion (optional - comment out if not needed)
  RAISE NOTICE 'User % and all associated data deleted', p_user_id;
END;
$$;

-- Grant execute permission to authenticated users (they can only delete their own account)
GRANT EXECUTE ON PROCEDURE public.delete_user_account(UUID) TO authenticated;

-- Add comment to procedure
COMMENT ON PROCEDURE public.delete_user_account(UUID) IS 'Completely deletes a user account and all associated data including chat, saved items, and profile information. Use with caution - this is irreversible.';
