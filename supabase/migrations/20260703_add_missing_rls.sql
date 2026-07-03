-- Migration: Add missing RLS policies for CRUD operations
-- Run: supabase db push or paste into Supabase SQL editor

-- 1. Users: admins can read all users (for worker management)
CREATE POLICY "Admins can read all users" ON users FOR SELECT USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- 2. Jobs: workers can update assigned jobs (status changes)
CREATE POLICY "Workers can update assigned jobs" ON jobs FOR UPDATE USING (auth.uid() = worker_id);
-- 2b. Jobs: customers can update their own jobs
CREATE POLICY "Customers can update own jobs" ON jobs FOR UPDATE USING (auth.uid() = customer_id);
-- 2c. Jobs: admins/managers can update any job
CREATE POLICY "Admins can update any job" ON jobs FOR UPDATE USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'manager'))
);
-- 2d. Jobs: workers can insert jobs (needed for worker-initiated requests)
CREATE POLICY "Workers can insert jobs" ON jobs FOR INSERT WITH CHECK (auth.uid() = customer_id);
-- 2e. Jobs: admins/managers can insert jobs
CREATE POLICY "Admins can insert jobs" ON jobs FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'manager'))
);

-- 3. Properties: manager CRUD
CREATE POLICY "Managers can insert properties" ON properties FOR INSERT WITH CHECK (auth.uid() = manager_id);
CREATE POLICY "Managers can update own properties" ON properties FOR UPDATE USING (auth.uid() = manager_id);
CREATE POLICY "Managers can delete own properties" ON properties FOR DELETE USING (auth.uid() = manager_id);

-- 4. Units: manager CRUD
CREATE POLICY "Managers can insert units" ON units FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM properties p WHERE p.id = property_id AND p.manager_id = auth.uid())
);
CREATE POLICY "Managers can update own units" ON units FOR UPDATE USING (
  EXISTS (SELECT 1 FROM properties p WHERE p.id = property_id AND p.manager_id = auth.uid())
);
CREATE POLICY "Managers can delete own units" ON units FOR DELETE USING (
  EXISTS (SELECT 1 FROM properties p WHERE p.id = property_id AND p.manager_id = auth.uid())
);

-- 5. Rooms: manager CRUD
CREATE POLICY "Managers can insert rooms" ON rooms FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM properties p JOIN units u ON u.property_id = p.id WHERE u.id = unit_id AND p.manager_id = auth.uid())
);
CREATE POLICY "Managers can update own rooms" ON rooms FOR UPDATE USING (
  EXISTS (SELECT 1 FROM properties p JOIN units u ON u.property_id = p.id WHERE u.id = unit_id AND p.manager_id = auth.uid())
);
CREATE POLICY "Managers can delete own rooms" ON rooms FOR DELETE USING (
  EXISTS (SELECT 1 FROM properties p JOIN units u ON u.property_id = p.id WHERE u.id = unit_id AND p.manager_id = auth.uid())
);

-- 6. Assets: manager CRUD
CREATE POLICY "Managers can insert assets" ON assets FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM properties p JOIN units u ON u.property_id = p.id JOIN rooms r ON r.unit_id = u.id WHERE r.id = room_id AND p.manager_id = auth.uid())
);
CREATE POLICY "Managers can update own assets" ON assets FOR UPDATE USING (
  EXISTS (SELECT 1 FROM properties p JOIN units u ON u.property_id = p.id JOIN rooms r ON r.unit_id = u.id WHERE r.id = room_id AND p.manager_id = auth.uid())
);
CREATE POLICY "Managers can delete own assets" ON assets FOR DELETE USING (
  EXISTS (SELECT 1 FROM properties p JOIN units u ON u.property_id = p.id JOIN rooms r ON r.unit_id = u.id WHERE r.id = room_id AND p.manager_id = auth.uid())
);
