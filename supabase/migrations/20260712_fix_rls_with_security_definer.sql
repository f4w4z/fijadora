-- Migration: Fix storage and products RLS using a security-definer function
-- The EXISTS (SELECT 1 FROM public.users ...) approach fails because storage
-- runs in a context where the users table SELECT is itself RLS-protected.
-- Solution: create a SECURITY DEFINER function that reads auth.users directly,
-- bypassing the public.users RLS entirely.

-- 1. Create a helper function that checks if the current user is an admin
--    by reading raw_user_meta_data from auth.users (bypasses public.users RLS)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' = 'admin'
  );
$$;

-- 2. Fix storage RLS: drop the broken public.users-based policies
DROP POLICY IF EXISTS "Admins can upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can update product images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete product images" ON storage.objects;

-- 3. Recreate storage policies using the security-definer function
CREATE POLICY "Admins can upload product images" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'product-images' AND public.is_admin()
  );

CREATE POLICY "Admins can update product images" ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'product-images' AND public.is_admin()
  ) WITH CHECK (
    bucket_id = 'product-images' AND public.is_admin()
  );

CREATE POLICY "Admins can delete product images" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'product-images' AND public.is_admin()
  );

-- 4. Fix products table RLS the same way
DROP POLICY IF EXISTS "Admins can insert products" ON products;
DROP POLICY IF EXISTS "Admins can update products" ON products;
DROP POLICY IF EXISTS "Admins can delete products" ON products;

CREATE POLICY "Admins can insert products" ON products
  FOR INSERT
  WITH CHECK (public.is_admin());

CREATE POLICY "Admins can update products" ON products
  FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "Admins can delete products" ON products
  FOR DELETE
  USING (public.is_admin());
