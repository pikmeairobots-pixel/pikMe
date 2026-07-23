-- Migration: 008_coupons_table
-- Purpose: Create table for restaurant coupons/promotions
-- Date: 2026-06-21

CREATE TABLE IF NOT EXISTS public.coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  coupon_type TEXT NOT NULL,
  discount_value NUMERIC NOT NULL,
  menu_item_id TEXT,
  coupon_code TEXT NOT NULL,
  expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
  usage_limit INTEGER,
  times_used INTEGER NOT NULL DEFAULT 0,
  conditions JSONB,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  -- Constraints
  CONSTRAINT valid_coupon_type CHECK (coupon_type IN ('item_percent', 'item_fixed', 'generic_percent', 'generic_fixed')),
  CONSTRAINT valid_discount_value CHECK (discount_value > 0),
  CONSTRAINT item_specific_requires_menu_item_id CHECK (
    (coupon_type IN ('item_percent', 'item_fixed') AND menu_item_id IS NOT NULL) OR
    (coupon_type IN ('generic_percent', 'generic_fixed') AND menu_item_id IS NULL)
  ),
  CONSTRAINT unique_code_per_restaurant UNIQUE(restaurant_id, coupon_code)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_coupons_restaurant_id ON public.coupons(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_coupons_menu_item_id ON public.coupons(menu_item_id);
CREATE INDEX IF NOT EXISTS idx_coupons_is_active ON public.coupons(is_active);
CREATE INDEX IF NOT EXISTS idx_coupons_expiry_date ON public.coupons(expiry_date);

-- Enable RLS
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Restaurant owners can view/manage their own coupons
CREATE POLICY "Owners can manage own coupons"
  ON public.coupons
  FOR ALL
  USING (
    restaurant_id IN (
      SELECT id FROM public.restaurants
      WHERE owner_id = (SELECT id FROM public.restaurant_owners WHERE id = auth.uid())
    )
  );

-- RLS Policy: Authenticated users can view active coupons (for display)
CREATE POLICY "Authenticated users can view active coupons"
  ON public.coupons
  FOR SELECT
  USING (is_active = true AND expiry_date > NOW());

-- RLS Policy: Service role has full access (for edge functions)
CREATE POLICY "Service role full access"
  ON public.coupons
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Add comments
COMMENT ON TABLE public.coupons IS 'Coupons and promotions created by restaurant owners. Types: item_percent (% off item), item_fixed ($ off item), generic_percent (% off total), generic_fixed ($ off total).';
COMMENT ON COLUMN public.coupons.coupon_type IS 'Type of coupon: item_percent, item_fixed, generic_percent, generic_fixed';
COMMENT ON COLUMN public.coupons.discount_value IS 'Discount amount (% or $ depending on type)';
COMMENT ON COLUMN public.coupons.menu_item_id IS 'Menu item ID (from FatSecret/USDA) - only for item-specific coupons';
COMMENT ON COLUMN public.coupons.conditions IS 'Flexible conditions object (min order, restrictions, etc.)';

-- Grant permissions
GRANT SELECT ON public.coupons TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.coupons TO authenticated;
