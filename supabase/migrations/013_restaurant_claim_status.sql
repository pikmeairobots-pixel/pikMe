-- Migration: 013_restaurant_claim_status
-- Purpose: Add approval status for restaurant claims
-- Date: 2026-06-22

ALTER TABLE public.restaurants
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id),
ADD CONSTRAINT valid_status CHECK (status IN ('pending', 'approved', 'rejected'));

-- Create index
CREATE INDEX IF NOT EXISTS idx_restaurants_status ON public.restaurants(status);

-- Add comment
COMMENT ON COLUMN public.restaurants.status IS 'Restaurant claim status: pending, approved, or rejected';
COMMENT ON COLUMN public.restaurants.approved_at IS 'Timestamp when admin approved the claim';
COMMENT ON COLUMN public.restaurants.approved_by IS 'Admin user ID who approved the claim';
