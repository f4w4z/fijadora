-- Migration: Add newsletter_subscribers table
-- Used by the landing page form to collect email signups

CREATE TABLE IF NOT EXISTS newsletter_subscribers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  subscribed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  source TEXT NOT NULL DEFAULT 'landing-page'
);

ALTER TABLE newsletter_subscribers ENABLE ROW LEVEL SECURITY;

-- Anyone can insert (public form on landing page)
CREATE POLICY "Anyone can subscribe" ON newsletter_subscribers
  FOR INSERT WITH CHECK (true);

-- Only authenticated users with admin/manager role can read
CREATE POLICY "Admins can read subscribers" ON newsletter_subscribers
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid()
        AND role IN ('admin', 'manager')
    )
  );

-- Index for dedup lookups
CREATE INDEX IF NOT EXISTS idx_newsletter_subscribers_email ON newsletter_subscribers(email);
