# Phoebe Homes - Phased Implementation Guide (Post-Worker-Flow)

This document maps out the remaining developmental phases to complete the Phoebe Homes application, excluding payments (handled by another team). It provides the full architectural context and file guidelines to ensure seamless implementation continuity.

---

## Current Architecture & State Context

1. **Authentication:** Uses `AuthRepository` with dynamic mock fallback (emails containing `@.*worker.*` get routed to `UserRole.worker`, others default to `UserRole.customer`).
2. **Services (Jobs):** UI lives in `lib/ui/features/services/views/services_tab_view.dart`. State managed by `JobsViewModel`.
3. **Worker Flow:** UI lives in `lib/ui/features/worker/views/worker_dashboard_view.dart` and `worker_job_details_view.dart`. Handles travel, clock-in, live ticking timers, and completions.
4. **Router:** Located in `lib/ui/core/router.dart`. The `/` route dynamically routes workers to `WorkerDashboardView` and customers to the bottom navigation `HomeShellView`.

---

## Phase 1: Shop & Cart Infrastructure (Furniture Marketplace)

**Objective:** Transform the current static shop mockup into a fully functional product listing, shopping cart, and mock reservation system.

### 1. Data Models
Create a product model supporting category classification, reviews, and deposits:
- **File:** `lib/domain/models/product.dart`
- **Fields:** `id` (UUID), `name`, `description`, `price`, `imageUrl`, `category`, `inventoryCount`, `isReserved`.

### 2. Shop Repository
Implement a repository to query catalog items:
- **File:** `lib/data/repositories/shop_repository.dart`
- **Actions:** `fetchProducts()`, `reserveProduct(String id)`, `updateInventory(String id, int quantity)`. Add standard local mock data fallback.

### 3. Cart State Management
Manage the user's shopping basket using Riverpod:
- **File:** `lib/ui/features/shop/view_models/cart_view_model.dart`
- **State:** `Map<Product, int>` (representing item and quantity).
- **Actions:** `addToCart()`, `removeFromCart()`, `clear()`, `checkoutReservation()`.

### 4. UI Refinement
Update the existing shop tab view:
- **Files:**
  - `lib/ui/features/shop/views/shop_tab_view.dart`: Bind with `ref.watch(shopRepository)` instead of hardcoded maps.
  - `lib/ui/features/shop/views/product_detail_view.dart` [NEW]: Display description, image, inventory, and "Add to Cart" button.
  - `lib/ui/features/shop/views/cart_view.dart` [NEW]: List items, show summary, and handle "Confirm Reservation" button.

---

## Phase 2: Admin & Property Manager Portals

**Objective:** Build dashboards for operational staff (Admins) and building managers to oversee maintenance queues and worker performance.

### 1. Router Updates
Configure `router.dart` `/` builder to support additional roles:
- `UserRole.admin` -> `AdminDashboardView`
- `UserRole.manager` -> `ManagerDashboardView`

### 2. Admin Dashboard
- **File:** `lib/ui/features/admin/views/admin_dashboard_view.dart` [NEW]
- **Features:**
  - **Job Queue:** Lists all active, pending, and unassigned jobs.
  - **Assign Action:** Dropdown to assign an unassigned job (`status == JobStatus.pending`) to a worker (loaded from a list of workers).
  - **Analytics Tab:** Simple clean cards showing responses, total revenue, and active issues.

### 3. Property Manager Portal
- **File:** `lib/ui/features/manager/views/manager_dashboard_view.dart` [NEW]
- **Features:**
  - **Property Overview:** Lists properties, rooms, and appliances.
  - **History Checker:** View maintenance histories for specific assets (tying in with `profile_tab_view.dart` card concepts).

---

## Phase 3: AI Assist (Gemini Integration)

**Objective:** Leverage Google Gemini (Gemini 2.5 Flash / Vision) to diagnose maintenance requests from photos and recommend matching furniture.

### 1. Photo Diagnosis Logic
Add AI analysis inside the request service flow:
- **File:** `lib/data/services/gemini_service.dart` [NEW]
- **Functionality:**
  - Take user's uploaded image.
  - Call Gemini Vision to generate a **Problem Summary**, **Required Tools**, **Suggested Parts**, and **Priority level**.
  - Populate the service request description automatically with this data.

### 2. Predictive Reminders
Run routine client-side logic to trigger maintenance guidelines:
- **Logic:** Generate dynamic notifications in the Home Hub (e.g., "HVAC filter is due in 3 days based on seasonal timing").

---

## Phase 4: Telemetry, Logs & Push Notifications

**Objective:** Set up diagnostics and communications infrastructure.

### 1. Push Notifications
- **Service:** FCM (Firebase Cloud Messaging) or Supabase Broadcast.
- **Workflow:** Send notification to worker when a job is assigned. Send notification to customer when status changes to `En Route` or `Completed`.

### 2. Crash Reporting & Sentry
- Initialize Sentry in `main.dart`.
- Ensure all repositories log caught network/database exceptions to Sentry for tracing.

---

## Phase 5: Design Polish & Performance

**Objective:** Perfect the user experience with minimalist, ultra-smooth premium styling.

### 1. Micro-Animations & Skeleton Loaders
- Implement shimmer layout lists (`shimmer` package or custom fading cards) while database queries run.
- Keep touch targets large (minimum 48px).

### 2. Offline Support & Sync
- Integrate `Hive` database to cache job status updates on the worker's device and synchronize when internet connection is restored.
