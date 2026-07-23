-- Migration: 012_soft_delete_coupons
-- Purpose: Add soft delete columns for audit trail instead of physical deletion
-- Date: 2026-06-28

-- Add soft delete columns to coupons table
ALTER TABLE public.coupons
ADD COLUMN is_deleted BOOLEAN DEFAULT false,
ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;

-- Add index for soft delete queries
CREATE INDEX idx_coupons_is_deleted ON public.coupons(is_deleted);
CREATE INDEX idx_coupons_deleted_at ON public.coupons(deleted_at);

-- Update delete_coupon function to use soft delete
DROP FUNCTION IF EXISTS public.delete_coupon(UUID);

CREATE FUNCTION public.delete_coupon(p_coupon_id UUID)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_owner_id UUID;
  v_rows_updated INTEGER;
BEGIN
  -- Get the owner ID from the coupon's restaurant
  SELECT auth.uid() INTO v_owner_id;

  -- Verify the user owns the restaurant that owns this coupon
  UPDATE public.coupons
  SET is_deleted = true, deleted_at = NOW()
  WHERE id = p_coupon_id
    AND restaurant_id IN (
      SELECT restaurants.id FROM restaurants
      WHERE restaurants.owner_id = v_owner_id
    );

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

  IF v_rows_updated = 0 THEN
    RETURN QUERY SELECT false, 'Coupon not found or unauthorized'::TEXT;
  ELSE
    RETURN QUERY SELECT true, 'Coupon deleted successfully'::TEXT;
  END IF;
END;
$$;

-- Update get_restaurant_coupons to exclude deleted coupons
DROP FUNCTION IF EXISTS public.get_restaurant_coupons(UUID);

CREATE FUNCTION public.get_restaurant_coupons(p_restaurant_id UUID)
RETURNS TABLE (
  id UUID,
  restaurant_id UUID,
  coupon_code TEXT,
  coupon_type TEXT,
  discount_value NUMERIC,
  menu_item_id TEXT,
  is_active BOOLEAN,
  expiry_date TIMESTAMP WITH TIME ZONE,
  usage_limit INT,
  times_used INT,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.restaurant_id,
    c.coupon_code,
    c.coupon_type,
    c.discount_value,
    c.menu_item_id,
    c.is_active,
    c.expiry_date,
    c.usage_limit,
    c.times_used,
    c.created_at,
    c.updated_at
  FROM public.coupons c
  WHERE c.restaurant_id = p_restaurant_id
    AND c.is_deleted = false
  ORDER BY c.created_at DESC;
END;
$$;

-- Update get_active_coupons_for_restaurant to exclude deleted coupons
DROP FUNCTION IF EXISTS public.get_active_coupons_for_restaurant(UUID);

CREATE FUNCTION public.get_active_coupons_for_restaurant(p_restaurant_id UUID)
RETURNS TABLE (
  id UUID,
  restaurant_id UUID,
  coupon_code TEXT,
  coupon_type TEXT,
  discount_value NUMERIC,
  menu_item_id TEXT,
  is_active BOOLEAN,
  expiry_date TIMESTAMP WITH TIME ZONE,
  usage_limit INT,
  times_used INT,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.restaurant_id,
    c.coupon_code,
    c.coupon_type,
    c.discount_value,
    c.menu_item_id,
    c.is_active,
    c.expiry_date,
    c.usage_limit,
    c.times_used,
    c.created_at,
    c.updated_at
  FROM public.coupons c
  WHERE c.restaurant_id = p_restaurant_id
    AND c.is_deleted = false
    AND c.is_active = true
    AND c.expiry_date > NOW()
  ORDER BY c.created_at DESC;
END;
$$;

-- Update get_coupons_for_menu_item to exclude deleted coupons
DROP FUNCTION IF EXISTS public.get_coupons_for_menu_item(UUID, TEXT);

CREATE FUNCTION public.get_coupons_for_menu_item(p_restaurant_id UUID, p_menu_item_id TEXT)
RETURNS TABLE (
  id UUID,
  coupon_code TEXT,
  coupon_type TEXT,
  discount_value NUMERIC,
  menu_item_id TEXT,
  expiry_date TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.coupon_code,
    c.coupon_type,
    c.discount_value,
    c.menu_item_id,
    c.expiry_date,
    c.is_active
  FROM public.coupons c
  WHERE c.restaurant_id = p_restaurant_id
    AND c.is_deleted = false
    AND (c.menu_item_id = p_menu_item_id OR c.menu_item_id IS NULL)
    AND c.is_active = true
    AND c.expiry_date > NOW()
  ORDER BY c.menu_item_id DESC NULLS LAST, c.discount_value DESC;
END;
$$;
