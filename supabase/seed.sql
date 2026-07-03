-- Phoebe Homes — Seed Data
-- Run after migrations: supabase db reset

-- Seed auth users (triggers handle_new_user() which creates public.users rows)
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, confirmation_token, recovery_token, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, instance_id) VALUES
  ('00000000-0000-0000-0000-000000000001', 'admin@phoebe.app', extensions.crypt('password', extensions.gen_salt('bf')), now(), '', '', 'authenticated', 'authenticated', '{"provider":"email","providers":["email"]}', '{"name":"Admin User","role":"admin"}', now(), now(), '00000000-0000-0000-0000-000000000000'),
  ('00000000-0000-0000-0000-000000000002', 'manager@phoebe.app', extensions.crypt('password', extensions.gen_salt('bf')), now(), '', '', 'authenticated', 'authenticated', '{"provider":"email","providers":["email"]}', '{"name":"Sarah Manager","role":"manager"}', now(), now(), '00000000-0000-0000-0000-000000000000'),
  ('00000000-0000-0000-0000-000000000003', 'worker@phoebe.app', extensions.crypt('password', extensions.gen_salt('bf')), now(), '', '', 'authenticated', 'authenticated', '{"provider":"email","providers":["email"]}', '{"name":"Alex Worker","role":"worker"}', now(), now(), '00000000-0000-0000-0000-000000000000'),
  ('00000000-0000-0000-0000-000000000004', 'customer@phoebe.app', extensions.crypt('password', extensions.gen_salt('bf')), now(), '', '', 'authenticated', 'authenticated', '{"provider":"email","providers":["email"]}', '{"name":"Jane Customer","role":"customer"}', now(), now(), '00000000-0000-0000-0000-000000000000')
ON CONFLICT (id) DO NOTHING;

-- Update extra fields not set by handle_new_user() trigger
UPDATE public.users SET worker_status = 'approved' WHERE id = '00000000-0000-0000-0000-000000000003';

-- Seed products
INSERT INTO products (id, name, description, price, image_url, image_urls, category, inventory_count) VALUES
  ('00000000-0000-0000-0000-000000000010', 'Sleek Floor Lamp', 'Minimalist arc floor lamp with dimmable LED', 189.00, 'https://images.unsplash.com/photo-1507473885765-e6ed057ab6f8?w=400', '["https://images.unsplash.com/photo-1507473885765-e6ed057ab6f8?w=400"]', 'Lighting', 15),
  ('00000000-0000-0000-0000-000000000011', 'Ceramic Vase Set', 'Set of 3 hand-thrown ceramic vases', 79.00, 'https://images.unsplash.com/photo-1578500494198-246f612d3b3d?w=400', '["https://images.unsplash.com/photo-1578500494198-246f612d3b3d?w=400"]', 'Decor', 30),
  ('00000000-0000-0000-0000-000000000012', 'Linen Throw Blanket', 'Premium stonewashed linen throw in oatmeal', 129.00, 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400', '["https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400"]', 'Textiles', 25)
ON CONFLICT (id) DO NOTHING;

-- Seed collections
INSERT INTO collections (id, title, description, cover_image_url, creator_id, creator_name, category, is_public) VALUES
  ('00000000-0000-0000-0000-000000000020', 'Cozy Minimalist', 'Warm minimalism for small spaces', NULL, '00000000-0000-0000-0000-000000000002', 'Sarah Manager', 'trending', true),
  ('00000000-0000-0000-0000-000000000021', 'Kitchen Refresh', 'Easy updates for your kitchen', NULL, '00000000-0000-0000-0000-000000000002', 'Sarah Manager', 'kitchen', true)
ON CONFLICT (id) DO NOTHING;

-- Seed collection items
INSERT INTO collection_items (collection_id, item_type, reference_id, label, subtitle, image_url) VALUES
  ('00000000-0000-0000-0000-000000000020', 'product', '00000000-0000-0000-0000-000000000010', 'Sleek Floor Lamp', 'Dimmable arc lamp', NULL),
  ('00000000-0000-0000-0000-000000000020', 'product', '00000000-0000-0000-0000-000000000012', 'Linen Throw Blanket', 'Stonewashed oatmeal', NULL),
  ('00000000-0000-0000-0000-000000000021', 'product', '00000000-0000-0000-0000-000000000011', 'Ceramic Vase Set', 'Hand-thrown set of 3', NULL)
ON CONFLICT DO NOTHING;

-- Seed jobs
INSERT INTO jobs (id, customer_id, worker_id, description, trade_type, status, schedule_date_time, address) VALUES
  ('00000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000003', 'Kitchen sink leaking under pressure', 'plumbing', 'assigned', NOW() + INTERVAL '1 day', '742 Evergreen Terrace, Springfield'),
  ('00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000004', NULL, 'Living room light switch not working', 'electrical', 'pending', NOW() + INTERVAL '3 days', 'Apartment 4B, Oakwood Heights')
ON CONFLICT (id) DO NOTHING;
