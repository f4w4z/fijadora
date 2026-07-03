-- Migration: Enable Realtime for the products table
-- The products stream in shop_repository.dart uses .stream() which requires
-- the table to be part of the supabase_realtime publication.
ALTER PUBLICATION supabase_realtime ADD TABLE products;
