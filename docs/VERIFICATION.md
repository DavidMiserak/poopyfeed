# Persona Feature Verification Report

**Date**: 2026-02-28
**Scope**: Full audit of Angular frontend against all three persona requirements (Mom/Sarah,
Dad/Michael, Maria/Nanny). Covers functionality, accessibility, code quality, and E2E test
coverage.

---

## Persona Feature Status

### Overall: ✅ Core Features Working

All primary persona workflows are implemented. The critical bug is that the dashboard's
**Recent Activity feed is loaded but never rendered** — see Issues section below.

### Feature Matrix

| Feature                                        | Mom  | Dad  | Maria | Status                            |
| ---------------------------------------------- | ---- | ---- | ----- | --------------------------------- |
| Quick-Log (Wet/Dirty/Both diaper, Nap, Bottle) | ✅✅ | ✅   | ✅✅  | ✅ LIVE                           |
| Today's Summary Cards                          | ✅✅ | ✅   | ✅    | ✅ LIVE                           |
| Recent Activity Feed                           | ✅✅ | ✅✅ | ✅    | ❌ DATA LOADED, NOT RENDERED      |
| Feeding / Diaper / Nap forms (full CRUD)       | ✅   | ✅   | ✅    | ✅ LIVE                           |
| Analytics Charts (feeding, diaper, sleep)      | ✅✅ | ✅✅ | —     | ✅ LIVE                           |
| CSV / PDF Export                               | —    | ✅✅ | —     | ✅ LIVE                           |
| Catch-Up Mode (batch logging)                  | ✅   | ✅   | ✅✅  | ✅ LIVE                           |
| Timeline View (7-day history)                  | ✅   | ✅✅ | ✅    | ✅ LIVE (via Advanced hub)        |
| Sharing System (invite, accept, revoke)        | ✅   | ✅✅ | ✅    | ✅ LIVE                           |
| Push Notifications (bell, drawer, mark-read)   | ✅   | ✅✅ | —     | ✅ LIVE                           |
| Per-Child Notification Preferences             | ✅   | ✅   | —     | ✅ LIVE (child edit form)         |
| Quiet Hours (account settings)                 | ✅   | ✅   | —     | ✅ LIVE                           |
| Feeding Reminders (interval picker)            | ✅✅ | ✅   | —     | ✅ LIVE (child edit form)         |
| Feeding Overdue Pill (child list)              | ✅✅ | ✅   | —     | ✅ LIVE                           |
| Loading Spinners on all navigation             | ✅✅ | ✅   | ✅✅  | ✅ LIVE                           |
| Toast Notifications on all async ops           | ✅   | ✅   | ✅✅  | ⚠️ Missing on share revoke/delete |
| Role-Based Access (owner/co-parent/caregiver)  | ✅   | ✅   | ✅    | ✅ LIVE                           |

---

## Issues Found

### P1 — Dashboard: Recent Activity Never Rendered

**Impact**: All personas. The dashboard loads feedings, diapers, and naps, merges them into
a `recentActivity` signal (top 10 newest across all types), and even has a skeleton for this
card — but the live content block closes at line 297 without ever rendering it. The component
also computes navigation methods for Analytics, Timeline, and Catch-Up that go unused.

**Root cause**: Section was dropped during a template refactor; data loading was not cleaned up.

**Fix**: Add a "Recent Activity" card at the bottom of the live dashboard content block using
the existing `recentActivity()` signal, `formatActivityAge()`, and `getActivityIcon()` utilities
(all already imported in the component).

**File**: `front-end/poopyfeed/src/app/children/dashboard/child-dashboard.html`

---

### P2 — Accessibility: Child List Cards Not Keyboard-Navigable (WCAG 2.1 AA)

**Impact**: Users who rely on keyboard navigation. Each child card is a `<div (click)>` with
no `role`, `tabindex`, or keyboard event handler — not reachable by Tab and not activatable
by Enter/Space. This fails AXE and WCAG 2.1 AA (Success Criterion 2.1.1).

**Fix**: Add `role="button"`, `tabindex="0"`, `(keydown.enter)="navigateToChild(child.id)"`,
and `(keydown.space)="navigateToChild(child.id)"` to the card `<div>`.

**Files**: `front-end/poopyfeed/src/app/children/list/children-list.html` and `children-list.ts`

---

### P3 — Guideline Violation: `@HostListener` in Notification Bell

**Impact**: Code quality. `notification-bell.ts` line 83 uses `@HostListener('document:click')`
which CLAUDE.md explicitly forbids. Must use the `host` object in `@Component` instead.

**Fix**: Move to `host: { '(document:click)': 'onDocumentClick($event)' }`.

**File**: `front-end/poopyfeed/src/app/components/notification-bell/notification-bell.ts`

---

### P4 — Guideline Violation: Explicit `standalone: true` in 12 Components

**Impact**: Code quality. Angular 21 makes standalone the default; explicit `standalone: true`
is prohibited by CLAUDE.md. Affects 12 component files (all in `components/` and `contact/`).

**Fix**: Remove `standalone: true,` from each `@Component` decorator. No behaviour change.

**Files**: All 11 shared components + `contact/contact.ts`

---

### P5 — Missing Success Toasts on Share Revoke / Delete Invite

**Impact**: UX inconsistency. Every other async operation in the app shows `toast.success()`.
Share revoke and invite delete show errors on failure but give no feedback on success — users
don't know if the action worked.

**Fix**: Add `this.toast.success('Access revoked')` and `this.toast.success('Invite deleted')`
in the `next:` callbacks of the two operations.

**File**: `front-end/poopyfeed/src/app/children/sharing/sharing-manage.ts`

---

### P6 — SSR-Unsafe `window.location.origin` in Sharing

**Impact**: Server-side rendering. `sharing-manage.ts` line 195 accesses `window.location.origin`
directly, which throws `ReferenceError` during SSR. The sharing route uses `RenderMode.Server`
for parameterised routes so this path can be reached server-side.

**Fix**: Inject `DOCUMENT` from `@angular/common` and use `this.document.location.origin`,
which is SSR-safe.

**File**: `front-end/poopyfeed/src/app/children/sharing/sharing-manage.ts`

---

### P7 — Orphaned File

`front-end/poopyfeed/src/app/children/feedings/form/feeding-form-polished.html` (257 lines)
is not imported or referenced anywhere — a leftover draft from development.

**Fix**: Delete the file.

---

## E2E Test Coverage Gaps

The E2E suite covers 11 files and happy-path flows but has significant gaps:

| Gap                                                      | Persona Impact                         |
| -------------------------------------------------------- | -------------------------------------- |
| Quick-Log buttons (zero tests)                           | Mom, Maria — primary daily UI untested |
| Catch-Up mode (zero tests)                               | Maria — core feature, zero coverage    |
| Timeline view (zero tests)                               | Dad — core feature, zero coverage      |
| Child dashboard content (Today Summary, Recent Activity) | All                                    |
| Edit/Delete for feedings, diapers, naps                  | All                                    |
| Quiet hours settings page                                | All                                    |
| PDF export                                               | Dad                                    |
| Keyboard navigation                                      | Accessibility                          |

These gaps represent a separate work item (writing E2E tests), not regressions.

---

## Out of Scope / Future Work

The following issues were found but are lower priority or require larger changes:

| Issue                                                                | Reason Deferred                         |
| -------------------------------------------------------------------- | --------------------------------------- |
| `confirm()` dialogs in sharing and catch-up                          | Requires styled modal; separate UX work |
| `: any` type annotations in `catch-up.ts`                            | Non-breaking; code quality cleanup      |
| `navigateToDashboard()` in sharing/catch-up navigates to `/advanced` | Cosmetic rename                         |
| Analytics `hasAnyData` doesn't check weekly summary                  | Edge-case, low frequency                |
| E2E test coverage for all features listed above                      | Separate test-writing task              |
