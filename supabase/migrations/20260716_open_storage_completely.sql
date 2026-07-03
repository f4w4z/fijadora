-- Migration: Make product-images storage bucket fully open for CRUD operations
-- This avoids any authentication/JWT token propagation issues between the app and Supabase storage.

DROP POLICY IF EXISTS "Authenticated users can upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update product images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete product images" ON storage.objects;

-- 1. Public Read Access (so everyone can view the product images)
CREATE POLICY "Public Read Access to product images" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'product-images');

-- 2. Open Insert Access
CREATE POLICY "Open Insert Access to product images" ON storage.objects
  FOR INSERT
  WITH CHECK (bucket_id = 'product-images');

-- 3. Open Update Access
CREATE POLICY "Open Update Access to product images" ON storage.objects
  FOR UPDATE
  USING (bucket_id = 'product-images')
  WITH CHECK (bucket_id = 'product-images');

-- 4. Open Delete Access
CREATE POLICY "Open Delete Access to product images" ON storage.objects
  FOR DELETE
  USING (bucket_id = 'product-images');
