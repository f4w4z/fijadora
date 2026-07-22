-- ═══════════════════════════════════════════════════════════════
-- RLS + triggers for commerce / wallet / announcement tables
-- Roles: customer, worker, admin, manager
-- ═══════════════════════════════════════════════════════════════

-- Helper: is the current user staff (admin/manager)?
CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid()
      AND role IN ('admin', 'manager')
  );
$$;

-- ── Announcements ──
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone authenticated can read announcements" ON public.announcements;
CREATE POLICY "Anyone authenticated can read announcements" ON public.announcements
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Staff can manage announcements" ON public.announcements;
CREATE POLICY "Staff can manage announcements" ON public.announcements
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ── Orders ──
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Customers read own orders" ON public.orders;
CREATE POLICY "Customers read own orders" ON public.orders
  FOR SELECT USING (auth.uid() = customer_id OR public.is_staff());

DROP POLICY IF EXISTS "Customers create own orders" ON public.orders;
CREATE POLICY "Customers create own orders" ON public.orders
  FOR INSERT WITH CHECK (auth.uid() = customer_id);

DROP POLICY IF EXISTS "Staff update orders" ON public.orders;
CREATE POLICY "Staff update orders" ON public.orders
  FOR UPDATE USING (public.is_staff()) WITH CHECK (public.is_staff());

-- ── Order items ──
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Order items readable by owner or staff" ON public.order_items;
CREATE POLICY "Order items readable by owner or staff" ON public.order_items
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_id AND (o.customer_id = auth.uid() OR public.is_staff()))
  );

DROP POLICY IF EXISTS "Order items insertable with order" ON public.order_items;
CREATE POLICY "Order items insertable with order" ON public.order_items
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_id AND o.customer_id = auth.uid())
  );

-- ── Deliveries ──
ALTER TABLE public.deliveries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Deliveries readable by owner or staff or assigned worker" ON public.deliveries;
CREATE POLICY "Deliveries readable by owner or staff or assigned worker" ON public.deliveries
  FOR SELECT USING (
    public.is_staff()
    OR assigned_worker_id = auth.uid()
    OR EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_id AND o.customer_id = auth.uid())
  );

DROP POLICY IF EXISTS "Staff manage deliveries" ON public.deliveries;
CREATE POLICY "Staff manage deliveries" ON public.deliveries
  FOR ALL USING (public.is_staff()) WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS "Assigned worker updates delivery status" ON public.deliveries;
CREATE POLICY "Assigned worker updates delivery status" ON public.deliveries
  FOR UPDATE USING (assigned_worker_id = auth.uid()) WITH CHECK (assigned_worker_id = auth.uid());

-- ── Item requests ──
ALTER TABLE public.item_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Customers read own requests" ON public.item_requests;
CREATE POLICY "Customers read own requests" ON public.item_requests
  FOR SELECT USING (auth.uid() = customer_id OR public.is_staff());

DROP POLICY IF EXISTS "Customers create own requests" ON public.item_requests;
CREATE POLICY "Customers create own requests" ON public.item_requests
  FOR INSERT WITH CHECK (auth.uid() = customer_id);

DROP POLICY IF EXISTS "Staff manage requests" ON public.item_requests;
CREATE POLICY "Staff manage requests" ON public.item_requests
  FOR UPDATE USING (public.is_staff()) WITH CHECK (public.is_staff());

-- ── Worker wallets ──
ALTER TABLE public.worker_wallets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Workers read own wallet" ON public.worker_wallets;
CREATE POLICY "Workers read own wallet" ON public.worker_wallets
  FOR SELECT USING (worker_id = auth.uid() OR public.is_staff());

DROP POLICY IF EXISTS "Staff manage wallets" ON public.worker_wallets;
CREATE POLICY "Staff manage wallets" ON public.worker_wallets
  FOR ALL USING (public.is_staff()) WITH CHECK (public.is_staff());

-- ── Wallet transactions ──
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Wallet tx readable by worker or staff" ON public.wallet_transactions;
CREATE POLICY "Wallet tx readable by worker or staff" ON public.wallet_transactions
  FOR SELECT USING (worker_id = auth.uid() OR public.is_staff());

-- ── Payouts ──
ALTER TABLE public.payouts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Payouts readable by worker or staff" ON public.payouts;
CREATE POLICY "Payouts readable by worker or staff" ON public.payouts
  FOR SELECT USING (worker_id = auth.uid() OR public.is_staff());

DROP POLICY IF EXISTS "Workers create own payouts" ON public.payouts;
CREATE POLICY "Workers create own payouts" ON public.payouts
  FOR INSERT WITH CHECK (worker_id = auth.uid());

DROP POLICY IF EXISTS "Staff manage payouts" ON public.payouts;
CREATE POLICY "Staff manage payouts" ON public.payouts
  FOR ALL USING (public.is_staff()) WITH CHECK (public.is_staff());

-- ── Paystack payments ──
ALTER TABLE public.paystack_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Payments readable by customer or staff" ON public.paystack_payments;
CREATE POLICY "Payments readable by customer or staff" ON public.paystack_payments
  FOR SELECT USING (customer_id = auth.uid() OR public.is_staff());

DROP POLICY IF EXISTS "Payments insertable by customer" ON public.paystack_payments;
CREATE POLICY "Payments insertable by customer" ON public.paystack_payments
  FOR INSERT WITH CHECK (customer_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════
-- Triggers
-- ═══════════════════════════════════════════════════════════════

-- Auto-create a wallet for any newly approved worker
CREATE OR REPLACE FUNCTION public.ensure_worker_wallet()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.role = 'worker' AND (OLD.role IS DISTINCT FROM 'worker') THEN
    INSERT INTO public.worker_wallets (worker_id)
    VALUES (NEW.id)
    ON CONFLICT (worker_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS ensure_worker_wallet ON public.users;
CREATE TRIGGER ensure_worker_wallet
  AFTER INSERT OR UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.ensure_worker_wallet();

-- updated_at maintenance for orders/deliveries/item_requests/payouts
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS touch_orders ON public.orders;
CREATE TRIGGER touch_orders BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS touch_deliveries ON public.deliveries;
CREATE TRIGGER touch_deliveries BEFORE UPDATE ON public.deliveries
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS touch_item_requests ON public.item_requests;
CREATE TRIGGER touch_item_requests BEFORE UPDATE ON public.item_requests
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS touch_payouts ON public.payouts;
CREATE TRIGGER touch_payouts BEFORE UPDATE ON public.payouts
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- Wallet balance auto-updates from ledger
CREATE OR REPLACE FUNCTION public.apply_wallet_transaction()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_delta NUMERIC(12,2);
BEGIN
  v_delta := CASE NEW.type
    WHEN 'credit' THEN NEW.amount
    WHEN 'adjustment' THEN NEW.amount
    WHEN 'debit' THEN -NEW.amount
    WHEN 'payout' THEN -NEW.amount
    ELSE 0
  END;
  UPDATE public.worker_wallets
    SET balance = GREATEST(0, balance + v_delta), updated_at = now()
    WHERE id = NEW.wallet_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS apply_wallet_transaction ON public.wallet_transactions;
CREATE TRIGGER apply_wallet_transaction
  AFTER INSERT ON public.wallet_transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.apply_wallet_transaction();
