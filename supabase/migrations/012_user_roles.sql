-- Migration: 012_user_roles
-- Purpose: Add user role system for admin access
-- Date: 2026-06-22

CREATE TABLE IF NOT EXISTS public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  -- Constraints
  CONSTRAINT valid_role CHECK (role IN ('admin', 'owner', 'customer')),
  CONSTRAINT unique_user_role UNIQUE(user_id, role)
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON public.user_roles(role);

-- Enable RLS
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own roles
CREATE POLICY "Users can view own roles"
  ON public.user_roles
  FOR SELECT
  USING (user_id = auth.uid());

-- RLS Policy: Admins can view all roles
CREATE POLICY "Admins can view all roles"
  ON public.user_roles
  FOR SELECT
  USING (
    user_id IN (
      SELECT user_id FROM public.user_roles
      WHERE role = 'admin' AND user_id = auth.uid()
    )
  );

-- RLS Policy: Service role has full access
CREATE POLICY "Service role full access"
  ON public.user_roles
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Add comment
COMMENT ON TABLE public.user_roles IS 'Maps users to their roles (admin, owner, customer)';

-- Grant permissions
GRANT SELECT ON public.user_roles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO public;
GRANT ALL ON public.user_roles TO service_role;
