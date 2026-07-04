-- RLS fixes: authorization, missing policies, consistency

-- 1. Create is_admin_or_manager() helper (like is_admin() but includes managers)
CREATE OR REPLACE FUNCTION public.is_admin_or_manager()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' IN ('admin', 'manager')
  );
$$;

-- 2. Fix reviews: add UPDATE and DELETE policies
CREATE POLICY "Users can update own reviews" ON reviews
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own reviews" ON reviews
  FOR DELETE USING (auth.uid() = user_id);

-- 3. Fix jobs: add DELETE policies
CREATE POLICY "Customers can delete own jobs" ON jobs
  FOR DELETE USING (auth.uid() = customer_id);
CREATE POLICY "Admins can delete any job" ON jobs
  FOR DELETE USING (public.is_admin_or_manager());

-- 4. Migrate jobs admin policies to use is_admin_or_manager() (recursion-safe)
DROP POLICY IF EXISTS "Admins can read all jobs" ON jobs;
DROP POLICY IF EXISTS "Admins can update any job" ON jobs;
DROP POLICY IF EXISTS "Admins can insert jobs" ON jobs;

CREATE POLICY "Admins can read all jobs" ON jobs
  FOR SELECT USING (public.is_admin_or_manager());
CREATE POLICY "Admins can update any job" ON jobs
  FOR UPDATE USING (public.is_admin_or_manager());
CREATE POLICY "Admins can insert jobs" ON jobs
  FOR INSERT WITH CHECK (public.is_admin_or_manager());

-- 5. Fix property_occupants: add admin SELECT policy
CREATE POLICY "Admins can read all occupants" ON property_occupants
  FOR SELECT USING (public.is_admin());

-- 6. Fix assign_job: add authorization check
CREATE OR REPLACE FUNCTION public.assign_job(
  p_job_id UUID,
  p_worker_id UUID
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  IF NOT (
    (auth.uid() = p_worker_id AND EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'worker' AND worker_status = 'approved'
    ))
    OR public.is_admin_or_manager()
  ) THEN
    RAISE EXCEPTION 'Not authorized' USING HINT = 'unauthorized';
  END IF;

  UPDATE public.jobs
  SET worker_id = p_worker_id, status = 'assigned', updated_at = NOW()
  WHERE id = p_job_id
    AND (status IS NULL OR status = 'pending')
  RETURNING to_jsonb(public.jobs.*) INTO v_result;

  IF v_result IS NULL THEN
    RAISE EXCEPTION 'Job is already assigned or completed' USING HINT = 'grab_failed';
  END IF;

  RETURN v_result;
END;
$$;
