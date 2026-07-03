-- Migration: Add CRUD policies on products table for admins
-- Only admins are allowed to insert, update, and delete products.

-- Enable RLS (just in case)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- 1. Insert Policy
CREATE POLICY "Admins can insert products" ON products FOR INSERT WITH CHECK (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
);

-- 2. Update Policy
CREATE POLICY "Admins can update products" ON products FOR UPDATE USING (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
) WITH CHECK (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
);

-- 3. Delete Policy
CREATE POLICY "Admins can delete products" ON products FOR DELETE USING (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
);
