-- Script to create first admin user
-- Replace 'admin@example.com' with the actual admin email

-- 1. Find the user by email
WITH user_to_promote AS (
  SELECT id FROM auth.users
  WHERE email = 'admin@example.com'  -- <-- CHANGE THIS EMAIL
  LIMIT 1
)
-- 2. Insert admin role
INSERT INTO public.user_roles (user_id, role)
SELECT id, 'admin' FROM user_to_promote
ON CONFLICT (user_id, role) DO NOTHING;

-- 3. Verify admin was created
SELECT u.id, u.email, ur.role
FROM auth.users u
LEFT JOIN public.user_roles ur ON u.id = ur.user_id
WHERE u.email = 'admin@example.com';
