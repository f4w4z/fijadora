-- Migration: Alter featured_order column type from INT to BIGINT in collections table
-- This allows storing milliseconds since epoch without throwing "integer out of range" exceptions.

ALTER TABLE collections ALTER COLUMN featured_order TYPE BIGINT;
