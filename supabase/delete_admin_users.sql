-- Script: Delete Admin Users
-- Purpose: Manual cleanup script to delete or modify admin users
-- IMPORTANT: This is NOT a migration. Run manually in Supabase SQL Editor.
-- Uncomment the section you want to run.

-- ============================================================================
-- OPTION 1: Delete a specific admin user (admin@example.com)
-- Uncomment to run:
-- ============================================================================
-- DELETE FROM public.user_roles
-- WHERE user_id = (SELECT id FROM auth.users WHERE email = 'admin@example.com');
--
-- DELETE FROM auth.users
-- WHERE email = 'admin@example.com';

-- ============================================================================
-- OPTION 2: Delete all admin users
-- Uncomment to run:
-- ============================================================================
-- DELETE FROM public.user_roles
-- WHERE role = 'admin';
--
-- DELETE FROM auth.users
-- WHERE id IN (
--   SELECT DISTINCT user_id FROM public.user_roles WHERE role = 'admin'
-- );

-- ============================================================================
-- OPTION 3: Remove admin role from a user (keep the user account)
-- Uncomment to run:
-- ============================================================================
-- DELETE FROM public.user_roles
-- WHERE user_id = (SELECT id FROM auth.users WHERE email = 'admin@example.com')
--   AND role = 'admin';

-- ============================================================================
-- List all current admin users (safe - just shows, doesn't delete)
-- ============================================================================
SELECT u.id, u.email, ur.role
FROM auth.users u
LEFT JOIN public.user_roles ur ON u.id = ur.user_id
WHERE ur.role = 'admin'
ORDER BY u.email;
