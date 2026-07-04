-- Migration: Add asset_id FK to jobs table for proper asset-level maintenance history linking
ALTER TABLE jobs
  ADD COLUMN IF NOT EXISTS asset_id UUID REFERENCES assets(id) ON DELETE SET NULL;

-- Index for fast lookups of jobs by asset
CREATE INDEX IF NOT EXISTS idx_jobs_asset_id ON jobs(asset_id);
