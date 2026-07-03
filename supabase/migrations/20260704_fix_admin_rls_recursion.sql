-- Migration: Fix infinite recursion in admin RLS policy on users table
-- The previous policy self-referenced users table. Use JWT claims instead.

-- 1. Drop the recursive policy
DROP POLICY IF EXISTS "Admins can read all users" ON users;

-- 2. Recreate using JWT claims (avoids self-referencing the users table)
--    The role is stored in auth.users.raw_user_meta_data during signup
--    and is accessible via auth.jwt() -> 'user_metadata' ->> 'role'
CREATE POLICY "Admins can read all users" ON users FOR SELECT USING (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
);
