-- Migration: Fix collections and collection_items RLS to allow admins full write/delete/update permissions.
-- Seeded collections are owned by Sarah Manager, but admins need to star (featured) or delete them in the Admin app.

-- 1. Drop old restrictive policies on collections
DROP POLICY IF EXISTS "Users can insert collections" ON collections;
DROP POLICY IF EXISTS "Users can update own collections" ON collections;
DROP POLICY IF EXISTS "Users can delete own collections" ON collections;

-- Recreate collections policies incorporating public.is_admin()
CREATE POLICY "Users can insert collections" ON collections 
  FOR INSERT 
  WITH CHECK (auth.uid() = creator_id OR public.is_admin());

CREATE POLICY "Users can update own collections" ON collections 
  FOR UPDATE 
  USING (auth.uid() = creator_id OR public.is_admin());

CREATE POLICY "Users can delete own collections" ON collections 
  FOR DELETE 
  USING (auth.uid() = creator_id OR public.is_admin());


-- 2. Drop old restrictive policies on collection_items
DROP POLICY IF EXISTS "Users can insert collection items" ON collection_items;
DROP POLICY IF EXISTS "Users can update own collection items" ON collection_items;
DROP POLICY IF EXISTS "Users can delete own collection items" ON collection_items;

-- Recreate collection_items policies incorporating public.is_admin() check on the parent collection
CREATE POLICY "Users can insert collection items" ON collection_items 
  FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM collections c 
      WHERE c.id = collection_id AND (c.creator_id = auth.uid() OR public.is_admin())
    )
  );

CREATE POLICY "Users can update own collection items" ON collection_items 
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM collections c 
      WHERE c.id = collection_id AND (c.creator_id = auth.uid() OR public.is_admin())
    )
  );

CREATE POLICY "Users can delete own collection items" ON collection_items 
  FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM collections c 
      WHERE c.id = collection_id AND (c.creator_id = auth.uid() OR public.is_admin())
    )
  );
