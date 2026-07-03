-- Migration: Fix storage RLS policies for product-images bucket
-- The JWT 'user_metadata' claim approach was failing with 403 Unauthorized.
-- Use the same pattern as other working policies: query public.users table directly.
-- This avoids JWT claim timing issues (session may not have refreshed after user creation).

-- Drop the broken JWT-based policies
DROP POLICY IF EXISTS "Admins can upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can update product images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete product images" ON storage.objects;

-- Recreate using public.users role check (consistent with other RLS policies)
CREATE POLICY "Admins can upload product images" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'product-images' AND
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can update product images" ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'product-images' AND
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  ) WITH CHECK (
    bucket_id = 'product-images' AND
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can delete product images" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'product-images' AND
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );
