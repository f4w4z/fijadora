-- Migration: Temporary RPC to inspect storage policies
CREATE OR REPLACE FUNCTION public.get_storage_policies()
RETURNS TABLE (policy_name text, cmd text, qual text, with_check text)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT policyname::text, cmd::text, qual::text, with_check::text
  FROM pg_policies
  WHERE tablename = 'objects' AND schemaname = 'storage';
$$;
