-- Migration: Clean up temporary inspection RPCs
DROP FUNCTION IF EXISTS public.get_storage_policies();
DROP FUNCTION IF EXISTS public.get_storage_buckets();
