-- Fix storage RLS: restrict product-images writes to authenticated users
-- Previous attempts with admin-only (JWT claims + SECURITY DEFINER) failed
-- due to JWT propagation issues in the storage context.
-- Using auth.role() = 'authenticated' is reliable (built-in, no DB queries).

DROP POLICY IF EXISTS "Public Read Access to product images" ON storage.objects;
DROP POLICY IF EXISTS "Open Insert Access to product images" ON storage.objects;
DROP POLICY IF EXISTS "Open Update Access to product images" ON storage.objects;
DROP POLICY IF EXISTS "Open Delete Access to product images" ON storage.objects;

-- Bucket is public (bucket-level setting), so public URLs still work for read.
-- This RLS policy prevents unauthenticated API reads via the client SDK.
CREATE POLICY "Authenticated can read product images" ON storage.objects
  FOR SELECT USING (bucket_id = 'product-images' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated can upload product images" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'product-images' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated can update product images" ON storage.objects
  FOR UPDATE USING (bucket_id = 'product-images' AND auth.role() = 'authenticated')
  WITH CHECK (bucket_id = 'product-images' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated can delete product images" ON storage.objects
  FOR DELETE USING (bucket_id = 'product-images' AND auth.role() = 'authenticated');
