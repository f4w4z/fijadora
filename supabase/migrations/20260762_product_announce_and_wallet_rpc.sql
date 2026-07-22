-- ═══════════════════════════════════════════════════════════════
-- Product-upload announcement: create an in-app announcement row and
-- fire a push notification to all customer_app users.
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.notify_product_upload()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_announcement_id UUID;
BEGIN
  -- Only announce when a product is freshly created (not on every update)
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.announcements (title, body, image_url, product_id, created_by)
    VALUES (
      'New product: ' || NEW.name,
      'We just added "' || NEW.name || '" to the shop. Tap to view it now!',
      NEW.image_url,
      NEW.id,
      NEW.created_at  -- placeholder; real creator set by app layer
    )
    RETURNING id INTO v_announcement_id;
    -- Push to customers is fired from the app layer (PushNotificationService)
    -- after a successful product insert, so we don't depend on pg_net here.
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS notify_product_upload ON public.products;
CREATE TRIGGER notify_product_upload
  AFTER INSERT ON public.products
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_product_upload();

-- ── RPC: credit a worker's wallet (called by staff on job completion) ──
CREATE OR REPLACE FUNCTION public.credit_worker_wallet(
  p_worker_id UUID,
  p_amount NUMERIC,
  p_description TEXT DEFAULT NULL,
  p_reference TEXT DEFAULT NULL
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_wallet_id UUID;
  v_new_balance NUMERIC(12,2);
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Only staff can credit worker wallets';
  END IF;
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive';
  END IF;

  INSERT INTO public.worker_wallets (worker_id)
  VALUES (p_worker_id)
  ON CONFLICT (worker_id) DO NOTHING;

  SELECT id INTO v_wallet_id FROM public.worker_wallets WHERE worker_id = p_worker_id;

  INSERT INTO public.wallet_transactions (wallet_id, worker_id, type, amount, reference, description)
  VALUES (v_wallet_id, p_worker_id, 'credit', p_amount, p_reference, p_description);

  SELECT balance INTO v_new_balance FROM public.worker_wallets WHERE id = v_wallet_id;
  RETURN v_new_balance;
END;
$$;

-- ── RPC: approve a payout (staff). Deducts from wallet via ledger. ──
CREATE OR REPLACE FUNCTION public.approve_payout(
  p_payout_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_worker UUID;
  v_wallet UUID;
  v_amount NUMERIC(12,2);
  v_existing TEXT;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Only staff can approve payouts';
  END IF;

  SELECT worker_id, wallet_id, amount, status
    INTO v_worker, v_wallet, v_amount, v_existing
  FROM public.payouts WHERE id = p_payout_id;

  IF v_existing IS DISTINCT FROM 'pending' THEN
    RAISE EXCEPTION 'Payout already processed';
  END IF;

  INSERT INTO public.wallet_transactions (wallet_id, worker_id, type, amount, reference, description)
  VALUES (v_wallet, v_worker, 'payout', v_amount, p_payout_id::text, 'Withdrawal payout');

  UPDATE public.payouts
    SET status = 'approved', reviewed_by = auth.uid(), reviewed_at = now()
  WHERE id = p_payout_id;
END;
$$;
