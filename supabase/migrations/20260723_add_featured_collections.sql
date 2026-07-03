-- Migration: Add featured flag to collections for Shop the Look

ALTER TABLE collections ADD COLUMN IF NOT EXISTS is_featured BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE collections ADD COLUMN IF NOT EXISTS featured_order INT NOT NULL DEFAULT 0;
