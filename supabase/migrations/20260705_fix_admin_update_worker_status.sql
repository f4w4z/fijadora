-- Migration: Allow admins to update worker_status on any user
-- The previous "Users can update own profile" policy blocks admins
-- from approving/rejecting workers.

CREATE POLICY "Admins can update worker status" ON users FOR UPDATE USING (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
);
