-- Allow the order owner (customer) to create a delivery for their own order.
-- Without this, placing an order fails with:
--   "new row violates row-level security policy for table \"deliveries\""
DROP POLICY IF EXISTS "Customers insert deliveries for own orders" ON public.deliveries;
CREATE POLICY "Customers insert deliveries for own orders" ON public.deliveries
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_id
        AND o.customer_id = auth.uid()
    )
  );
