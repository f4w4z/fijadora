-- Migration: Add missing RLS policies for collections and collection_items update/delete/insert operations

-- 1. Policies for collections
CREATE POLICY "Users can update own collections" ON collections 
  FOR UPDATE 
  USING (auth.uid() = creator_id);

CREATE POLICY "Users can delete own collections" ON collections 
  FOR DELETE 
  USING (auth.uid() = creator_id);

-- 2. Policies for collection_items
CREATE POLICY "Users can insert collection items" ON collection_items 
  FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM collections c 
      WHERE c.id = collection_id AND c.creator_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own collection items" ON collection_items 
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM collections c 
      WHERE c.id = collection_id AND c.creator_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own collection items" ON collection_items 
  FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM collections c 
      WHERE c.id = collection_id AND c.creator_id = auth.uid()
    )
  );
