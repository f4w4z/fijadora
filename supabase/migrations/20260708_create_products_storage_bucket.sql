-- Migration: Create product-images storage bucket and configure admin RLS policies

-- 1. Create the bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Configure object upload policies for admin users
CREATE POLICY "Admins can upload product images" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'product-images' AND
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

-- 3. Configure object update policies for admin users
CREATE POLICY "Admins can update product images" ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'product-images' AND
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  ) WITH CHECK (
    bucket_id = 'product-images' AND
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

-- 4. Configure object delete policies for admin users
CREATE POLICY "Admins can delete product images" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'product-images' AND
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );
