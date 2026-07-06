-- Fijadora — Supabase Schema Migration
-- Run this in the Supabase SQL Editor (https://supabase.com/dashboard/project/nmcxkoahokihzqnfkmvg)

-- 1. Users table (for auth profiles)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT NOT NULL DEFAULT '',
  role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'worker', 'admin', 'manager')),
  worker_status TEXT CHECK (worker_status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can read all users" ON users FOR SELECT USING (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
);
CREATE POLICY "Admins can update worker status" ON users FOR UPDATE USING (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
);

-- 2. Products table (for shop)
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  price NUMERIC(10,2) NOT NULL DEFAULT 0,
  image_url TEXT NOT NULL DEFAULT '',
  image_urls JSONB NOT NULL DEFAULT '[]',
  category TEXT NOT NULL DEFAULT '',
  inventory_count INT NOT NULL DEFAULT 0,
  is_reserved BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read products" ON products FOR SELECT USING (true);

-- 3. Wishlists table
CREATE TABLE IF NOT EXISTS wishlists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, product_id)
);
ALTER TABLE wishlists ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own wishlist" ON wishlists FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own wishlist" ON wishlists FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own wishlist" ON wishlists FOR DELETE USING (auth.uid() = user_id);

-- 4. Reviews table
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read reviews" ON reviews FOR SELECT USING (true);
CREATE POLICY "Users can insert own reviews" ON reviews FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 5. Jobs table (maintenance/service requests)
CREATE TABLE IF NOT EXISTS jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  worker_id UUID REFERENCES users(id) ON DELETE SET NULL,
  description TEXT NOT NULL DEFAULT '',
  trade_type TEXT NOT NULL CHECK (trade_type IN ('interiorDesign','electrical','plumbing','masonry','tiling','designConsultation','acEngineering','kitchenDesigns','cleaning','gardening')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','quoted','assigned','workerEnRoute','workerArrived','inProgress','waitingApproval','completed','rejected','cancelled','onHold','rescheduled','awaitingParts')),
  schedule_date_time TIMESTAMPTZ,
  address TEXT NOT NULL DEFAULT '',
  images JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Customers can read own jobs" ON jobs FOR SELECT USING (auth.uid() = customer_id);
CREATE POLICY "Workers can read assigned jobs" ON jobs FOR SELECT USING (auth.uid() = worker_id);
CREATE POLICY "Customers can insert jobs" ON jobs FOR INSERT WITH CHECK (auth.uid() = customer_id);
CREATE POLICY "Admins can read all jobs" ON jobs FOR SELECT USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'manager'))
);
CREATE POLICY "Workers can update assigned jobs" ON jobs FOR UPDATE USING (auth.uid() = worker_id);
CREATE POLICY "Customers can update own jobs" ON jobs FOR UPDATE USING (auth.uid() = customer_id);
CREATE POLICY "Admins can update any job" ON jobs FOR UPDATE USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'manager'))
);
CREATE POLICY "Workers can insert jobs" ON jobs FOR INSERT WITH CHECK (auth.uid() = customer_id);
CREATE POLICY "Admins can insert jobs" ON jobs FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'manager'))
);

-- 6. Collections table (curated collections)
CREATE TABLE IF NOT EXISTS collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  cover_image_url TEXT,
  creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  creator_name TEXT NOT NULL DEFAULT '',
  creator_avatar_url TEXT,
  category TEXT NOT NULL DEFAULT 'trending' CHECK (category IN ('trending','kitchen','diy','seasonal','renovation','bathroom','bedroom','livingRoom','outdoor','energy','cleaning','organization')),
  is_public BOOLEAN NOT NULL DEFAULT true,
  follower_count INT NOT NULL DEFAULT 0,
  like_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read public collections" ON collections FOR SELECT USING (is_public OR auth.uid() = creator_id);
CREATE POLICY "Users can insert collections" ON collections FOR INSERT WITH CHECK (auth.uid() = creator_id);

-- 7. Collection Items table
CREATE TABLE IF NOT EXISTS collection_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
  item_type TEXT NOT NULL CHECK (item_type IN ('product', 'service', 'note')),
  reference_id TEXT,
  label TEXT NOT NULL DEFAULT '',
  subtitle TEXT,
  image_url TEXT,
  note_content TEXT
);
ALTER TABLE collection_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read public collection items" ON collection_items FOR SELECT USING (
  EXISTS (SELECT 1 FROM collections c WHERE c.id = collection_id AND (c.is_public OR auth.uid() = c.creator_id))
);

-- 8. Collection Follows table
CREATE TABLE IF NOT EXISTS collection_follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, collection_id)
);
ALTER TABLE collection_follows ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own follows" ON collection_follows FOR ALL USING (auth.uid() = user_id);

-- 9. Collection Likes table
CREATE TABLE IF NOT EXISTS collection_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, collection_id)
);
ALTER TABLE collection_likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own likes" ON collection_likes FOR ALL USING (auth.uid() = user_id);

-- 10. Properties table (for manager property management)
CREATE TABLE IF NOT EXISTS properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL DEFAULT '',
  address TEXT NOT NULL DEFAULT '',
  manager_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Managers can read own properties" ON properties FOR SELECT USING (auth.uid() = manager_id);
CREATE POLICY "Managers can insert properties" ON properties FOR INSERT WITH CHECK (auth.uid() = manager_id);
CREATE POLICY "Managers can update own properties" ON properties FOR UPDATE USING (auth.uid() = manager_id);
CREATE POLICY "Managers can delete own properties" ON properties FOR DELETE USING (auth.uid() = manager_id);

-- 11. Units table (apartment/unit within a property)
CREATE TABLE IF NOT EXISTS units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  number TEXT NOT NULL DEFAULT ''
);
ALTER TABLE units ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Managers can read own units" ON units FOR SELECT USING (
  EXISTS (SELECT 1 FROM properties p WHERE p.id = property_id AND p.manager_id = auth.uid())
);
CREATE POLICY "Managers can insert units" ON units FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM properties p WHERE p.id = property_id AND p.manager_id = auth.uid())
);
CREATE POLICY "Managers can update own units" ON units FOR UPDATE USING (
  EXISTS (SELECT 1 FROM properties p WHERE p.id = property_id AND p.manager_id = auth.uid())
);
CREATE POLICY "Managers can delete own units" ON units FOR DELETE USING (
  EXISTS (SELECT 1 FROM properties p WHERE p.id = property_id AND p.manager_id = auth.uid())
);

-- 12. Rooms table (room within a unit)
CREATE TABLE IF NOT EXISTS rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT ''
);
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Managers can read own rooms" ON rooms FOR SELECT USING (
  EXISTS (SELECT 1 FROM properties p JOIN units u ON u.property_id = p.id WHERE u.id = unit_id AND p.manager_id = auth.uid())
);
CREATE POLICY "Managers can insert rooms" ON rooms FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM properties p JOIN units u ON u.property_id = p.id WHERE u.id = unit_id AND p.manager_id = auth.uid())
);
CREATE POLICY "Managers can update own rooms" ON rooms FOR UPDATE USING (
  EXISTS (SELECT 1 FROM properties p JOIN units u ON u.property_id = p.id WHERE u.id = unit_id AND p.manager_id = auth.uid())
);
CREATE POLICY "Managers can delete own rooms" ON rooms FOR DELETE USING (
  EXISTS (SELECT 1 FROM properties p JOIN units u ON u.property_id = p.id WHERE u.id = unit_id AND p.manager_id = auth.uid())
);

-- 13. Assets table (item/appliance within a room)
CREATE TABLE IF NOT EXISTS assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '',
  type TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'Healthy'
);
ALTER TABLE assets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Managers can read own assets" ON assets FOR SELECT USING (
  EXISTS (SELECT 1 FROM properties p JOIN units u ON u.property_id = p.id JOIN rooms r ON r.unit_id = u.id WHERE r.id = room_id AND p.manager_id = auth.uid())
);
CREATE POLICY "Managers can insert assets" ON assets FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM properties p JOIN units u ON u.property_id = p.id JOIN rooms r ON r.unit_id = u.id WHERE r.id = room_id AND p.manager_id = auth.uid())
);
CREATE POLICY "Managers can update own assets" ON assets FOR UPDATE USING (
  EXISTS (SELECT 1 FROM properties p JOIN units u ON u.property_id = p.id JOIN rooms r ON r.unit_id = u.id WHERE r.id = room_id AND p.manager_id = auth.uid())
);
CREATE POLICY "Managers can delete own assets" ON assets FOR DELETE USING (
  EXISTS (SELECT 1 FROM properties p JOIN units u ON u.property_id = p.id JOIN rooms r ON r.unit_id = u.id WHERE r.id = room_id AND p.manager_id = auth.uid())
);

-- 14. FCM Tokens table (push notification tokens)
CREATE TABLE IF NOT EXISTS fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, token)
);
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own tokens" ON fcm_tokens FOR ALL USING (auth.uid() = user_id);

-- Trigger: auto-update updated_at on jobs
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER jobs_updated_at
  BEFORE UPDATE ON jobs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_jobs_customer_id ON jobs(customer_id);
CREATE INDEX IF NOT EXISTS idx_jobs_worker_id ON jobs(worker_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_wishlists_user_id ON wishlists(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_collections_creator_id ON collections(creator_id);
CREATE INDEX IF NOT EXISTS idx_collection_items_collection_id ON collection_items(collection_id);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id);

-- Seed helper: function to create a user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role, worker_status)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer'),
    CASE WHEN NEW.raw_user_meta_data->>'role' = 'worker' THEN 'pending' ELSE NULL END
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create user profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- RPC: increment collection follower count
CREATE OR REPLACE FUNCTION increment_collection_follow(col_id UUID)
RETURNS void AS $$
  UPDATE collections SET follower_count = follower_count + 1 WHERE id = col_id;
$$ LANGUAGE sql;

-- RPC: decrement collection follower count
CREATE OR REPLACE FUNCTION decrement_collection_follow(col_id UUID)
RETURNS void AS $$
  UPDATE collections SET follower_count = GREATEST(0, follower_count - 1) WHERE id = col_id;
$$ LANGUAGE sql;

-- RPC: increment collection like count
CREATE OR REPLACE FUNCTION increment_collection_like(col_id UUID)
RETURNS void AS $$
  UPDATE collections SET like_count = like_count + 1 WHERE id = col_id;
$$ LANGUAGE sql;

-- RPC: decrement collection like count
CREATE OR REPLACE FUNCTION decrement_collection_like(col_id UUID)
RETURNS void AS $$
  UPDATE collections SET like_count = GREATEST(0, like_count - 1) WHERE id = col_id;
$$ LANGUAGE sql;

-- 20. Helper: bulk user name lookup (bypasses row-level security so reviewers can show names)
CREATE OR REPLACE FUNCTION get_user_names(user_ids UUID[])
RETURNS TABLE(id UUID, name TEXT) SECURITY DEFINER AS $$
  SELECT u.id, u.name FROM users u WHERE u.id = ANY(user_ids);
$$ LANGUAGE sql;
