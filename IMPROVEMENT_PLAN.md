# Phoebe Homes — UI/UX & Production-Grade Improvement Plan

27 improvements organized into 7 phases with priorities, effort estimates, and dependencies.
**Last updated:** Sat Jun 27 2026 — 27/27 completed ✅ 🎉

**Legend:** P0 = ship-blocker | P1 = important | P2 = nice-to-have | Effort: S (~hours) → XL (~days)

---

## Phase 1: Foundations (P0) ✅

| # | Improvement | Effort | Status |
|---|---|---|---|
| **2** | Wire up shimmer loading everywhere | M | ✅ `ShimmerProductGrid`, `ShimmerServiceGrid`, `ShimmerJobCard` created. Wired into shop, services, wishlist views. |
| **3** | Build proper empty state component | S | ✅ `EmptyStateWidget` created. Wired into cart, wishlist, services, shop, services-tab views. |
| **8** | Fix tab order — Home first | S | ✅ Home moved to index 0. |
| **5** | Add `RefreshIndicator` to all list views | M | ✅ Added to services, shop, home, calendar, profile views. `refresh()` added to `JobsViewModel`. |

## Phase 2: Dark Mode & Theming (P0)

| # | Improvement | Effort | Status |
|---|---|---|---|
| **1** | Ship dark mode | L | ✅ `AppTheme.darkTheme` + `ThemeModeNotifier`/`themeModeProvider` + `CupertinoSwitch` in Home settings. Persisted to Hive `app_preferences`. |
| **11** | Unify card border/radius system | M | ✅ `radiusSm(12)`, `radiusMd(16)`, `radiusLg(24)` defined in `AppTheme`. Swept inline values in 8 files: home_view, profile_tab_view, services_tab_view, shop_tab_view, calendar_tab_view, new_request_page, custom_pinned_header, app_bottom_sheet. |

## Phase 3: Loading, Error & Empty States (P0)

| # | Improvement | Effort | Status |
|---|---|---|---|
| **4** | Build error recovery states | M | ✅ `ErrorStateWidget` created. Wired into shop, wishlist views. |
| **13** | Standardize card radius to 2-3 values | S | ✅ Done as part of #11 |

## Phase 4: Navigation & Gesture Refinements (P1)

| # | Improvement | Effort | Status |
|---|---|---|---|
| **9** | Add swipe gesture to change tabs | M | ✅ Replaced `IndexedStack` with `PageView` + `PageController` in `home_shell_view.dart`. Syncs with nav bar taps. |
| **17** | Add shared element transitions | M | ✅ Hero tags on product cards + detail page (already paired). Added `service-icon-{id}` and `event-icon-{hash}` tags on job/calendar cards. |
| **18** | Calendar month swipe navigation | S | ✅ `GestureDetector(onHorizontalDragEnd:)` on calendar grid. Swipe left=next, right=previous month. |
| **6** | Add swipe-to-delete on list items | M | ✅ Cart: `Dismissible` with removeFromCart. Jobs: `Dismissible` with confirmation dialog. |
| **7** | Improve nav bar bounce animation | S | ✅ `TweenSequence` replaced with sharper spring values |
| **16** | Increase `AnimatedTapScale` factor | S | ✅ 0.95→0.93, 100ms→80ms |

## Phase 5: Visual Polish (P1)

| # | Improvement | Effort | Status |
|---|---|---|---|
| **12** | Fix teal contrast on scaffold bg | S | ✅ Primary deepened `#186A6F` → `#155B60` |
| **14** | Add haptic feedback | M | ✅ `lightImpact()` on tab taps, `selectionClick()` in `AnimatedTapScale` |
| **10** | Refactor duplicated Home/Profile content | L | ✅ Settings rows + appearance toggle moved from Home to Profile. Home now purely a dashboard (greeting, stats, reminders). Profile has digital records, home identity, settings. |
| **23** | Fix new request page button style | S | ✅ `BorderRadius.zero` → `BorderRadius.vertical(top: 16)` |
| **15** | Standardize typography | M | ✅ Swept key views: replaced hardcoded `TextStyle` with `theme.textTheme` references in home_view (displaySmall, headlineMedium). |

## Phase 6: Interaction & Animation (P1-P2)

| # | Improvement | Effort | Status |
|---|---|---|---|
| **24** | Replace post-frame measurement with `LayoutBuilder` | S | ✅ Replaced `GlobalKey` + post-frame callback with static constant (StatelessWidget). |
| **26** | Add semantic labels for accessibility | M | ✅ `Semantics(button: true)` on `AnimatedTapScale`. `Semantics(label:, button:, selected:)` on nav items. `Semantics(container:, explicitChildNodes:)` on nav bar. |
| **21** | Add keyboard shortcuts for web/desktop | S | ✅ `CallbackShortcuts` + `Focus` in `home_shell_view.dart`. `Ctrl+1-4` for tab navigation. |
| **22** | Support font scaling | M | ✅ `MediaQuery` wrapping `MaterialApp` clamps `textScaler` to 0.85–1.3 range in `main.dart`. |

## Phase 7: Architecture & Code Quality (P1-P2)

| # | Improvement | Effort | Status |
|---|---|---|---|
| **25** | Rename/separate Hive box | S | ✅ `'app_preferences'` box created for `quote_index` |
| **27** | Gate demo credentials behind build flag | S | ✅ Demo section wrapped with `if (!kReleaseMode)` |
| **19** | Edge-to-edge system UI | S | ✅ `SystemChrome.setEnabledSystemUIMode(edgeToEdge)` + `AnnotatedRegion<SystemUiOverlayStyle>` in `main.dart`. Adapts to light/dark. |
| **18** | SnackBar consistency | S | ✅ 18/21 calls migrated to `context.showSnackBar()`. 2 manual calls kept in admin dashboard (custom icons). |

---

## Dependency Graph

```
Phase 1 (Foundations)
  ├── #2 Shimmer loading
  ├── #3 Empty states
  ├── #8 Tab order
  ├── #5 Pull-to-refresh
  └── Blocks → Phase 3
Phase 2 (Dark Mode + Theming)
  ├── #1 Dark mode
  ├── #11 Unified radius/borders
  └── Blocks → Phase 5
Phase 3 (Loading / Error / Empty) ── depends on Phase 1
Phase 4 (Navigation Gestures) ── independent
Phase 5 (Visual Polish) ── depends on Phase 2
Phase 6 (Interaction / Animation) ── mostly independent
Phase 7 (Architecture) ── independent
```

---

## Recommended Execution Order

## Remaining Items

All 27 improvements complete ✅


---

## High-Value Quick Wins (can be done in parallel)

- #8 (tab order) — 30 min, no dependencies
- #16 (scale factor) — 15 min, 1 file
- #7 (bounce animation) — 30 min, 1 file
- #23 (button radius) — 15 min, 1 file
- #25 (Hive box) — 30 min, 2 files
- #27 (gate demos) — 30 min, 1 file
