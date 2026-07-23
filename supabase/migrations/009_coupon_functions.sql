-- Migration: 009_coupon_functions
-- Purpose: RPC functions for coupon management and retrieval
-- Date: 2026-06-21

-- Function: Create a new coupon
DROP FUNCTION IF EXISTS public.create_coupon(UUID, TEXT, NUMERIC, TEXT, TIMESTAMP WITH TIME ZONE, TEXT, INTEGER, JSONB) CASCADE;
CREATE OR REPLACE FUNCTION public.create_coupon(
  p_restaurant_id UUID,
  p_coupon_type TEXT,
  p_discount_value NUMERIC,
  p_coupon_code TEXT,
  p_expiry_date TIMESTAMP WITH TIME ZONE,
  p_menu_item_id TEXT DEFAULT NULL,
  p_usage_limit INTEGER DEFAULT NULL,
  p_conditions JSONB DEFAULT NULL
)
RETURNS TABLE (
  coupon_id UUID,
  restaurant_id UUID,
  coupon_type TEXT,
  discount_value NUMERIC,
  menu_item_id TEXT,
  coupon_code TEXT,
  expiry_date TIMESTAMP WITH TIME ZONE,
  usage_limit INTEGER,
  times_used INTEGER,
  conditions JSONB,
  is_active BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_owner_id UUID;
BEGIN
  -- Verify user owns the restaurant
  SELECT owner_id INTO v_owner_id
  FROM public.restaurants
  WHERE id = p_restaurant_id;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'Restaurant not found';
  END IF;

  IF v_owner_id != auth.uid() THEN
    RAISE EXCEPTION 'Not authorized to manage this restaurant';
  END IF;

  RETURN QUERY
  INSERT INTO public.coupons (
    restaurant_id,
    coupon_type,
    discount_value,
    menu_item_id,
    coupon_code,
    expiry_date,
    usage_limit,
    conditions
  )
  VALUES (
    p_restaurant_id,
    p_coupon_type,
    p_discount_value,
    p_menu_item_id,
    p_coupon_code,
    p_expiry_date,
    p_usage_limit,
    p_conditions
  )
  RETURNING
    coupons.id,
    coupons.restaurant_id,
    coupons.coupon_type,
    coupons.discount_value,
    coupons.menu_item_id,
    coupons.coupon_code,
    coupons.expiry_date,
    coupons.usage_limit,
    coupons.times_used,
    coupons.conditions,
    coupons.is_active,
    coupons.created_at;
END;
$$;

-- Function: Update a coupon
DROP FUNCTION IF EXISTS public.update_coupon(UUID, TEXT, NUMERIC, TEXT, TIMESTAMP WITH TIME ZONE, TEXT, INTEGER, JSONB, BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION public.update_coupon(
  p_coupon_id UUID,
  p_coupon_type TEXT DEFAULT NULL,
  p_discount_value NUMERIC DEFAULT NULL,
  p_coupon_code TEXT DEFAULT NULL,
  p_expiry_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  p_menu_item_id TEXT DEFAULT NULL,
  p_usage_limit INTEGER DEFAULT NULL,
  p_conditions JSONB DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
  coupon_id UUID,
  restaurant_id UUID,
  coupon_type TEXT,
  discount_value NUMERIC,
  menu_item_id TEXT,
  coupon_code TEXT,
  expiry_date TIMESTAMP WITH TIME ZONE,
  usage_limit INTEGER,
  times_used INTEGER,
  conditions JSONB,
  is_active BOOLEAN,
  updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_owner_id UUID;
BEGIN
  -- Verify user owns the restaurant
  SELECT r.owner_id INTO v_owner_id
  FROM public.coupons c
  JOIN public.restaurants r ON c.restaurant_id = r.id
  WHERE c.id = p_coupon_id;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'Coupon not found';
  END IF;

  IF v_owner_id != auth.uid() THEN
    RAISE EXCEPTION 'Not authorized to update this coupon';
  END IF;

  RETURN QUERY
  UPDATE public.coupons
  SET
    coupon_type = COALESCE(p_coupon_type, public.coupons.coupon_type),
    discount_value = COALESCE(p_discount_value, public.coupons.discount_value),
    coupon_code = COALESCE(p_coupon_code, public.coupons.coupon_code),
    expiry_date = COALESCE(p_expiry_date, public.coupons.expiry_date),
    menu_item_id = COALESCE(p_menu_item_id, public.coupons.menu_item_id),
    usage_limit = COALESCE(p_usage_limit, public.coupons.usage_limit),
    conditions = COALESCE(p_conditions, public.coupons.conditions),
    is_active = COALESCE(p_is_active, public.coupons.is_active),
    updated_at = NOW()
  WHERE public.coupons.id = p_coupon_id
  RETURNING
    coupons.id,
    coupons.restaurant_id,
    coupons.coupon_type,
    coupons.discount_value,
    coupons.menu_item_id,
    coupons.coupon_code,
    coupons.expiry_date,
    coupons.usage_limit,
    coupons.times_used,
    coupons.conditions,
    coupons.is_active,
    coupons.updated_at;
END;
$$;

-- Function: Delete a coupon
CREATE OR REPLACE FUNCTION public.delete_coupon(p_coupon_id UUID)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_owner_id UUID;
  v_rows_deleted INTEGER;
BEGIN
  -- Verify user owns the restaurant
  SELECT r.owner_id INTO v_owner_id
  FROM public.coupons c
  JOIN public.restaurants r ON c.restaurant_id = r.id
  WHERE c.id = p_coupon_id;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'Coupon not found';
  END IF;

  IF v_owner_id != auth.uid() THEN
    RAISE EXCEPTION 'Not authorized to delete this coupon';
  END IF;

  DELETE FROM public.coupons WHERE id = p_coupon_id;
  GET DIAGNOSTICS v_rows_deleted = ROW_COUNT;

  RETURN QUERY
  SELECT
    v_rows_deleted > 0 AS success,
    'Coupon deleted' AS message;
END;
$$;

-- Function: Get all coupons for a restaurant
DROP FUNCTION IF EXISTS public.get_restaurant_coupons(UUID) CASCADE;
CREATE OR REPLACE FUNCTION public.get_restaurant_coupons(p_restaurant_id UUID)
RETURNS TABLE (
  coupon_id UUID,
  coupon_type TEXT,
  discount_value NUMERIC,
  menu_item_id TEXT,
  coupon_code TEXT,
  expiry_date TIMESTAMP WITH TIME ZONE,
  usage_limit INTEGER,
  times_used INTEGER,
  conditions JSONB,
  is_active BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_owner_id UUID;
BEGIN
  -- Verify user owns the restaurant
  SELECT owner_id INTO v_owner_id
  FROM public.restaurants
  WHERE id = p_restaurant_id;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'Restaurant not found';
  END IF;

  IF v_owner_id != auth.uid() THEN
    RAISE EXCEPTION 'Not authorized to view these coupons';
  END IF;

  RETURN QUERY
  SELECT
    c.id,
    c.coupon_type,
    c.discount_value,
    c.menu_item_id,
    c.coupon_code,
    c.expiry_date,
    c.usage_limit,
    c.times_used,
    c.conditions,
    c.is_active,
    c.created_at,
    c.updated_at
  FROM public.coupons c
  WHERE c.restaurant_id = p_restaurant_id
  ORDER BY c.created_at DESC;
END;
$$;

-- Function: Get coupons for a specific restaurant (public - for customer display)
DROP FUNCTION IF EXISTS public.get_active_coupons_for_restaurant(UUID) CASCADE;
CREATE OR REPLACE FUNCTION public.get_active_coupons_for_restaurant(p_restaurant_id UUID)
RETURNS TABLE (
  coupon_id UUID,
  coupon_type TEXT,
  discount_value NUMERIC,
  menu_item_id TEXT,
  coupon_code TEXT,
  expiry_date TIMESTAMP WITH TIME ZONE,
  usage_limit INTEGER,
  times_used INTEGER,
  conditions JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.coupon_type,
    c.discount_value,
    c.menu_item_id,
    c.coupon_code,
    c.expiry_date,
    c.usage_limit,
    c.times_used,
    c.conditions
  FROM public.coupons c
  WHERE c.restaurant_id = p_restaurant_id
    AND c.is_active = true
    AND c.expiry_date > NOW()
  ORDER BY c.coupon_type DESC, c.created_at DESC;
END;
$$;

-- Function: Get coupons for a specific menu item
DROP FUNCTION IF EXISTS public.get_coupons_for_menu_item(UUID, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.get_coupons_for_menu_item(
  p_restaurant_id UUID,
  p_menu_item_id TEXT
)
RETURNS TABLE (
  coupon_id UUID,
  coupon_type TEXT,
  discount_value NUMERIC,
  coupon_code TEXT,
  expiry_date TIMESTAMP WITH TIME ZONE,
  usage_limit INTEGER,
  times_used INTEGER,
  conditions JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.coupon_type,
    c.discount_value,
    c.coupon_code,
    c.expiry_date,
    c.usage_limit,
    c.times_used,
    c.conditions
  FROM public.coupons c
  WHERE c.restaurant_id = p_restaurant_id
    AND (c.menu_item_id = p_menu_item_id OR c.menu_item_id IS NULL)
    AND c.is_active = true
    AND c.expiry_date > NOW()
  ORDER BY c.menu_item_id DESC NULLS LAST, c.discount_value DESC;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.create_coupon TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_coupon TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_coupon TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_restaurant_coupons TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_active_coupons_for_restaurant TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_coupons_for_menu_item TO authenticated;

-- Grant schema and table permissions
GRANT ALL ON SCHEMA public TO public;
GRANT ALL ON ALL TABLES IN SCHEMA public TO public;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO public;
