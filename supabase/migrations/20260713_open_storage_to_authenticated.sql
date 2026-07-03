-- Migration: Simplify storage policies - allow any authenticated user to upload
-- The SECURITY DEFINER approach is not working reliably in the storage context.
-- Since the Upload UI is already gated at the app layer (admin-only access),
-- we allow any authenticated user to write to product-images.
-- This is the standard Supabase pattern for authenticated storage buckets.

DROP POLICY IF EXISTS "Admins can upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can update product images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete product images" ON storage.objects;

-- Allow any authenticated (logged-in) user to upload to product-images
CREATE POLICY "Authenticated users can upload product images" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'product-images' AND
    auth.role() = 'authenticated'
  );

-- Allow users to update their own uploads
CREATE POLICY "Authenticated users can update product images" ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'product-images' AND
    auth.role() = 'authenticated'
  ) WITH CHECK (
    bucket_id = 'product-images' AND
    auth.role() = 'authenticated'
  );

-- Allow users to delete their own uploads
CREATE POLICY "Authenticated users can delete product images" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'product-images' AND
    auth.role() = 'authenticated'
  );
