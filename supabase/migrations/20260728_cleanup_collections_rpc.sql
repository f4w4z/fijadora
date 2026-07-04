-- Migration: Clean up temporary collections inspection RPC
DROP FUNCTION IF EXISTS public.get_collections_policies();
