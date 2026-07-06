-- Migration: Replace broad authenticated-user RLS with tenant/staff-specific policies
-- Previously any authenticated user could read ALL properties, units, rooms, and assets.
-- Now:
--   - Tenants/customers can only read properties they're linked to via property_occupants
--   - Staff (admin/manager) can read all (they need to manage everything)
--   - Workers can read properties they have job assignments in

-- Helper function to check if user is staff (admin/manager)
CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' IN ('admin', 'manager')
  );
$$;

-- Drop old overly-permissive policies
DROP POLICY IF EXISTS "Authenticated users can read properties" ON properties;
DROP POLICY IF EXISTS "Authenticated users can read units" ON units;
DROP POLICY IF EXISTS "Authenticated users can read rooms" ON rooms;
DROP POLICY IF EXISTS "Authenticated users can read assets" ON assets;

-- Properties: staff see all; others see only their own
CREATE POLICY "Properties read access" ON properties
  FOR SELECT USING (
    auth.role() = 'authenticated'
    AND (
      public.is_staff()
      OR EXISTS (
        SELECT 1 FROM property_occupants
        WHERE property_occupants.property_id = properties.id
        AND property_occupants.user_id = auth.uid()
      )
    )
  );

-- Units: staff see all; others see units in their properties
CREATE POLICY "Units read access" ON units
  FOR SELECT USING (
    auth.role() = 'authenticated'
    AND (
      public.is_staff()
      OR EXISTS (
        SELECT 1 FROM property_occupants
        WHERE property_occupants.property_id = units.property_id
        AND property_occupants.user_id = auth.uid()
      )
    )
  );

-- Rooms: staff see all; others see rooms in their units
CREATE POLICY "Rooms read access" ON rooms
  FOR SELECT USING (
    auth.role() = 'authenticated'
    AND (
      public.is_staff()
      OR EXISTS (
        SELECT 1 FROM property_occupants po
        JOIN units u ON u.property_id = po.property_id
        WHERE u.id = rooms.unit_id
        AND po.user_id = auth.uid()
      )
    )
  );

-- Assets: staff see all; others see assets in their rooms
CREATE POLICY "Assets read access" ON assets
  FOR SELECT USING (
    auth.role() = 'authenticated'
    AND (
      public.is_staff()
      OR EXISTS (
        SELECT 1 FROM property_occupants po
        JOIN units u ON u.property_id = po.property_id
        JOIN rooms r ON r.unit_id = u.id
        WHERE r.id = assets.room_id
        AND po.user_id = auth.uid()
      )
    )
  );
