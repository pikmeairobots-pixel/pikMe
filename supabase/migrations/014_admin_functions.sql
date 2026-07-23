-- Migration: 014_admin_functions
-- Purpose: RPC functions for admin claim approval
-- Date: 2026-06-22

-- Function: Approve restaurant claim
CREATE OR REPLACE FUNCTION public.approve_restaurant_claim(p_restaurant_id UUID, p_reason TEXT DEFAULT NULL)
RETURNS TABLE (
  restaurant_id UUID,
  status TEXT,
  approved_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  -- Check if user is admin
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
  ) INTO v_is_admin;

  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Only admins can approve claims';
  END IF;

  RETURN QUERY
  UPDATE public.restaurants
  SET
    status = 'approved',
    approved_at = NOW(),
    approved_by = auth.uid(),
    updated_at = NOW()
  WHERE id = p_restaurant_id
  RETURNING public.restaurants.id, public.restaurants.status, public.restaurants.approved_at;
END;
$$;

-- Function: Reject restaurant claim
CREATE OR REPLACE FUNCTION public.reject_restaurant_claim(p_restaurant_id UUID, p_reason TEXT DEFAULT NULL)
RETURNS TABLE (
  restaurant_id UUID,
  status TEXT,
  updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  -- Check if user is admin
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
  ) INTO v_is_admin;

  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Only admins can reject claims';
  END IF;

  RETURN QUERY
  UPDATE public.restaurants
  SET
    status = 'rejected',
    updated_at = NOW()
  WHERE id = p_restaurant_id
  RETURNING public.restaurants.id, public.restaurants.status, public.restaurants.updated_at;
END;
$$;

-- Function: Get pending claims for admin
CREATE OR REPLACE FUNCTION public.get_pending_claims()
RETURNS TABLE (
  restaurant_id UUID,
  google_place_id TEXT,
  name TEXT,
  address TEXT,
  owner_id UUID,
  owner_email TEXT,
  business_name TEXT,
  claimed_at TIMESTAMP WITH TIME ZONE,
  status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  -- Check if user is admin
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
  ) INTO v_is_admin;

  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Only admins can view claims';
  END IF;

  RETURN QUERY
  SELECT
    r.id,
    r.google_place_id,
    r.name,
    r.address,
    ro.id,
    ro.email,
    ro.business_name,
    r.claimed_at,
    r.status
  FROM public.restaurants r
  JOIN public.restaurant_owners ro ON r.owner_id = ro.id
  WHERE r.status = 'pending'
  ORDER BY r.claimed_at ASC;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.approve_restaurant_claim TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_restaurant_claim TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pending_claims TO authenticated;
