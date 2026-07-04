# Phoebe Homes

Property management platform connecting tenants, workers, and property managers.

## Apps

| App | Directory | Description |
|-----|-----------|-------------|
| Customer | `apps/customer_app` | Tenant portal — shop, collections, service requests |
| Worker | `apps/worker_app` | Job dispatch, scheduling, maintenance work |
| Staff | `apps/staff_app` | Property management, admin dashboards, approvals |

## Setup

```sh
# Get dependencies (Dart workspace resolves all packages)
flutter pub get

# Run with Supabase credentials (required)
flutter run --dart-define SUPABASE_URL=<url> --dart-define SUPABASE_ANON_KEY=<key>

# App-specific run
flutter run -t apps/customer_app/lib/main.dart --dart-define SUPABASE_URL=... --dart-define SUPABASE_ANON_KEY=...
flutter run -t apps/worker_app/lib/main.dart --dart-define SUPABASE_URL=... --dart-define SUPABASE_ANON_KEY=...
flutter run -t apps/staff_app/lib/main.dart --dart-define SUPABASE_URL=... --dart-define SUPABASE_ANON_KEY=...
```

## Develop

```sh
flutter analyze        # 0 warnings, 0 errors target
flutter test           # 66+ tests
```

## Architecture

```
apps/
├── customer_app/    — Customer-facing (shop, cart, service requests)
├── worker_app/      — Worker (job dispatch, scheduling)
└── staff_app/       — Staff/admin (properties, products, approvals)
packages/
└── phoebe_core/     — Shared: models, repos, services, UI
```

Core patterns:
- **State:** Riverpod (StreamProvider, StateNotifierProvider)
- **Backend:** Supabase (auth, Postgres, realtime streams)
- **Cache:** Hive (LocalCacheService — cache-on-data, cache-fallback-on-error)
- **Routing:** GoRouter (file-based in router.dart)
- **Auth:** Row-level security via Supabase policies + `worker_status` column

## Key Commands

```sh
# Run all tests
flutter test

# Run single test file
flutter test packages/phoebe_core/test/cart_view_model_test.dart

# Analyze
flutter analyze
```
