-- Migration: 017_owner_must_change_password
-- Purpose: Force restaurant owners created by an admin to change their
--          temporary password on first login.
-- Date: 2026-06-27

ALTER TABLE public.restaurant_owners
ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.restaurant_owners.must_change_password IS
  'When true, the owner is forced to set a new password on next login (e.g. accounts provisioned by an admin with a temporary password).';
