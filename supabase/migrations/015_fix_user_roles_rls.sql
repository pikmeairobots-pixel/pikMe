-- Migration: 015_fix_user_roles_rls
-- Purpose: Fix infinite recursion in user_roles RLS policy
-- Date: 2026-06-22

-- Drop the problematic policy that causes infinite recursion
DROP POLICY IF EXISTS "Admins can view all roles" ON public.user_roles;

-- Keep only safe policies:
-- 1. Users can view their own roles
-- 2. Service role has full access

-- No need for a policy allowing admins to view all roles
-- Admins can check via the auth layer or via service role
