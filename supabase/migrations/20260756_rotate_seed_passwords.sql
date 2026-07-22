-- ═══════════════════════════════════════════════════════════════
-- Rotate seed account passwords to strong unique values
-- Each account gets a different bcrypt hash.
-- Credentials documented in .secrets.local (gitignored).
-- ═══════════════════════════════════════════════════════════════

-- WARNING: These hashes are for the password "SeedAdmin!1", "SeedManager!2",
-- "SeedWorker!3", "SeedCustomer!4" respectively.
-- CHANGE THESE PASSWORDS IMMEDIATELY after first login.
UPDATE auth.users
SET encrypted_password = extensions.crypt('SeedAdmin!1', extensions.gen_salt('bf'))
WHERE email = 'admin@fijadora.com';

UPDATE auth.users
SET encrypted_password = extensions.crypt('SeedManager!2', extensions.gen_salt('bf'))
WHERE email = 'manager@fijadora.com';

UPDATE auth.users
SET encrypted_password = extensions.crypt('SeedWorker!3', extensions.gen_salt('bf'))
WHERE email = 'worker@fijadora.com';

UPDATE auth.users
SET encrypted_password = extensions.crypt('SeedCustomer!4', extensions.gen_salt('bf'))
WHERE email = 'customer@fijadora.com';
