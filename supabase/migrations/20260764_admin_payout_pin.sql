-- Admin-managed settings (e.g. payout approval PIN). Admin can set/reset
-- the PIN from the app instead of a fixed server secret.
CREATE TABLE IF NOT EXISTS public.app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Only staff can read settings; only staff can write.
DROP POLICY IF EXISTS "Staff read app_settings" ON public.app_settings;
CREATE POLICY "Staff read app_settings" ON public.app_settings
  FOR SELECT USING (public.is_staff());

DROP POLICY IF EXISTS "Staff write app_settings" ON public.app_settings;
CREATE POLICY "Staff write app_settings" ON public.app_settings
  FOR ALL USING (public.is_staff()) WITH CHECK (public.is_staff());

-- RPC: admin sets/reset the payout approval PIN.
CREATE OR REPLACE FUNCTION public.set_payout_pin(p_pin TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Only staff can set the approval PIN';
  END IF;
  IF p_pin IS NULL OR length(p_pin) < 4 THEN
    RAISE EXCEPTION 'PIN must be at least 4 characters';
  END IF;
  INSERT INTO public.app_settings (key, value, updated_by, updated_at)
    VALUES ('payout_approval_pin', p_pin, auth.uid(), now())
  ON CONFLICT (key) DO UPDATE
    SET value = EXCLUDED.value, updated_by = EXCLUDED.updated_by, updated_at = now();
END;
$$;

-- RPC: read the current PIN (staff only) for display/verification.
CREATE OR REPLACE FUNCTION public.get_payout_pin()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pin TEXT;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Only staff can read the approval PIN';
  END IF;
  SELECT value INTO v_pin FROM public.app_settings WHERE key = 'payout_approval_pin';
  RETURN v_pin;
END;
$$;
