-- ═══════════════════════════════════════════════════════════════
-- Fijadora Commerce + Worker Wallet + Announcements
-- New tables:
--   announcements        (product-upload broadcast feed)
--   orders / order_items (Amazon-style purchases)
--   deliveries           (delivery tracking + fee)
--   item_requests        (customer requests for out-of-shop items)
--   worker_wallets       (credit balance per worker)
--   wallet_transactions  (wallet ledger)
--   payouts              (worker withdrawal requests via Paystack)
--   paystack_payments    (payment reference ledger)
-- ═══════════════════════════════════════════════════════════════

-- ── Announcements (in-app feed + push to customers) ──
CREATE TABLE IF NOT EXISTS public.announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  image_url TEXT,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_announcements_created_at
  ON public.announcements (created_at DESC);

-- ── Orders (customer purchases) ──
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'paid', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded'
  )),
  subtotal NUMERIC(12,2) NOT NULL DEFAULT 0,
  delivery_fee NUMERIC(12,2) NOT NULL DEFAULT 0,
  total NUMERIC(12,2) NOT NULL DEFAULT 0,
  delivery_address TEXT NOT NULL,
  delivery_phone TEXT,
  delivery_note TEXT,
  paystack_reference TEXT UNIQUE,
  paystack_paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON public.orders (customer_id, created_at DESC);

-- ── Order items ──
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  unit_price NUMERIC(12,2) NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  image_url TEXT
);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items (order_id);

-- ── Deliveries ──
CREATE TABLE IF NOT EXISTS public.deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'assigned', 'picked_up', 'in_transit', 'delivered', 'failed'
  )),
  assigned_worker_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  tracking_note TEXT,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_deliveries_order ON public.deliveries (order_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_worker ON public.deliveries (assigned_worker_id, status);

-- ── Item requests (customer wants something not in shop) ──
CREATE TABLE IF NOT EXISTS public.item_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT,
  image_url TEXT,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN (
    'open', 'reviewing', 'fulfilled', 'rejected', 'closed'
  )),
  linked_product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  reviewed_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_item_requests_customer ON public.item_requests (customer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_item_requests_status ON public.item_requests (status);

-- ── Worker wallets (credit system) ──
CREATE TABLE IF NOT EXISTS public.worker_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  balance NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
  bank_name TEXT,
  bank_account_number TEXT,
  bank_account_name TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Wallet transactions (ledger) ──
CREATE TABLE IF NOT EXISTS public.wallet_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES public.worker_wallets(id) ON DELETE CASCADE,
  worker_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN (
    'credit', 'debit', 'payout', 'adjustment'
  )),
  amount NUMERIC(12,2) NOT NULL,
  reference TEXT,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_wallet ON public.wallet_transactions (wallet_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_worker ON public.wallet_transactions (worker_id, created_at DESC);

-- ── Payouts (withdrawal requests) ──
CREATE TABLE IF NOT EXISTS public.payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  wallet_id UUID NOT NULL REFERENCES public.worker_wallets(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'approved', 'processing', 'completed', 'rejected'
  )),
  paystack_transfer_reference TEXT,
  paystack_recipient_code TEXT,
  bank_name TEXT,
  bank_account_number TEXT,
  bank_account_name TEXT,
  reviewed_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_payouts_worker ON public.payouts (worker_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON public.payouts (status);

-- ── Paystack payment ledger ──
CREATE TABLE IF NOT EXISTS public.paystack_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reference TEXT NOT NULL UNIQUE,
  customer_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  amount NUMERIC(12,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'NGN',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'success', 'failed', 'abandoned'
  )),
  gateway_response TEXT,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_paystack_payments_order ON public.paystack_payments (order_id);
