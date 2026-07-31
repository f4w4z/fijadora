-- ═══════════════════════════════════════════════════════════════
-- Service pricing: quotes, deposits, change orders, worker payouts
-- Flow:
--   pending → staff sends quote (send_job_quote) → quoted
--   customer pays deposit (paystack verify) → deposit_paid
--   staff assigns worker (assign_job, deposit required) → assigned
--   worker submits change order (submit_change_order) → onHold
--   staff approves (approve_change_order) → inProgress
--   customer pays change order (paystack verify) → paid flag
--   worker completes → waitingApproval → staff finalizes (finalize_job)
--     → completed + balance_due
--   customer pays balance (paystack verify) → credit_job_earnings
--     → payment_status = paid + worker wallet credited
-- ═══════════════════════════════════════════════════════════════

-- ── 1. Money columns on jobs ────────────────────────────────────
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS quote_amount NUMERIC(12,2),
  ADD COLUMN IF NOT EXISTS deposit_amount NUMERIC(12,2),
  ADD COLUMN IF NOT EXISTS max_amount NUMERIC(12,2),
  ADD COLUMN IF NOT EXISTS change_orders JSONB NOT NULL DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS final_amount NUMERIC(12,2),
  ADD COLUMN IF NOT EXISTS payment_status TEXT NOT NULL DEFAULT 'none',
  ADD COLUMN IF NOT EXISTS paystack_reference TEXT;

ALTER TABLE public.jobs
  DROP CONSTRAINT IF EXISTS jobs_payment_status_check;
ALTER TABLE public.jobs
  ADD CONSTRAINT jobs_payment_status_check
    CHECK (payment_status IN ('none','deposit_paid','balance_due','paid'));

-- Money columns can only be written by SECURITY DEFINER RPCs (staff quote,
-- service-role payment flow) — never directly from client JWTs.
REVOKE UPDATE (
  quote_amount, deposit_amount, max_amount, change_orders,
  final_amount, payment_status, paystack_reference
) ON public.jobs FROM anon, authenticated;

-- ── 2. Job payments ledger ──────────────────────────────────────
-- Written by the paystack edge function (service role) after verified
-- payments. UNIQUE paystack_reference makes the flow idempotent.
CREATE TABLE IF NOT EXISTS public.job_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK (kind IN ('deposit','change_order','balance')),
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  status TEXT NOT NULL DEFAULT 'paid' CHECK (status IN ('paid','pending','refunded')),
  paystack_reference TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_job_payments_job ON public.job_payments (job_id, created_at DESC);

ALTER TABLE public.job_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Job payments readable by owner worker or staff" ON public.job_payments;
CREATE POLICY "Job payments readable by owner worker or staff" ON public.job_payments
  FOR SELECT USING (
    public.is_staff()
    OR EXISTS (SELECT 1 FROM public.jobs j WHERE j.id = job_id AND j.customer_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.jobs j WHERE j.id = job_id AND j.worker_id = auth.uid())
  );

DROP POLICY IF EXISTS "Staff insert job payments" ON public.job_payments;
CREATE POLICY "Staff insert job payments" ON public.job_payments
  FOR INSERT WITH CHECK (public.is_staff());

-- Link paystack payments to jobs as well as orders
ALTER TABLE public.paystack_payments
  ADD COLUMN IF NOT EXISTS job_id UUID REFERENCES public.jobs(id) ON DELETE SET NULL;

-- ── 3. Pricing config (tunable per trade) ───────────────────────
CREATE TABLE IF NOT EXISTS public.service_pricing_config (
  trade_type TEXT PRIMARY KEY CHECK (trade_type IN (
    'interiorDesign','electrical','plumbing','masonry','tiling',
    'designConsultation','acEngineering','kitchenDesigns','cleaning','gardening'
  )),
  worker_share_pct NUMERIC(5,2) NOT NULL DEFAULT 70,
  booking_fee NUMERIC(12,2) NOT NULL DEFAULT 20,
  deposit_pct NUMERIC(5,2) NOT NULL DEFAULT 30,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO public.service_pricing_config (trade_type, worker_share_pct, booking_fee, deposit_pct) VALUES
  ('interiorDesign',     70, 20, 30),
  ('electrical',         70, 20, 30),
  ('plumbing',           70, 20, 30),
  ('masonry',            70, 20, 30),
  ('tiling',             70, 20, 30),
  ('designConsultation', 70, 20, 30),
  ('acEngineering',      70, 20, 30),
  ('kitchenDesigns',     70, 20, 30),
  ('cleaning',           70, 20, 30),
  ('gardening',          70, 20, 30)
ON CONFLICT (trade_type) DO NOTHING;

ALTER TABLE public.service_pricing_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Pricing config readable by authenticated" ON public.service_pricing_config;
CREATE POLICY "Pricing config readable by authenticated" ON public.service_pricing_config
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Staff manage pricing config" ON public.service_pricing_config;
CREATE POLICY "Staff manage pricing config" ON public.service_pricing_config
  FOR ALL USING (public.is_staff()) WITH CHECK (public.is_staff());

-- ── 4. RPC: staff sends a quote (deposit auto-computed from config) ──
CREATE OR REPLACE FUNCTION public.send_job_quote(
  p_job_id UUID,
  p_amount NUMERIC,
  p_max_amount NUMERIC DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_job public.jobs%ROWTYPE;
  v_cfg public.service_pricing_config%ROWTYPE;
  v_deposit NUMERIC(12,2);
  v_result JSONB;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Only staff can send quotes';
  END IF;

  SELECT * INTO v_job FROM public.jobs WHERE id = p_job_id;
  IF v_job.id IS NULL THEN RAISE EXCEPTION 'Job not found'; END IF;
  IF v_job.status <> 'pending' THEN RAISE EXCEPTION 'Only pending jobs can be quoted'; END IF;
  IF p_amount <= 0 THEN RAISE EXCEPTION 'Invalid quote amount'; END IF;
  IF p_max_amount IS NOT NULL AND p_max_amount < p_amount THEN
    RAISE EXCEPTION 'Max amount must be at least the quote amount';
  END IF;

  SELECT * INTO v_cfg FROM public.service_pricing_config WHERE trade_type = v_job.trade_type;
  v_deposit := coalesce(v_cfg.booking_fee, 0) + round(p_amount * coalesce(v_cfg.deposit_pct, 30) / 100, 2);

  UPDATE public.jobs
  SET quote_amount = p_amount,
      max_amount = coalesce(p_max_amount, p_amount),
      deposit_amount = v_deposit,
      status = 'quoted'
  WHERE id = p_job_id
  RETURNING to_jsonb(public.jobs.*) INTO v_result;

  RETURN v_result;
END;
$$;

-- ── 5. RPC: worker submits a change order (job pauses) ───────────
CREATE OR REPLACE FUNCTION public.submit_change_order(
  p_job_id UUID,
  p_description TEXT,
  p_amount NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_job public.jobs%ROWTYPE;
  v_co JSONB;
BEGIN
  SELECT * INTO v_job FROM public.jobs WHERE id = p_job_id;
  IF v_job.id IS NULL THEN RAISE EXCEPTION 'Job not found'; END IF;
  IF auth.uid() IS NULL OR v_job.worker_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Only the assigned worker can submit change orders';
  END IF;
  IF p_amount <= 0 OR p_description IS NULL OR trim(p_description) = '' THEN
    RAISE EXCEPTION 'Change order needs a description and a positive amount';
  END IF;
  IF v_job.status IN ('completed','rejected','cancelled') THEN
    RAISE EXCEPTION 'Job is no longer active';
  END IF;

  v_co := jsonb_build_object(
    'id', gen_random_uuid()::text,
    'description', p_description,
    'amount', p_amount,
    'status', 'pending',
    'created_at', now()
  );

  UPDATE public.jobs
  SET change_orders = change_orders || jsonb_build_array(v_co),
      status = 'onHold'
  WHERE id = p_job_id;

  RETURN v_co;
END;
$$;

-- ── 6. RPC: staff approves a change order (job resumes) ──────────
CREATE OR REPLACE FUNCTION public.approve_change_order(
  p_job_id UUID,
  p_change_order_id TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_job public.jobs%ROWTYPE;
  v_new JSONB := '[]'::jsonb;
  v_elem JSONB;
  v_found BOOLEAN := false;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Only staff can approve change orders';
  END IF;

  SELECT * INTO v_job FROM public.jobs WHERE id = p_job_id;
  IF v_job.id IS NULL THEN RAISE EXCEPTION 'Job not found'; END IF;

  FOR v_elem IN SELECT * FROM jsonb_array_elements(v_job.change_orders) LOOP
    IF v_elem->>'id' = p_change_order_id THEN
      IF v_elem->>'status' <> 'pending' THEN RAISE EXCEPTION 'Change order is not pending'; END IF;
      v_new := v_new || jsonb_build_array(v_elem || jsonb_build_object(
        'status', 'approved',
        'approved_at', now()
      ));
      v_found := true;
    ELSE
      v_new := v_new || jsonb_build_array(v_elem);
    END IF;
  END LOOP;

  IF NOT v_found THEN RAISE EXCEPTION 'Change order not found'; END IF;

  UPDATE public.jobs
  SET change_orders = v_new,
      status = CASE WHEN status = 'onHold' THEN 'inProgress' ELSE status END
  WHERE id = p_job_id;
END;
$$;

-- ── 7. RPC: mark a change order paid (called by payment flow) ────
-- Only proceeds if a matching job_payments ledger row was just created
-- by the verified payment path (service role), so the paid flag can
-- never be forged from a client JWT.
CREATE OR REPLACE FUNCTION public.mark_change_order_paid(
  p_job_id UUID,
  p_change_order_id TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_job public.jobs%ROWTYPE;
  v_new JSONB := '[]'::jsonb;
  v_elem JSONB;
  v_found BOOLEAN := false;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.job_payments jp
    WHERE jp.job_id = p_job_id
      AND jp.kind = 'change_order'
      AND jp.status = 'paid'
      AND jp.paystack_reference IS NOT NULL
      AND jp.created_at > now() - interval '15 minutes'
  ) THEN
    RAISE EXCEPTION 'No recent payment recorded for this change order';
  END IF;

  SELECT * INTO v_job FROM public.jobs WHERE id = p_job_id;
  IF v_job.id IS NULL THEN RAISE EXCEPTION 'Job not found'; END IF;

  FOR v_elem IN SELECT * FROM jsonb_array_elements(v_job.change_orders) LOOP
    IF v_elem->>'id' = p_change_order_id THEN
      IF v_elem->>'status' <> 'approved' THEN RAISE EXCEPTION 'Change order is not approved'; END IF;
      v_new := v_new || jsonb_build_array(v_elem || jsonb_build_object(
        'status', 'paid',
        'paid_at', now()
      ));
      v_found := true;
    ELSE
      v_new := v_new || jsonb_build_array(v_elem);
    END IF;
  END LOOP;

  IF NOT v_found THEN RAISE EXCEPTION 'Change order not found'; END IF;

  UPDATE public.jobs SET change_orders = v_new WHERE id = p_job_id;
END;
$$;

-- ── 8. RPC: staff finalizes a completed job ─────────────────────
-- Sets final_amount (quote + approved paid change orders) and, when a
-- quote exists, moves the job to balance_due so the customer can pay.
CREATE OR REPLACE FUNCTION public.finalize_job(
  p_job_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_job public.jobs%ROWTYPE;
  v_total NUMERIC(12,2);
  v_delta NUMERIC(12,2) := 0;
  v_elem JSONB;
  v_result JSONB;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Only staff can finalize jobs';
  END IF;

  SELECT * INTO v_job FROM public.jobs WHERE id = p_job_id;
  IF v_job.id IS NULL THEN RAISE EXCEPTION 'Job not found'; END IF;
  IF v_job.status <> 'waitingApproval' THEN RAISE EXCEPTION 'Job is not awaiting approval'; END IF;

  IF v_job.quote_amount IS NULL THEN
    -- Legacy job without pricing: just mark completed
    UPDATE public.jobs SET status = 'completed'
    WHERE id = p_job_id
    RETURNING to_jsonb(public.jobs.*) INTO v_result;
    RETURN v_result;
  END IF;

  FOR v_elem IN SELECT * FROM jsonb_array_elements(v_job.change_orders) LOOP
    IF v_elem->>'status' = 'paid' THEN
      v_delta := v_delta + (v_elem->>'amount')::numeric;
    END IF;
  END LOOP;
  v_total := v_job.quote_amount + v_delta;

  UPDATE public.jobs
  SET status = 'completed',
      final_amount = v_total,
      payment_status = 'balance_due'
  WHERE id = p_job_id
  RETURNING to_jsonb(public.jobs.*) INTO v_result;

  RETURN v_result;
END;
$$;

-- ── 9. RPC: credit worker earnings after balance is paid ────────
-- Atomic: records the balance payment, credits the worker wallet with
-- their share, and marks the job paid. The amount check runs against
-- the verified Paystack payment so clients can never inflate earnings.
CREATE OR REPLACE FUNCTION public.credit_job_earnings(
  p_job_id UUID,
  p_reference TEXT
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_job public.jobs%ROWTYPE;
  v_cfg public.service_pricing_config%ROWTYPE;
  v_pay public.paystack_payments%ROWTYPE;
  v_total NUMERIC(12,2);
  v_delta NUMERIC(12,2) := 0;
  v_balance NUMERIC(12,2);
  v_share NUMERIC(12,2);
  v_wallet UUID;
  v_new_balance NUMERIC(12,2);
  v_elem JSONB;
BEGIN
  IF p_reference IS NULL OR trim(p_reference) = '' THEN
    RAISE EXCEPTION 'Payment reference required';
  END IF;

  SELECT * INTO v_job FROM public.jobs WHERE id = p_job_id;
  IF v_job.id IS NULL THEN RAISE EXCEPTION 'Job not found'; END IF;
  IF v_job.status <> 'completed' THEN RAISE EXCEPTION 'Job is not completed'; END IF;
  IF v_job.payment_status <> 'balance_due' THEN RAISE EXCEPTION 'Job is not awaiting balance payment'; END IF;

  SELECT * INTO v_pay FROM public.paystack_payments WHERE reference = p_reference;
  IF v_pay.status IS DISTINCT FROM 'success' THEN
    RAISE EXCEPTION 'Payment not verified';
  END IF;

  FOR v_elem IN SELECT * FROM jsonb_array_elements(v_job.change_orders) LOOP
    IF v_elem->>'status' = 'paid' THEN
      v_delta := v_delta + (v_elem->>'amount')::numeric;
    END IF;
  END LOOP;
  v_total := coalesce(v_job.quote_amount, 0) + v_delta;
  v_balance := v_total - coalesce(v_job.deposit_amount, 0);

  -- Mock-mode payments (dev) record amount 0; skip the amount check then.
  IF v_pay.amount < v_balance - 0.005
     AND coalesce(v_pay.gateway_response, '') NOT ILIKE 'Mock%' THEN
    RAISE EXCEPTION 'Payment amount does not cover the balance due';
  END IF;

  SELECT * INTO v_cfg FROM public.service_pricing_config WHERE trade_type = v_job.trade_type;
  v_share := round(v_total * coalesce(v_cfg.worker_share_pct, 70) / 100, 2);

  INSERT INTO public.worker_wallets (worker_id)
  VALUES (v_job.worker_id)
  ON CONFLICT (worker_id) DO NOTHING;

  SELECT id INTO v_wallet FROM public.worker_wallets WHERE worker_id = v_job.worker_id;

  INSERT INTO public.wallet_transactions (wallet_id, worker_id, type, amount, reference, description)
  VALUES (v_wallet, v_job.worker_id, 'credit', v_share, p_reference, 'Job payout: ' || v_job.id);

  INSERT INTO public.job_payments (job_id, kind, amount, status, paystack_reference)
  VALUES (p_job_id, 'balance', v_balance, 'paid', p_reference);

  UPDATE public.jobs
  SET payment_status = 'paid',
      final_amount = v_total,
      paystack_reference = p_reference
  WHERE id = p_job_id;

  SELECT balance INTO v_new_balance FROM public.worker_wallets WHERE id = v_wallet;
  RETURN v_new_balance;
END;
$$;

-- ── 10. Assign now requires deposit paid (when a quote exists) ───
CREATE OR REPLACE FUNCTION public.assign_job(
  p_job_id UUID,
  p_worker_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  UPDATE public.jobs
  SET worker_id = p_worker_id, status = 'assigned', updated_at = NOW()
  WHERE id = p_job_id
    AND (status IS NULL OR status IN ('pending', 'quoted'))
    AND (quote_amount IS NULL OR payment_status = 'deposit_paid')
  RETURNING to_jsonb(public.jobs.*) INTO v_result;

  IF v_result IS NULL THEN
    RAISE EXCEPTION 'Job is already assigned, completed, or awaiting deposit payment' USING HINT = 'grab_failed';
  END IF;

  RETURN v_result;
END;
$$;
