-- Migration: Add select policies for authenticated users on properties, units, rooms, assets
-- And seed property rooms and assets (appliances) for Oakwood Heights.

-- 1. Create SELECT policies so authenticated users (tenants and workers) can view properties
CREATE POLICY "Authenticated users can read properties" ON properties
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read units" ON units
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read rooms" ON rooms
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read assets" ON assets
  FOR SELECT USING (auth.role() = 'authenticated');


-- 2. Seed a Unit for Oakwood Heights
INSERT INTO units (id, property_id, number) VALUES
  ('00000000-0000-0000-0000-000000000060', '00000000-0000-0000-0000-000000000005', 'Apartment 4B')
ON CONFLICT (id) DO NOTHING;


-- 3. Seed Rooms within the Unit
INSERT INTO rooms (id, unit_id, name) VALUES
  ('00000000-0000-0000-0000-000000000070', '00000000-0000-0000-0000-000000000060', 'Living Room'),
  ('00000000-0000-0000-0000-000000000071', '00000000-0000-0000-0000-000000000060', 'Kitchen'),
  ('00000000-0000-0000-0000-000000000072', '00000000-0000-0000-0000-000000000060', 'Bedroom')
ON CONFLICT (id) DO NOTHING;


-- 4. Seed Assets/Appliances within the Rooms
INSERT INTO assets (id, room_id, name, type, status) VALUES
  ('00000000-0000-0000-0000-000000000080', '00000000-0000-0000-0000-000000000070', 'Central AC', 'Appliance', 'Healthy'),
  ('00000000-0000-0000-0000-000000000081', '00000000-0000-0000-0000-000000000071', 'Smart Refrigerator', 'Appliance', 'Healthy'),
  ('00000000-0000-0000-0000-000000000082', '00000000-0000-0000-0000-000000000071', 'Induction Cooktop', 'Appliance', 'Needs Service'),
  ('00000000-0000-0000-0000-000000000083', '00000000-0000-0000-0000-000000000071', 'Eco Dishwasher', 'Appliance', 'Healthy'),
  ('00000000-0000-0000-0000-000000000084', '00000000-0000-0000-0000-000000000072', 'Digital Water Heater', 'Appliance', 'Healthy')
ON CONFLICT (id) DO NOTHING;


-- 5. Link the customer (Jane Customer) occupant row to the seeded unit
UPDATE property_occupants
SET unit_id = '00000000-0000-0000-0000-000000000060'
WHERE user_id = (SELECT id FROM users WHERE email = 'customer@fijadora.com');
