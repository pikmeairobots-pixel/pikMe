-- Migration: 006_restaurant_owners_table
-- Purpose: Create table for restaurant owner accounts (separate from user accounts)
-- Date: 2026-06-21

CREATE TABLE IF NOT EXISTS public.restaurant_owners (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  business_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_restaurant_owners_email ON public.restaurant_owners(email);

-- Enable RLS
ALTER TABLE public.restaurant_owners ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Restaurant owners can view their own record
CREATE POLICY "Restaurant owners can view own record"
  ON public.restaurant_owners
  FOR SELECT
  USING (auth.uid() = id);

-- RLS Policy: Restaurant owners can update their own record
CREATE POLICY "Restaurant owners can update own record"
  ON public.restaurant_owners
  FOR UPDATE
  USING (auth.uid() = id);

-- RLS Policy: Service role has full access (for edge functions)
CREATE POLICY "Service role full access"
  ON public.restaurant_owners
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Add comment
COMMENT ON TABLE public.restaurant_owners IS 'Separate authentication and account info for restaurant owners managing coupons and promotions.';
COMMENT ON COLUMN public.restaurant_owners.id IS 'References auth.users(id) - shared with Supabase auth';
COMMENT ON COLUMN public.restaurant_owners.business_name IS 'Name of the restaurant business';
COMMENT ON COLUMN public.restaurant_owners.email IS 'Email used for restaurant owner login';

-- Grant permissions
GRANT SELECT, UPDATE ON public.restaurant_owners TO authenticated;
