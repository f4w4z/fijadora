-- Add RLS policy for admins/managers to read all jobs
CREATE POLICY "Admins can read all jobs" ON jobs FOR SELECT USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'manager'))
);
