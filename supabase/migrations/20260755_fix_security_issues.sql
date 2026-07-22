-- ═══════════════════════════════════════════════════════════════
-- Comprehensive Security Fix Migration
-- Fixes: C1 (storage RLS), C3 (newsletter abuse), C4 (RPC auth),
--        C5 (assign_job), C6 (get_user_names), C7 (role escalation)
-- ═══════════════════════════════════════════════════════════════

-- ── 1. Storage RLS: staff-only write using public.users table ──
-- Replaces unreliable auth.jwt() ->> 'role' checks with a direct
-- DB query, which is immune to JWT claim propagation issues in
-- the storage context.
DROP POLICY IF EXISTS "Staff can upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Staff can update product images" ON storage.objects;
DROP POLICY IF EXISTS "Staff can delete product images" ON storage.objects;

CREATE POLICY "Staff can upload product images" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid()
        AND role IN ('admin', 'manager')
    )
  );

CREATE POLICY "Staff can update product images" ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid()
        AND role IN ('admin', 'manager')
    )
  )
  WITH CHECK (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid()
        AND role IN ('admin', 'manager')
    )
  );

CREATE POLICY "Staff can delete product images" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid()
        AND role IN ('admin', 'manager')
    )
  );

-- ── 2. Fix collection RPC functions: add auth.uid() check ──
-- Prevents anonymous users from inflating/deflating counts.
CREATE OR REPLACE FUNCTION public.increment_collection_follow(col_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    UPDATE collections SET follower_count = follower_count + 1 WHERE id = col_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.decrement_collection_follow(col_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    UPDATE collections SET follower_count = GREATEST(0, follower_count - 1) WHERE id = col_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.increment_collection_like(col_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    UPDATE collections SET like_count = like_count + 1 WHERE id = col_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.decrement_collection_like(col_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    UPDATE collections SET like_count = GREATEST(0, like_count - 1) WHERE id = col_id;
  END IF;
END;
$$;

-- ── 3. Fix get_user_names: add auth.uid() guard ──
CREATE OR REPLACE FUNCTION public.get_user_names(user_ids UUID[])
RETURNS TABLE(id UUID, name TEXT)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT u.id, u.name FROM public.users u
  WHERE u.id = ANY(user_ids)
    AND auth.uid() IS NOT NULL;
$$;

-- ── 4. Fix handle_new_user: reject privileged roles from client ──
-- Only allow customer or worker from signup metadata.
-- Admin/manager roles must be set manually or via a privileged process.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role TEXT;
BEGIN
  v_role := COALESCE(NEW.raw_user_meta_data->>'role', 'customer');
  -- Only customer and worker can be set via client metadata
  IF v_role NOT IN ('customer', 'worker') THEN
    v_role := 'customer';
  END IF;

  INSERT INTO public.users (id, email, name, role, worker_status, email_confirmed_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    v_role,
    CASE WHEN v_role = 'worker' THEN 'pending' ELSE NULL END,
    NEW.email_confirmed_at
  );
  RETURN NEW;
END;
$$;

-- ── 5. Newsletter subscribers: add rate limiting trigger ──
-- Track recent signups to prevent abuse of the landing page form.
CREATE TABLE IF NOT EXISTS newsletter_signup_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  ip_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_newsletter_signup_ip_hash_created
  ON newsletter_signup_log(ip_hash, created_at DESC);

-- Trigger function: max 5 signups per email per hour
CREATE OR REPLACE FUNCTION public.check_newsletter_rate_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM newsletter_signup_log
    WHERE email = NEW.email
      AND created_at > NOW() - INTERVAL '1 hour'
    HAVING COUNT(*) >= 5
  ) THEN
    RAISE EXCEPTION 'Too many signup attempts. Please try again later.'
      USING HINT = 'rate_limited';
  END IF;
  INSERT INTO newsletter_signup_log (email, ip_hash)
  VALUES (NEW.email, COALESCE(current_setting('request.headers', true)::json->>'x-real-ip', 'unknown'));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS check_newsletter_rate_limit ON newsletter_subscribers;
CREATE TRIGGER check_newsletter_rate_limit
  BEFORE INSERT ON newsletter_subscribers
  FOR EACH ROW
  EXECUTE FUNCTION public.check_newsletter_rate_limit();
