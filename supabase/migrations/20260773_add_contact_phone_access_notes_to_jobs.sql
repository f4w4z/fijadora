-- Migration: Add contact_phone and access_notes to jobs table
-- This supports the new booking form fields for customer contact info and site access instructions.

ALTER TABLE jobs
  ADD COLUMN IF NOT EXISTS contact_phone TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS access_notes TEXT NOT NULL DEFAULT '';
