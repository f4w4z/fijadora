-- Migration: Add is_edited flag to collections to track if a look has been edited

ALTER TABLE collections ADD COLUMN IF NOT EXISTS is_edited BOOLEAN NOT NULL DEFAULT false;
