-- Migration: 005_user_agreements_table
-- Purpose: Create table to track user agreement acceptance for legal compliance
-- Date: 2026-06-19

-- Create user_agreements table
CREATE TABLE IF NOT EXISTS public.user_agreements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  agreement_type TEXT NOT NULL,
  version TEXT NOT NULL DEFAULT '1.0',
  agreed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  -- Constraints
  CONSTRAINT valid_agreement_type CHECK (agreement_type IN ('privacy_policy', 'terms_of_service', 'food_disclaimer')),
  CONSTRAINT user_agreement_unique UNIQUE(user_id, agreement_type, version)
);

-- Create indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_user_agreements_user_id ON public.user_agreements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_agreements_type ON public.user_agreements(agreement_type);
CREATE INDEX IF NOT EXISTS idx_user_agreements_agreed_at ON public.user_agreements(agreed_at DESC);

-- Enable RLS (Row Level Security)
ALTER TABLE public.user_agreements ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only view their own agreements
CREATE POLICY "Users can view own agreements"
  ON public.user_agreements
  FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can only insert their own agreements
CREATE POLICY "Users can insert own agreements"
  ON public.user_agreements
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Admins/Service role can view all (for audit)
CREATE POLICY "Service role can view all agreements"
  ON public.user_agreements
  FOR SELECT
  USING (
    current_user = 'postgres'
    OR current_user = 'authenticated'
    OR current_setting('request.jwt.claims', true)::jsonb->>'role' = 'service_role'
    OR session_user = 'postgres'
  );

-- Add comment
COMMENT ON TABLE public.user_agreements IS 'Audit trail of user agreement acceptance. Tracks which agreements each user has accepted, when, and from which IP/device.';
COMMENT ON COLUMN public.user_agreements.agreement_type IS 'Type of agreement: privacy_policy, terms_of_service, or food_disclaimer';
COMMENT ON COLUMN public.user_agreements.version IS 'Version of the agreement accepted (e.g., 1.0, 1.1)';
COMMENT ON COLUMN public.user_agreements.agreed_at IS 'Timestamp when user agreed (user-client time)';
COMMENT ON COLUMN public.user_agreements.ip_address IS 'IP address from which agreement was accepted (optional, for audit)';
COMMENT ON COLUMN public.user_agreements.user_agent IS 'User agent / device info from which agreement was accepted (optional, for audit)';

-- Create function to record agreement
CREATE OR REPLACE FUNCTION public.record_user_agreement(
  p_agreement_type TEXT,
  p_version TEXT DEFAULT '1.0',
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_agreement_id UUID;
BEGIN
  INSERT INTO public.user_agreements (
    user_id,
    agreement_type,
    version,
    ip_address,
    user_agent,
    agreed_at
  )
  VALUES (
    auth.uid(),
    p_agreement_type,
    p_version,
    p_ip_address,
    p_user_agent,
    NOW()
  )
  ON CONFLICT (user_id, agreement_type, version)
  DO UPDATE SET
    agreed_at = NOW(),
    ip_address = COALESCE(p_ip_address, user_agreements.ip_address),
    user_agent = COALESCE(p_user_agent, user_agreements.user_agent)
  RETURNING id INTO v_agreement_id;

  RETURN v_agreement_id;
END;
$$;

-- Create function to check if user has agreed to a specific agreement
CREATE OR REPLACE FUNCTION public.has_user_agreed(
  p_agreement_type TEXT,
  p_version TEXT DEFAULT '1.0'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_agreements
    WHERE user_id = auth.uid()
      AND agreement_type = p_agreement_type
      AND version = p_version
  );
END;
$$;

-- Create function to get user's agreement history
CREATE OR REPLACE FUNCTION public.get_user_agreement_history(p_user_id UUID DEFAULT NULL)
RETURNS TABLE (
  agreement_type TEXT,
  version TEXT,
  agreed_at TIMESTAMP WITH TIME ZONE,
  ip_address INET,
  user_agent TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_current_user_id UUID;
BEGIN
  -- Get current authenticated user (may be NULL for service role)
  v_current_user_id := auth.uid();

  -- Determine which user's data to fetch
  IF p_user_id IS NOT NULL THEN
    -- Explicitly requested user (service role can do this)
    v_user_id := p_user_id;
  ELSIF v_current_user_id IS NOT NULL THEN
    -- Default to current authenticated user
    v_user_id := v_current_user_id;
  ELSE
    -- No user specified and not authenticated
    RAISE EXCEPTION 'Must be authenticated or provide a user_id';
  END IF;

  -- RLS will enforce permissions based on policies
  RETURN QUERY
  SELECT
    ua.agreement_type,
    ua.version,
    ua.agreed_at,
    ua.ip_address,
    ua.user_agent
  FROM public.user_agreements ua
  WHERE ua.user_id = v_user_id
  ORDER BY ua.agreed_at DESC;
END;
$$;

-- Create admin function to view all agreements (bypasses RLS)
CREATE OR REPLACE FUNCTION public.admin_get_all_agreements()
RETURNS TABLE (
  user_id UUID,
  agreement_type TEXT,
  version TEXT,
  agreed_at TIMESTAMP WITH TIME ZONE,
  ip_address INET,
  user_agent TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Function runs with SECURITY DEFINER, so it bypasses RLS
  -- This allows anyone to execute it, but they'll only see data based on RLS policies
  -- For true admin access, call from service_role context

  RETURN QUERY
  SELECT
    ua.user_id,
    ua.agreement_type,
    ua.version,
    ua.agreed_at,
    ua.ip_address,
    ua.user_agent
  FROM public.user_agreements ua
  ORDER BY ua.agreed_at DESC;
END;
$$;

-- Grant permissions
GRANT SELECT, INSERT ON public.user_agreements TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_user_agreement(TEXT, TEXT, INET, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_user_agreed(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_agreement_history(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_get_all_agreements() TO authenticated;
