-- RPC: Delete the calling user's account and all associated data
-- Runs with SECURITY DEFINER so the user can delete their own auth record
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  uid UUID;
BEGIN
  uid := auth.uid();
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- FCM push tokens
  DELETE FROM public.fcm_tokens WHERE user_id = uid;

  -- Reviews
  DELETE FROM public.reviews WHERE user_id = uid;

  -- Wishlists
  DELETE FROM public.wishlists WHERE user_id = uid;

  -- Property occupant links
  DELETE FROM public.property_occupants WHERE user_id = uid;

  -- Collection interactions
  DELETE FROM public.collection_follows WHERE user_id = uid;
  DELETE FROM public.collection_likes WHERE user_id = uid;

  -- Collections owned by user (cascades to collection_items)
  DELETE FROM public.collections WHERE creator_id = uid;

  -- Jobs: nullify worker assignments, delete customer jobs
  UPDATE public.jobs SET worker_id = NULL WHERE worker_id = uid;
  DELETE FROM public.jobs WHERE customer_id = uid;

  -- Properties managed by user (cascades to units → rooms → assets)
  DELETE FROM public.properties WHERE manager_id = uid;

  -- Remove user profile (should cascade from auth.users, but do it explicitly)
  DELETE FROM public.users WHERE id = uid;

  -- Remove the auth user (triggers cascade to public.users)
  DELETE FROM auth.users WHERE id = uid;
END;
$$;
