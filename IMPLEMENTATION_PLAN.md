# Security Fix Implementation Plan

## Phase 1 — CRITICAL (Do First)

### 1.1 Remove Firebase Admin SDK Key from Git

- [ ] Purge `pheobe-ee0a3-firebase-adminsdk-fbsvc-24442c6f82.json` from git history using `git filter-branch` or `bfg-repo-cleaner`
- [ ] Rotate the Firebase service account key in GCP Console
- [ ] Add `*.json` patterns to `.gitignore` for any future service account keys

### 1.2 Remove Root-Level Firebase Config Files

- [ ] Delete `google-services (customer).json`, `google-services (staff).json`, `google-services (Worker).json` from repo root
- [ ] Delete `GoogleService-Info(CustomerIOS).plist`, `GoogleService-Info(StaffIOS).plist`, `GoogleService-Info(WorkerIOS).plist` from repo root
- [ ] Update `.gitignore` to exclude these patterns at root level

### 1.3 Switch to Magic Links + GoodSender SMTP

**File:** `supabase/config.toml:196-220`
- [ ] Enable magic link auth in Supabase dashboard (Settings > Authentication > Providers > Email > Magic Link)
- [ ] Enable `secure_password_change = true`
- [ ] Set `minimum_password_length = 8` (as fallback for edge cases)

**File:** `supabase/config.toml` — add SMTP section:
```toml
[auth.email.smtp]
host = "smtp.goodsender.com"
port = 587
user = "SMTP_Injection"
pass = "<API_KEY>"
```
- [ ] Sign up at [goodsender.com](https://goodsender.com) — 100K emails/mo free, no credit card
- [ ] Verify sending domain (add SPF, DKIM, DMARC DNS records)
- [ ] Create SMTP credentials and add to config

**UI changes:**
**File:** `packages/fijadora_core/lib/ui/features/auth/views/login_view.dart`
- [ ] Replace password login UI with email-only input + "Send Magic Link" button
- [ ] Remove demo accounts section entirely (was already planned in 2.2)

**File:** `packages/fijadora_core/lib/ui/features/auth/views/register_view.dart`
- [ ] Convert to email collection for magic link sign-up (no password registration)

**File:** `packages/fijadora_core/lib/ui/features/auth/view_models/auth_view_model.dart`
- [ ] Replace `signIn()` call with `client.auth.signInWithOtp(email:)`
- [ ] Remove `signUp()` with password — use magic link instead
- [ ] Keep `signOut()` and `resetPassword()` as-is

### 1.4 Encrypt Hive Local Storage

**File:** `packages/fijadora_core/lib/data/services/local_cache_service.dart:11`
- [ ] Generate or derive an encryption key at app startup (store via `flutter_secure_storage` or `crypto` + device ID)
- [ ] Replace `Hive.openBox(_boxName)` with `Hive.openBox(_boxName, encryptionCipher: HiveAesCipher(key))`

**File:** `packages/fijadora_core/lib/app_entry.dart:60-61`
- [ ] Encrypt `app_preferences` box similarly

### 1.5 Fix Release Signing Config

**File:** `apps/customer_app/android/app/build.gradle.kts:40`
**File:** `apps/staff_app/android/app/build.gradle.kts:40`
**File:** `apps/worker_app/android/app/build.gradle.kts:40`
- [ ] Replace `signingConfig = signingConfigs.getByName("debug")` with reference to a release keystore
- [ ] Document how to generate the keystore: `keytool -genkey -v -keystore release.keystore -alias fijadora -keyalg RSA -keysize 2048 -validity 10000`
- [ ] Add `release.keystore` to `.gitignore`; store password in CI secrets

---

## Phase 2 — HIGH

### 2.1 Implement SSL Certificate Pinning

**File:** `packages/fijadora_core/lib/data/services/supabase_service.dart:44-69`
- [ ] Remove the `!kReleaseMode` bypass — pinning must work in all modes
- [ ] Keep the `SUPABASE_CERT_FINGERPRINT` check but remove the debug bypass
- [ ] Add a fallback: if fingerprint hex is empty, still validate against system CA store (don't use `badCertificateCallback` at all)
- [ ] Document how to obtain the Supabase API gateway SHA-256 fingerprint

### 2.2 Remove Hardcoded Demo Credentials

**File:** `packages/fijadora_core/lib/ui/features/auth/views/login_view.dart:51-55,240-327`
- [ ] Remove `_useCredentials()` method entirely
- [ ] Remove the entire demo accounts UI section (lines 240-327)
- [ ] If demo accounts are still needed for development, move them to a separate dev-only tool that reads from environment variables, not hardcoded strings

### 2.3 Fix Weak Seed Account Passwords

**File:** `supabase/seed.sql:6-9`
- [ ] Replace `extensions.crypt('password', ...)` with properly generated bcrypt hashes
- [ ] Update seed passwords to strong values (passwords should be unique per account)
- [ ] Document that seed accounts must have passwords rotated immediately if run against production

### 2.4 Fix Insecure Deep Link Token Handling

**File:** `packages/fijadora_core/lib/data/services/deep_link_service.dart:70-74`
- [ ] Replace `.contains('access_token')` with proper URI fragment parsing
- [ ] Use `uri.fragment.contains(...)` and then validate the fragment structure
- [ ] Add origin validation — verify the deep link came from a trusted source

**File:** `packages/fijadora_core/lib/app_entry.dart:106-110`
- [ ] Apply the same fix to the initial deep link handler

### 2.5 Lock Down Storage RLS Policies

**File:** `supabase/migrations/20260734_fix_storage_rls.sql:13-24`
- [ ] Restrict `product-images` bucket mutations to staff/admin roles only:
  - `INSERT`: only `auth.jwt() ->> 'role' IN ('admin', 'manager')`
  - `UPDATE`: only `auth.jwt() ->> 'role' IN ('admin', 'manager')`
  - `DELETE`: only `auth.jwt() ->> 'role' IN ('admin', 'manager')`
- [ ] Keep SELECT for all authenticated users (product browsing)
- [ ] Consider adding a bucket-level size/type restriction via edge function

### 2.6 Implement Tenant-Specific RLS

**File:** `supabase/migrations/20260730_tenant_read_policies_and_seeding.sql:5-15`
- [ ] Replace generic `auth.role() = 'authenticated'` SELECT policies with occupant-based checks:
  - `properties`: user can read properties they are linked to via `property_occupants`
  - `units`: user can read units belonging to their properties (join through property_occupants)
  - `rooms`: user can read rooms belonging to their units
  - `assets`: user can read assets belonging to their rooms
- [ ] For staff/worker roles, allow reading all properties (they need to see assignments)
- [ ] Create a helper function to get user's accessible property IDs

### 2.7 Sanitize Error Messages Shown to Users

**File:** `packages/fijadora_core/lib/ui/features/auth/views/login_view.dart:44`
**File:** `packages/fijadora_core/lib/ui/features/auth/views/register_view.dart:56`
**File:** `packages/fijadora_core/lib/ui/features/auth/views/reset_password_view.dart:40`
**File:** `packages/fijadora_core/lib/ui/features/auth/view_models/auth_view_model.dart:51`
- [ ] Create a user-friendly error mapping that strips internal details
- [ ] Map `AuthApiException` codes to generic messages like "Invalid email or password"
- [ ] Never forward `e.toString()` directly to UI
- [ ] Log the full error internally via CrashReportingService

### 2.8 Remove or Guard All debugPrint Calls

Systematic check across all files (24 occurrences):
- [ ] Convert `debugPrint('$sensitiveData')` to structured logging via CrashReportingService
- [ ] For deep link URIs: log only the path, strip query params
- [ ] For FCM tokens: log only first 4 chars + "..."
- [ ] For auth errors: log only error type, not full message
- [ ] For stack traces: log via dedicated error service only

Key files to fix:
- `packages/fijadora_core/lib/data/services/deep_link_service.dart:27,49`
- `packages/fijadora_core/lib/data/services/supabase_service.dart:38-39`
- `packages/fijadora_core/lib/data/services/push_notification_service.dart:41,179`
- `packages/fijadora_core/lib/data/repositories/auth_repository.dart:67,161,186`
- `packages/fijadora_core/lib/app_entry.dart:52,63,70,113,123,132`

### 2.9 Implement Real Client-Side Rate Limiting

**File:** `packages/fijadora_core/lib/ui/features/auth/views/login_view.dart`
- [ ] Add a rate limiter: max 5 login attempts per 60 seconds
- [ ] Disable the sign-in button and show a countdown timer on rate limit
- [ ] Add exponential backoff for rapid retries

**File:** `packages/fijadora_core/lib/ui/features/auth/views/register_view.dart`
- [ ] Same rate limiting for sign-up attempts

---

## Phase 3 — MEDIUM

### 3.1 Enhance FCM Token Storage

**File:** `packages/fijadora_core/lib/data/services/push_notification_service.dart:174-177`
- [ ] Consider encrypting FCM tokens at rest in the DB
- [ ] Add RLS to `fcm_tokens` table so users can only read/update their own tokens
- [ ] Add a trigger to automatically remove tokens for deleted users

### 3.2 Improve Auth Error Handling & Stream Resilience

**File:** `packages/fijadora_core/lib/data/repositories/auth_repository.dart:55-84`
- [ ] Add error handler to `_authSubscription` that re-subscribes on failure
- [ ] Add a retry mechanism with backoff for the auth state stream

### 3.3 Audit & Minimize SECURITY DEFINER Functions

**File:** `supabase/migrations/20260712_fix_rls_with_security_definer.sql:9-21` (is_admin)
**File:** `supabase/migrations/20260733_rls_fixes.sql:47-78` (assign_job)
**File:** `supabase/migration.sql:264-277,310-312` (handle_new_user, get_user_names)
- [ ] Review each SECURITY DEFINER function for input validation
- [ ] Add explicit parameter validation to `assign_job` (verify caller is admin)
- [ ] Add row-level access checks inside `get_user_names` (limit to users in same property)
- [ ] Document why each function needs SECURITY DEFINER
- [ ] Consider replacing `get_user_names` with a direct view that respects RLS

### 3.4 Add Input Validation to OpenRouter Edge Function

**File:** `supabase/functions/openrouter-proxy/index.ts:16-31`
- [ ] Add max length restriction on messages (e.g., 4096 chars total)
- [ ] Whitelist allowed models instead of accepting arbitrary user input
- [ ] Add maxTokens cap enforced server-side (512)
- [ ] Add usage rate limiting per user

### 3.5 Remove Linked Supabase Project File

- [ ] Delete `supabase/.temp/linked-project.json`
- [ ] Add `.temp/` to `.gitignore`

---

## Phase 4 — LOW

### 4.1 Fix AndroidManifest INTERNET Permission

**File:** `apps/*/android/app/src/debug/AndroidManifest.xml:6`
- [ ] Move `<uses-permission android:name="android.permission.INTERNET"/>` to `src/main/AndroidManifest.xml`
- [ ] Remove from debug/manifest since it should be in all builds

### 4.2 Add Sentry PII Stripping

**File:** `packages/fijadora_core/lib/data/services/crash_reporting_service.dart`
- [ ] Add `options.sendDefaultPii = false` (verify it's already false)
- [ ] Add a before-send callback to strip email addresses and tokens from error messages
- [ ] Review trace sample rate (0.2 = 20%) — consider lowering for production

### 4.3 Configure iOS App Transport Security

**File:** `apps/*/ios/Runner/Info.plist`
- [ ] Add `NSAppTransportSecurity` with `NSAllowsArbitraryLoads = false`
- [ ] Add `NSRequiresCertificateTransparency = true`
- [ ] Add specific exception domains only if needed

### 4.4 Cleanup Debug/Profile Manifest Duplication

- [ ] Review `apps/*/android/app/src/profile/AndroidManifest.xml` — remove if identical to debug
- [ ] Consolidate common manifest entries into the main manifest

---

## Summary

| Phase | Items | Est. Effort |
|-------|-------|-------------|
| 1 — CRITICAL | 5 | 1-2 days |
| 2 — HIGH | 9 | 3-4 days |
| 3 — MEDIUM | 5 | 2-3 days |
| 4 — LOW | 4 | 0.5 day |
| **Total** | **23** | **~7-10 days** |
