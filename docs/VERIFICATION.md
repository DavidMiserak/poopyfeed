# Persona Feature Verification Report

**Date**: 2026-02-28
**Scope**: Full audit of Angular frontend against all three persona requirements (Mom/Sarah,
Dad/Michael, Maria/Nanny). Covers functionality, accessibility, code quality, and E2E test
coverage.

---

## Persona Feature Status

### Overall: ✅ Core Features Working

All primary persona workflows are implemented. Previously reported issues (P1–P7) have
been fixed. See **Issues Found** for details; each is marked **✅ Fixed**.

### Feature Matrix

<!-- markdownlint-disable MD060 -->

| Feature                                        | Mom  | Dad  | Maria | Status                     |
| ---------------------------------------------- | ---- | ---- | ----- | -------------------------- |
| Quick-Log (Wet/Dirty/Both diaper, Nap, Bottle) | ✅✅ | ✅   | ✅✅  | ✅ LIVE                    |
| Today's Summary Cards                          | ✅✅ | ✅   | ✅    | ✅ LIVE                    |
| Recent Activity Feed                           | ✅✅ | ✅✅ | ✅    | ✅ LIVE                    |
| Feeding / Diaper / Nap forms (full CRUD)       | ✅   | ✅   | ✅    | ✅ LIVE                    |
| Analytics Charts (feeding, diaper, sleep)      | ✅✅ | ✅✅ | —     | ✅ LIVE                    |
| CSV / PDF Export                               | —    | ✅✅ | —     | ✅ LIVE                    |
| Catch-Up Mode (batch logging)                  | ✅   | ✅   | ✅✅  | ✅ LIVE                    |
| Timeline View (7-day history)                  | ✅   | ✅✅ | ✅    | ✅ LIVE (via Advanced hub) |
| Sharing System (invite, accept, revoke)        | ✅   | ✅✅ | ✅    | ✅ LIVE                    |
| Push Notifications (bell, drawer, mark-read)   | ✅   | ✅✅ | —     | ✅ LIVE                    |
| Per-Child Notification Preferences             | ✅   | ✅   | —     | ✅ LIVE (child edit form)  |
| Quiet Hours (account settings)                 | ✅   | ✅   | —     | ✅ LIVE                    |
| Feeding Reminders (interval picker)            | ✅✅ | ✅   | —     | ✅ LIVE (child edit form)  |
| Feeding Overdue Pill (child list)              | ✅✅ | ✅   | —     | ✅ LIVE                    |
| Loading Spinners on all navigation             | ✅✅ | ✅   | ✅✅  | ✅ LIVE                    |
| Toast Notifications on all async ops           | ✅   | ✅   | ✅✅  | ✅ LIVE                    |
| Role-Based Access (owner/co-parent/caregiver)  | ✅   | ✅   | ✅    | ✅ LIVE                    |

<!-- markdownlint-enable MD060 -->

---

## Issues Found

### P1 — Dashboard: Recent Activity Never Rendered — ✅ Fixed

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

### P2 — Accessibility: Child List Cards Not Keyboard-Navigable (WCAG 2.1 AA) — ✅ Fixed

**Impact**: Users who rely on keyboard navigation. Each child card is a `<div (click)>` with
no `role`, `tabindex`, or keyboard event handler — not reachable by Tab and not activatable
by Enter/Space. This fails AXE and WCAG 2.1 AA (Success Criterion 2.1.1).

**Fix**: Add `role="button"`, `tabindex="0"`, `(keydown.enter)="navigateToChild(child.id)"`,
and `(keydown.space)="navigateToChild(child.id)"` to the card `<div>`.

**Files**: `front-end/poopyfeed/src/app/children/list/children-list.html` and `children-list.ts`

---

### P3 — Guideline Violation: `@HostListener` in Notification Bell — ✅ Fixed

**Impact**: Code quality. `notification-bell.ts` line 83 uses `@HostListener('document:click')`
which CLAUDE.md explicitly forbids. Must use the `host` object in `@Component` instead.

**Fix**: Move to `host: { '(document:click)': 'onDocumentClick($event)' }`.

**File**: `front-end/poopyfeed/src/app/components/notification-bell/notification-bell.ts`

---

### P4 — Guideline Violation: Explicit `standalone: true` in 12 Components — ✅ Fixed

**Impact**: Code quality. Angular 21 makes standalone the default; explicit `standalone: true`
is prohibited by CLAUDE.md. Affects 12 component files (all in `components/` and `contact/`).

**Fix**: Remove `standalone: true,` from each `@Component` decorator. No behaviour change.

**Files**: All 11 shared components + `contact/contact.ts`

---

### P5 — Missing Success Toasts on Share Revoke / Delete Invite — ✅ Fixed

**Impact**: UX inconsistency. Every other async operation in the app shows `toast.success()`.
Share revoke and invite delete show errors on failure but give no feedback on success — users
don't know if the action worked.

**Fix**: Add `this.toast.success('Access revoked')` and `this.toast.success('Invite deleted')`
in the `next:` callbacks of the two operations.

**File**: `front-end/poopyfeed/src/app/children/sharing/sharing-manage.ts`

---

### P6 — SSR-Unsafe `window.location.origin` in Sharing — ✅ Fixed

**Impact**: Server-side rendering. `sharing-manage.ts` line 195 accesses `window.location.origin`
directly, which throws `ReferenceError` during SSR. The sharing route uses `RenderMode.Server`
for parameterised routes so this path can be reached server-side.

**Fix**: Inject `DOCUMENT` from `@angular/common` and use `this.document.location.origin`,
which is SSR-safe.

**File**: `front-end/poopyfeed/src/app/children/sharing/sharing-manage.ts`

---

### P7 — Orphaned File — ✅ Fixed

`front-end/poopyfeed/src/app/children/feedings/form/feeding-form-polished.html` (257 lines)
is not imported or referenced anywhere — a leftover draft from development.

**Fix**: Delete the file. (File has been removed.)

---

## E2E Test Coverage

### Covered by E2E tests

The following gaps from the original audit are now covered:

<!-- markdownlint-disable MD060 -->

| Area                                               | Persona impact | Spec / notes                                       |
| -------------------------------------------------- | -------------- | -------------------------------------------------- |
| Quick-Log buttons (diaper, nap, bottle + toasts)   | Mom, Maria     | `e2e/quick-log.e2e.spec.ts`                        |
| Catch-Up mode (wizard, add/edit/delete events)     | Maria          | `e2e/catch-up.e2e.spec.ts`                         |
| Edit/Delete feedings                               | All            | `e2e/feedings.e2e.spec.ts` + `tracking-helpers.ts` |
| Edit/Delete diapers                                | All            | `e2e/diapers.e2e.spec.ts`                          |
| Edit/Delete naps                                   | All            | `e2e/naps.e2e.spec.ts`                             |
| CSV export                                         | Dad            | `e2e/analytics.e2e.spec.ts`                        |
| Child dashboard (Today's Summary, Recent Activity) | All            | `e2e/dashboard-content.e2e.spec.ts`                |

<!-- markdownlint-enable MD060 -->

### Remaining E2E gaps

<!-- markdownlint-disable MD060 -->

| Gap                                    | Persona impact              |
| -------------------------------------- | --------------------------- |
| Timeline view                          | Dad — core feature          |
| Quiet hours settings page              | All                         |
| PDF export (async job + download)      | Dad                         |
| Keyboard navigation (child list cards) | Accessibility (WCAG 2.1 AA) |

<!-- markdownlint-enable MD060 -->

These remaining gaps are separate work items (writing E2E tests), not regressions.

---

## Out of Scope / Future Work

The following issues were found but are lower priority or require larger changes:

<!-- markdownlint-disable MD060 -->

| Issue                                                                                          | Reason Deferred                         |
| ---------------------------------------------------------------------------------------------- | --------------------------------------- |
| `confirm()` dialogs in sharing and catch-up                                                    | Requires styled modal; separate UX work |
| `: any` type annotations in `catch-up.ts`                                                      | Non-breaking; code quality cleanup      |
| `navigateToDashboard()` in sharing/catch-up navigates to `/advanced`                           | Cosmetic rename                         |
| Analytics `hasAnyData` doesn't check weekly summary                                            | Edge-case, low frequency                |
| E2E test coverage for remaining gaps (timeline, dashboard content, quiet hours, PDF, keyboard) | Separate test-writing task              |

<!-- markdownlint-enable MD060 -->
