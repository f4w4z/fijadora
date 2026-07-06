-- Migration: Restrict storage mutations to staff roles (admin/manager)
-- Previously any authenticated user could upload/update/delete product images.
-- Now only admin and manager roles have write access; all authenticated users can still read.

DROP POLICY IF EXISTS "Authenticated can upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated can update product images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated can delete product images" ON storage.objects;

-- Staff can upload product images
CREATE POLICY "Staff can upload product images" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
    AND auth.jwt() ->> 'role' IN ('admin', 'manager')
  );

-- Staff can update product images
CREATE POLICY "Staff can update product images" ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
    AND auth.jwt() ->> 'role' IN ('admin', 'manager')
  )
  WITH CHECK (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
    AND auth.jwt() ->> 'role' IN ('admin', 'manager')
  );

-- Staff can delete product images
CREATE POLICY "Staff can delete product images" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
    AND auth.jwt() ->> 'role' IN ('admin', 'manager')
  );
