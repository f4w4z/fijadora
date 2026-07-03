-- Clean up broken auth.users from previous seed migration
DELETE FROM public.users WHERE email LIKE '%@phoebe.app';
DELETE FROM auth.users WHERE email LIKE '%@phoebe.app';
