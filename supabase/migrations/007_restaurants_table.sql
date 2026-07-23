-- Migration: 007_restaurants_table
-- Purpose: Create table to track claimed restaurants by owners
-- Date: 2026-06-21

CREATE TABLE IF NOT EXISTS public.restaurants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.restaurant_owners(id) ON DELETE CASCADE,
  google_place_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  claimed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_restaurants_owner_id ON public.restaurants(owner_id);
CREATE INDEX IF NOT EXISTS idx_restaurants_google_place_id ON public.restaurants(google_place_id);

-- Enable RLS
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Restaurant owners can view their own restaurants
CREATE POLICY "Owners can view own restaurants"
  ON public.restaurants
  FOR SELECT
  USING (owner_id = auth.uid());

-- RLS Policy: Restaurant owners can update their own restaurants
CREATE POLICY "Owners can update own restaurants"
  ON public.restaurants
  FOR UPDATE
  USING (owner_id = auth.uid());

-- RLS Policy: Authenticated users can view all restaurants (read-only for coupons display)
CREATE POLICY "Authenticated users can view all restaurants"
  ON public.restaurants
  FOR SELECT
  USING (true);

-- RLS Policy: Service role has full access (for edge functions)
CREATE POLICY "Service role full access"
  ON public.restaurants
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Add comment
COMMENT ON TABLE public.restaurants IS 'Tracks restaurants claimed by owners for coupon management. Links Google Places restaurants to PikMe restaurant owners.';
COMMENT ON COLUMN public.restaurants.google_place_id IS 'Google Places API place ID for matching with restaurant listings';
COMMENT ON COLUMN public.restaurants.address IS 'Restaurant address for matching/verification';

-- Grant permissions
GRANT SELECT ON public.restaurants TO authenticated;
GRANT SELECT, UPDATE ON public.restaurants TO authenticated;
