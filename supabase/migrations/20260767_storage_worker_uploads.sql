-- Allow workers (and any authenticated user) to upload job proof photos to the
-- product-images bucket under the job_images/ folder. Product images at the
-- bucket root remain restricted to staff via the existing policies.
-- The role is stored in public.users, not in the JWT, so we can't rely on
-- auth.jwt() ->> 'role'. Instead we scope by the object path prefix.

DROP POLICY IF EXISTS "Workers can upload job images" ON storage.objects;
CREATE POLICY "Workers can upload job images" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
    AND (name LIKE 'job_images/%' OR name LIKE 'item_requests/%')
  );

DROP POLICY IF EXISTS "Workers can update job images" ON storage.objects;
CREATE POLICY "Workers can update job images" ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
    AND (name LIKE 'job_images/%' OR name LIKE 'item_requests/%')
  )
  WITH CHECK (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
    AND (name LIKE 'job_images/%' OR name LIKE 'item_requests/%')
  );
