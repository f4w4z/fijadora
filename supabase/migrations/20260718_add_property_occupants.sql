-- Migration: Add property_occupants table for customer-property links
-- Allows customers to be associated with properties they occupy

-- 1. Create property_occupants table
CREATE TABLE IF NOT EXISTS property_occupants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
  role TEXT NOT NULL DEFAULT 'tenant' CHECK (role IN ('tenant', 'owner', 'co-owner')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(property_id, user_id)
);

ALTER TABLE property_occupants ENABLE ROW LEVEL SECURITY;

-- 2. RLS: Occupants can see their own occupant records
CREATE POLICY "Occupants can read own records" ON property_occupants
  FOR SELECT USING (auth.uid() = user_id);

-- 3. RLS: Managers can read occupants for their properties
CREATE POLICY "Managers can read occupants" ON property_occupants
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM properties p WHERE p.id = property_id AND p.manager_id = auth.uid())
  );

-- 4. RLS: Managers can manage occupants for their properties
CREATE POLICY "Managers can insert occupants" ON property_occupants
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM properties p WHERE p.id = property_id AND p.manager_id = auth.uid())
  );

CREATE POLICY "Managers can update occupants" ON property_occupants
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM properties p WHERE p.id = property_id AND p.manager_id = auth.uid())
  );

CREATE POLICY "Managers can delete occupants" ON property_occupants
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM properties p WHERE p.id = property_id AND p.manager_id = auth.uid())
  );

-- 5. Index for efficient occupant lookups
CREATE INDEX IF NOT EXISTS idx_property_occupants_user_id ON property_occupants(user_id);
CREATE INDEX IF NOT EXISTS idx_property_occupants_property_id ON property_occupants(property_id);
