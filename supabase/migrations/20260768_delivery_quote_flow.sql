-- Delivery quote flow: orders start with delivery_fee=0, staff sends a quote,
-- customer pays the full amount after accepting.

ALTER TABLE public.orders
  DROP CONSTRAINT IF EXISTS orders_status_check;

ALTER TABLE public.orders
  ADD CONSTRAINT orders_status_check CHECK (status IN (
    'pending', 'quote_sent', 'preparing', 'out_for_delivery', 'delivered',
    'cancelled', 'refunded',
    -- Legacy values kept for backward compatibility
    'paid', 'processing', 'shipped'
  ));
