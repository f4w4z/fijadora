-- Migration: Temporary RPC to inspect collections policies
CREATE OR REPLACE FUNCTION public.get_collections_policies()
RETURNS TABLE (policy_name text, cmd text, qual text, with_check text)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT policyname::text, cmd::text, qual::text, with_check::text
  FROM pg_policies
  WHERE tablename = 'collections' AND schemaname = 'public';
$$;
