-- Migrate existing order status values to match Dart enum names
UPDATE public.orders SET status = 'preparing' WHERE status IN ('paid', 'processing');
UPDATE public.orders SET status = 'outForDelivery' WHERE status IN ('shipped', 'out_for_delivery');
UPDATE public.orders SET status = 'quoteSent' WHERE status = 'quote_sent';

-- Fix order status check constraint to match Dart enum values
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;
DO $$ BEGIN
  ALTER TABLE public.orders ADD CONSTRAINT orders_status_check CHECK (status IN (
    'pending', 'quoteSent', 'preparing', 'outForDelivery', 'delivered', 'cancelled', 'refunded'
  ));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Migrate existing delivery status values to match Dart enum names
UPDATE public.deliveries SET status = 'pickedUp' WHERE status = 'picked_up';
UPDATE public.deliveries SET status = 'inTransit' WHERE status = 'in_transit';

-- Fix delivery status check constraint to match Dart enum values
ALTER TABLE public.deliveries DROP CONSTRAINT IF EXISTS deliveries_status_check;
DO $$ BEGIN
  ALTER TABLE public.deliveries ADD CONSTRAINT deliveries_status_check CHECK (status IN (
    'pending', 'assigned', 'pickedUp', 'inTransit', 'delivered', 'failed'
  ));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
