-- Seed supporting data using real user IDs from Auth API signup
-- (These are the IDs returned by POST /auth/v1/signup)

-- 1. Approve worker status
UPDATE public.users SET worker_status = 'approved' WHERE email = 'worker@phoebe.app';

-- 2. Seed a property for Sarah Manager
INSERT INTO properties (id, name, address, manager_id)
SELECT '00000000-0000-0000-0000-000000000005', 'Oakwood Heights', '742 Evergreen Terrace, Springfield', id
FROM public.users WHERE email = 'manager@phoebe.app'
ON CONFLICT (id) DO NOTHING;

-- 3. Link Jane Customer as a tenant of that property
INSERT INTO property_occupants (property_id, user_id, role)
SELECT '00000000-0000-0000-0000-000000000005', id, 'tenant'
FROM public.users WHERE email = 'customer@phoebe.app'
ON CONFLICT (property_id, user_id) DO NOTHING;

-- 4. Seed products
INSERT INTO products (id, name, description, price, image_url, image_urls, category, inventory_count) VALUES
  ('00000000-0000-0000-0000-000000000010', 'Sleek Floor Lamp', 'Minimalist arc floor lamp with dimmable LED', 189.00, 'https://images.unsplash.com/photo-1507473885765-e6ed057ab6f8?w=400', '["https://images.unsplash.com/photo-1507473885765-e6ed057ab6f8?w=400"]', 'Lighting', 15),
  ('00000000-0000-0000-0000-000000000011', 'Ceramic Vase Set', 'Set of 3 hand-thrown ceramic vases', 79.00, 'https://images.unsplash.com/photo-1578500494198-246f612d3b3d?w=400', '["https://images.unsplash.com/photo-1578500494198-246f612d3b3d?w=400"]', 'Decor', 30),
  ('00000000-0000-0000-0000-000000000012', 'Linen Throw Blanket', 'Premium stonewashed linen throw in oatmeal', 129.00, 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400', '["https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400"]', 'Textiles', 25),
  ('00000000-0000-0000-0000-000000000013', 'Industrial Arc Lamp', 'Matte black arc floor lamp with marble base', 219.00, 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=400', '["https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=400"]', 'Lighting', 12),
  ('00000000-0000-0000-0000-000000000014', 'Faux Olive Tree', '5ft realistic faux olive tree in ceramic pot', 179.00, 'https://images.unsplash.com/photo-1587061949405-0e6be0c8b55d?w=400', '["https://images.unsplash.com/photo-1587061949405-0e6be0c8b55d?w=400"]', 'Decor', 20),
  ('00000000-0000-0000-0000-000000000015', 'Wool Throw Pillow', 'Handwoven wool blend pillow in charcoal', 69.00, 'https://images.unsplash.com/photo-1584100936595-c0654b55a2e2?w=400', '["https://images.unsplash.com/photo-1584100936595-c0654b55a2e2?w=400"]', 'Textiles', 40),
  ('00000000-0000-0000-0000-000000000016', 'Herb Garden Kit', 'Indoor herb garden starter with 6 pots, soil, seeds, and bamboo tray', 49.00, 'https://images.unsplash.com/photo-1585409677983-0f6c41ca9c3b?w=400', '["https://images.unsplash.com/photo-1585409677983-0f6c41ca9c3b?w=400"]', 'Bundle', 50),
  ('00000000-0000-0000-0000-000000000017', 'Paint & Tools Bundle', 'Premium paint (5L) + roller set + painter''s tape + drop cloth + tray', 129.00, 'https://images.unsplash.com/photo-1562259929-b4e1fd3aef09?w=400', '["https://images.unsplash.com/photo-1562259929-b4e1fd3aef09?w=400"]', 'Bundle', 35),
  ('00000000-0000-0000-0000-000000000018', 'Smart Home Starter', 'Smart plug (4-pack) + hub + motion sensor + smart bulb (2-pack)', 299.00, 'https://images.unsplash.com/photo-1558089687-f282ffcbc126?w=400', '["https://images.unsplash.com/photo-1558089687-f282ffcbc126?w=400"]', 'Bundle', 20),
  ('00000000-0000-0000-0000-000000000019', 'Bath Refresh Bundle', 'Rain shower head + matte black fixtures + towel set (4-pc) + storage caddy', 199.00, 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=400', '["https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=400"]', 'Bundle', 25),
  ('00000000-0000-0000-0000-000000000020', 'Cozy Night In Bundle', 'Weighted blanket + soy candle set (3) + bamboo tray + cocoa mix gift set', 159.00, 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=400', '["https://images.unsplash.com/photo-1519681393784-d120267933ba?w=400"]', 'Bundle', 30),
  ('00000000-0000-0000-0000-000000000021', 'Kitchen Starter Bundle', 'Cast iron skillet + bamboo cutting board set + utensil set + kitchen towels (6)', 249.00, 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400', '["https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400"]', 'Bundle', 15),
  ('00000000-0000-0000-0000-000000000022', 'Gallery Wall Set', 'Set of 5 coordinating art prints with frames, two layout options', 139.00, 'https://images.unsplash.com/photo-1513519245088-0e12902e35ca?w=400', '["https://images.unsplash.com/photo-1513519245088-0e12902e35ca?w=400"]', 'Decor', 22)
ON CONFLICT (id) DO NOTHING;

-- 5. Seed collections (using Sarah Manager's real ID)
INSERT INTO collections (id, title, description, cover_image_url, creator_id, creator_name, category, is_public)
SELECT '00000000-0000-0000-0000-000000000020', 'Cozy Minimalist', 'Warm minimalism for small spaces — clean lines and soft textures', 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600', id, 'Sarah Manager', 'trending', true
FROM public.users WHERE email = 'manager@phoebe.app'
ON CONFLICT (id) DO NOTHING;

INSERT INTO collections (id, title, description, cover_image_url, creator_id, creator_name, category, is_public)
SELECT '00000000-0000-0000-0000-000000000021', 'Kitchen Refresh', 'Easy budget-friendly updates for your kitchen that make a big impact', 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=600', id, 'Sarah Manager', 'kitchen', true
FROM public.users WHERE email = 'manager@phoebe.app'
ON CONFLICT (id) DO NOTHING;

INSERT INTO collections (id, title, description, cover_image_url, creator_id, creator_name, category, is_public)
SELECT '00000000-0000-0000-0000-000000000022', 'Bathroom Spa Retreat', 'Transform your bathroom into a spa-like sanctuary with these picks', 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=600', id, 'Sarah Manager', 'bathroom', true
FROM public.users WHERE email = 'manager@phoebe.app'
ON CONFLICT (id) DO NOTHING;

INSERT INTO collections (id, title, description, cover_image_url, creator_id, creator_name, category, is_public)
SELECT '00000000-0000-0000-0000-000000000023', 'Weekend DIY Projects', 'Fun and rewarding DIY projects to tackle this weekend', 'https://images.unsplash.com/photo-1562259929-b4e1fd3aef09?w=600', id, 'Sarah Manager', 'diy', true
FROM public.users WHERE email = 'manager@phoebe.app'
ON CONFLICT (id) DO NOTHING;

INSERT INTO collections (id, title, description, cover_image_url, creator_id, creator_name, category, is_public)
SELECT '00000000-0000-0000-0000-000000000024', 'Seasonal Refresh', 'Transition your home into the new season with fresh accents', 'https://images.unsplash.com/photo-1513519245088-0e12902e35ca?w=600', id, 'Sarah Manager', 'seasonal', true
FROM public.users WHERE email = 'manager@phoebe.app'
ON CONFLICT (id) DO NOTHING;

INSERT INTO collections (id, title, description, cover_image_url, creator_id, creator_name, category, is_public)
SELECT '00000000-0000-0000-0000-000000000025', 'Urban Jungle', 'Bring the outdoors in with our favorite indoor plant setups', 'https://images.unsplash.com/photo-1587061949405-0e6be0c8b55d?w=600', id, 'Sarah Manager', 'livingRoom', true
FROM public.users WHERE email = 'manager@phoebe.app'
ON CONFLICT (id) DO NOTHING;

INSERT INTO collections (id, title, description, cover_image_url, creator_id, creator_name, category, is_public)
SELECT '00000000-0000-0000-0000-000000000026', 'Boho Bedroom Vibes', 'Free-spirited bohemian bedroom decor for a dreamy retreat', 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=600', id, 'Sarah Manager', 'bedroom', true
FROM public.users WHERE email = 'manager@phoebe.app'
ON CONFLICT (id) DO NOTHING;

INSERT INTO collections (id, title, description, cover_image_url, creator_id, creator_name, category, is_public)
SELECT '00000000-0000-0000-0000-000000000027', 'Smart & Efficient Home', 'Upgrade your home with smart technology and energy-saving essentials', 'https://images.unsplash.com/photo-1558089687-f282ffcbc126?w=600', id, 'Sarah Manager', 'energy', true
FROM public.users WHERE email = 'manager@phoebe.app'
ON CONFLICT (id) DO NOTHING;

-- 6. Seed collection items
INSERT INTO collection_items (collection_id, item_type, reference_id, label, subtitle, image_url) VALUES
  -- Cozy Minimalist
  ('00000000-0000-0000-0000-000000000020', 'product', '00000000-0000-0000-0000-000000000010', 'Sleek Floor Lamp', 'Dimmable arc lamp', NULL),
  ('00000000-0000-0000-0000-000000000020', 'product', '00000000-0000-0000-0000-000000000012', 'Linen Throw Blanket', 'Stonewashed oatmeal', NULL),
  ('00000000-0000-0000-0000-000000000020', 'product', '00000000-0000-0000-0000-000000000015', 'Wool Throw Pillow', 'Charcoal handwoven', NULL),
  ('00000000-0000-0000-0000-000000000020', 'product', '00000000-0000-0000-0000-000000000011', 'Ceramic Vase Set', 'Hand-thrown set of 3', NULL),
  -- Kitchen Refresh
  ('00000000-0000-0000-0000-000000000021', 'product', '00000000-0000-0000-0000-000000000011', 'Ceramic Vase Set', 'Hand-thrown set of 3', NULL),
  ('00000000-0000-0000-0000-000000000021', 'product', '00000000-0000-0000-0000-000000000021', 'Kitchen Starter Bundle', 'Everything you need', NULL),
  ('00000000-0000-0000-0000-000000000021', 'product', '00000000-0000-0000-0000-000000000016', 'Herb Garden Kit', 'Indoor herbs', NULL),
  -- Bathroom Spa Retreat
  ('00000000-0000-0000-0000-000000000022', 'product', '00000000-0000-0000-0000-000000000019', 'Bath Refresh Bundle', 'New fixtures & towels', NULL),
  ('00000000-0000-0000-0000-000000000022', 'product', '00000000-0000-0000-0000-000000000020', 'Cozy Night In Bundle', 'Weighted blanket & candle set', NULL),
  -- Weekend DIY Projects
  ('00000000-0000-0000-0000-000000000023', 'product', '00000000-0000-0000-0000-000000000017', 'Paint & Tools Bundle', 'Premium paint + roller set', NULL),
  ('00000000-0000-0000-0000-000000000023', 'product', '00000000-0000-0000-0000-000000000016', 'Herb Garden Kit', 'Grow your own herbs', NULL),
  -- Urban Jungle
  ('00000000-0000-0000-0000-000000000025', 'product', '00000000-0000-0000-0000-000000000014', 'Faux Olive Tree', '5ft realistic faux tree', NULL),
  ('00000000-0000-0000-0000-000000000025', 'product', '00000000-0000-0000-0000-000000000013', 'Industrial Arc Lamp', 'Matte black with marble base', NULL),
  ('00000000-0000-0000-0000-000000000025', 'product', '00000000-0000-0000-0000-000000000011', 'Ceramic Vase Set', 'Hand-thrown set of 3', NULL),
  -- Boho Bedroom Vibes
  ('00000000-0000-0000-0000-000000000026', 'product', '00000000-0000-0000-0000-000000000012', 'Linen Throw Blanket', 'Stonewashed oatmeal', NULL),
  ('00000000-0000-0000-0000-000000000026', 'product', '00000000-0000-0000-0000-000000000015', 'Wool Throw Pillow', 'Charcoal handwoven', NULL),
  ('00000000-0000-0000-0000-000000000026', 'product', '00000000-0000-0000-0000-000000000020', 'Cozy Night In Bundle', 'Weighted blanket & candle set', NULL),
  -- Smart & Efficient Home
  ('00000000-0000-0000-0000-000000000027', 'product', '00000000-0000-0000-0000-000000000018', 'Smart Home Starter', 'Plugs, hub, sensor & bulbs', NULL),
  -- Seasonal Refresh
  ('00000000-0000-0000-0000-000000000024', 'product', '00000000-0000-0000-0000-000000000022', 'Gallery Wall Set', 'Set of 5 framed prints', NULL),
  ('00000000-0000-0000-0000-000000000024', 'product', '00000000-0000-0000-0000-000000000011', 'Ceramic Vase Set', 'Hand-thrown set of 3', NULL),
  ('00000000-0000-0000-0000-000000000024', 'product', '00000000-0000-0000-0000-000000000016', 'Herb Garden Kit', 'Indoor herb garden', NULL)
ON CONFLICT DO NOTHING;

-- 7. Seed jobs (using real user IDs)
INSERT INTO jobs (id, customer_id, worker_id, description, trade_type, status, schedule_date_time, address)
SELECT '00000000-0000-0000-0000-000000000030', cu.id, wo.id, 'Kitchen sink leaking under pressure', 'plumbing', 'assigned', NOW() + INTERVAL '1 day', '742 Evergreen Terrace, Springfield'
FROM public.users cu, public.users wo
WHERE cu.email = 'customer@phoebe.app' AND wo.email = 'worker@phoebe.app'
ON CONFLICT (id) DO NOTHING;

INSERT INTO jobs (id, customer_id, worker_id, description, trade_type, status, schedule_date_time, address)
SELECT '00000000-0000-0000-0000-000000000031', cu.id, NULL, 'Living room light switch not working', 'electrical', 'pending', NOW() + INTERVAL '3 days', 'Apartment 4B, Oakwood Heights'
FROM public.users cu
WHERE cu.email = 'customer@phoebe.app'
ON CONFLICT (id) DO NOTHING;
