-- Add commerce / wallet tables to the realtime publication so .stream() works.
-- Idempotent: skip tables already in the publication.
DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'public.announcements',
    'public.orders',
    'public.order_items',
    'public.deliveries',
    'public.item_requests',
    'public.worker_wallets',
    'public.wallet_transactions',
    'public.payouts',
    'public.paystack_payments'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = split_part(t, '.', 1)
        AND tablename = split_part(t, '.', 2)
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE %s', t);
    END IF;
  END LOOP;
END $$;
