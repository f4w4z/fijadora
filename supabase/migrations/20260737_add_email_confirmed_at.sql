-- Add email_confirmed_at to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS email_confirmed_at TIMESTAMPTZ;

-- Update handle_new_user trigger to include email_confirmed_at
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role, worker_status, email_confirmed_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer'),
    CASE WHEN NEW.raw_user_meta_data->>'role' = 'worker' THEN 'pending' ELSE NULL END,
    NEW.email_confirmed_at
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
