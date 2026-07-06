-- Fijadora — Clean Reset (removes all seed data, preserves schema)
-- Run this in the Supabase SQL Editor to erase all mock/test data
-- while keeping all tables, RLS policies, triggers, functions, and indexes.

-- 1. Items that don't CASCADE from auth.users
DELETE FROM collection_items;
DELETE FROM collection_likes;
DELETE FROM collection_follows;
DELETE FROM reviews;
DELETE FROM wishlists;

-- 2. Collections & products (no FK cascade from users)
DELETE FROM collections;
DELETE FROM products;

-- 3. Jobs (CASCADEs from users, but explicit is safer)
DELETE FROM jobs;

-- 4. FCM tokens, assets, rooms, units, properties
DELETE FROM fcm_tokens;
DELETE FROM assets;
DELETE FROM rooms;
DELETE FROM units;
DELETE FROM properties;

-- 5. Seed auth users — CASCADE-deletes public.users rows automatically
--    (via ON DELETE CASCADE on users(id) FK)
DELETE FROM auth.users WHERE email IN (
  'admin@fijadora.com',
  'manager@fijadora.com',
  'worker@fijadora.com',
  'customer@fijadora.com'
);
