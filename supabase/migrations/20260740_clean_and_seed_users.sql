-- Clean up existing users (cascade handles auth deletion if FK exists)
DELETE FROM public.users;

-- Seed 4 role users (password: Password1!)
-- Pre-computed bcrypt hash of 'Password1!' with 10 rounds
-- Customer
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at, confirmation_sent_at, is_sso_user)
VALUES (
  gen_random_uuid(),
  'customer@fijadora.com',
  '$2b$10$HAtwke5ELxV3ac7ugkdwPecN7eo9YmntAusvja.tJyxMuKhHdJtAe',
  now(),
  jsonb_build_object('name', 'Jane Customer', 'role', 'customer'),
  now(),
  now(),
  now(),
  false
);

-- Worker
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at, confirmation_sent_at, is_sso_user)
VALUES (
  gen_random_uuid(),
  'worker@fijadora.com',
  '$2b$10$HAtwke5ELxV3ac7ugkdwPecN7eo9YmntAusvja.tJyxMuKhHdJtAe',
  now(),
  jsonb_build_object('name', 'Will Worker', 'role', 'worker'),
  now(),
  now(),
  now(),
  false
);

-- Manager
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at, confirmation_sent_at, is_sso_user)
VALUES (
  gen_random_uuid(),
  'manager@fijadora.com',
  '$2b$10$HAtwke5ELxV3ac7ugkdwPecN7eo9YmntAusvja.tJyxMuKhHdJtAe',
  now(),
  jsonb_build_object('name', 'Sarah Manager', 'role', 'manager'),
  now(),
  now(),
  now(),
  false
);

-- Admin
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at, confirmation_sent_at, is_sso_user)
VALUES (
  gen_random_uuid(),
  'admin@fijadora.com',
  '$2b$10$HAtwke5ELxV3ac7ugkdwPecN7eo9YmntAusvja.tJyxMuKhHdJtAe',
  now(),
  jsonb_build_object('name', 'Adam Admin', 'role', 'admin'),
  now(),
  now(),
  now(),
  false
);

-- Insert corresponding profiles into public.users
INSERT INTO public.users (id, email, name, role, worker_status, created_at)
SELECT a.id, a.email, a.raw_user_meta_data->>'name', a.raw_user_meta_data->>'role', 'approved', a.created_at
FROM auth.users a
WHERE a.email LIKE '%@fijadora.com'
ON CONFLICT (id) DO NOTHING;
