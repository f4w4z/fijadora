-- Atomic job assignment: only assigns if job is still unassigned
-- Uses UPDATE ... WHERE status = 'pending' to prevent race conditions
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
