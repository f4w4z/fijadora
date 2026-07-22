-- Add bank_code to payouts so staff only need an approval PIN (not bank details)
-- when releasing worker withdrawals via Paystack.
ALTER TABLE public.payouts ADD COLUMN IF NOT EXISTS bank_code TEXT;
