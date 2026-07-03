-- Migration: Temporary RPC to inspect storage buckets
CREATE OR REPLACE FUNCTION public.get_storage_buckets()
RETURNS TABLE (id text, name text, public boolean)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT id::text, name::text, public::boolean
  FROM storage.buckets;
$$;
