# Feature: Frontend Feature Inventory

## Overview

This document enumerates the user-facing features that are **currently implemented** in the Angular frontend of PoopyFeed, grouped by functional area.
It is intended as a quick-reference map of what exists today so that deeper feature specs (in this folder) can link back to a single, canonical inventory.

Snapshot date: **2026-03-03**

### How to use this inventory

- **New to the codebase?** — Scan the section headings and bullet lists to see what the app does; use the route paths to find components in the front-end.
- **Writing or updating a feature spec?** — Link to this doc from your spec’s overview and add a “Related spec” link back here for your feature.
- **Planning a release or QA pass?** — Use the inventory as a checklist of user-facing areas to test or document.
- **Adding or removing a feature?** — Update the relevant group and, for new features, add a link to the dedicated spec in `docs/specs` if one exists.

---

## Current Feature Inventory

### 1. Access, Onboarding, and Shell

- **Public marketing pages**
    - **Routes**: `/`, `/contact`, `/privacy`, `/terms`
    - **Description**: Public landing experience explaining the app, plus contact form and legal pages.
- **Authentication (login & signup)**
    - **Routes**: `/login`, `/signup`
    - **Description**: Email/password login and signup forms backed by the Django/Djoser token API, including error messaging and loading states.
- **Accept invite flow**
    - **Route**: `/invites/accept/:token`
    - **Description**: Accepts a shared-child invite using a signed token link and attaches the child to the accepting user.
- **Account page**
    - **Route**: `/account`
    - **Description**: Authenticated account shell for managing logged-in user settings (including notification and quiet-hours settings, see below).

### 2. Children Management

- **Child list and selection**
    - **Route**: `/children`
    - **Description**: Lists all children the user can access, including role badges and last-activity summaries (last feeding/diaper/nap). An **Overdue** pill appears next to a child’s last activity when feeding is past the child’s reminder interval.
- **Child dashboard**
    - **Route**: `/children/:id/dashboard`
    - **Description**: Primary hub for a single child, summarizing recent activity, pattern alerts, and quick actions for tracking.
    - **Related spec**: `dashboard-performance.spec.md`
- **Child CRUD**
    - **Description**: Create, edit, and archive children via forms using `Child` model and backing `children.service.ts`.

### 3. Tracking: Feedings, Diapers, Naps

- **Feeding tracking (full CRUD)**
    - **Routes**: `/children/:id/feedings`, feeding create/edit subroutes
    - **Description**: Log bottle/breast feedings with volume, side, duration, and timestamps, including conditional validation and timezone-aware date handling.
- **Diaper tracking (full CRUD)**
    - **Routes**: `/children/:id/diapers`, diaper create/edit subroutes
    - **Description**: Log wet/dirty/both diaper changes with timestamp and optional notes.
- **Nap tracking (full CRUD)**
    - **Routes**: `/children/:id/naps`, nap create/edit subroutes
    - **Description**: Log naps with start/end times, duration, and notes, including validation based on wake windows.
- **Catch-up / bulk logging**
    - **Route**: `/children/:id/catch-up`
    - **Description**: Bulk-entry workflow to quickly enter multiple historical feedings/diapers/naps after a gap.
    - **Related spec**: `catch-up-mode.spec.md`

### 4. Timeline & Activity History

- **Child timeline**
    - **Route**: `/children/:id/timeline`
    - **Description**: Unified chronological timeline of feedings, diapers, and naps with relative time labels (e.g., “2 hours ago”) and activity-specific icons. Time gaps between activities are shown; for gaps of 60 minutes or more, owners and co-parents can add a nap in place via an “Add nap” action that creates a nap spanning the gap.

### 5. Analytics, Patterns, and Export

- **Analytics dashboards**
    - **Route**: `/children/:id/analytics`
    - **Description**: Chart.js-based dashboards summarizing feeding, diaper, and sleep trends over configurable time ranges.
- **Data export (CSV/PDF)**
    - **Route**: `/children/:id/analytics/export`
    - **Description**: Export tracking data as CSV and PDF for sharing or personal archiving.
- **Pediatrician summary**
    - **Description**: Printable pediatrician-friendly report aggregating recent trends and key stats for a child.
    - **Related spec**: `pediatrician-summary.spec.md`
- **Pattern alerts**
    - **Description**: Frontend presentation of pattern alerts from the backend (e.g., overdue feedings, nap wake-window warnings) surfaced on dashboards and in notifications.
    - **Related spec**: `pattern-alerts.spec.md`
- **Advanced tools hub**
    - **Description**: Consolidated “advanced tools” area (e.g., analytics variants, exports, filters) for power users, with filtering and navigation helpers.
- **Fuss Bus**
    - **Route**: `/children/:id/fuss-bus`
    - **Description**: Guided troubleshooting wizard to help identify causes of a child's fussiness (crying, won't sleep, general fussiness, or refusing food for 12+ months), with a smart checklist that auto-checks recent feedings, diapers, and naps from tracking data and targeted soothing suggestions. Accessible from the child dashboard and Advanced Tools grid.
    - **Related spec**: `fuss-bus.spec.md`

### 6. Notifications, Reminders, and Quiet Hours

- **In-app notifications center**
    - **Description**: Notification list UI for pattern alerts, reminders, and system messages, including unread counts reflected on the dashboard.
    - **Related spec**: `notifications.spec.md`
- **Push notifications**
    - **Description**: Web push for time-sensitive events (e.g., feeding reminders, overdue alerts), built on top of the browser Notifications API and service worker integration.
- **Feeding/nap reminders**
    - **Description**: Reminder flows that schedule notifications when the next feeding or nap is due based on patterns and wake windows.
    - **Related spec**: `feeding-reminders.spec.md`
- **Quiet hours**
    - **Description**: User-configurable quiet hours that suppress non-critical notifications during configured time windows.
    - **Related specs**: `notifications.spec.md`, `feeding-reminders.spec.md`

### 7. Sharing, Roles, and Permissions

- **Child sharing & roles**
    - **Route**: `/children/:id/sharing`
    - **Description**: Manage sharing invitations and access roles (`owner`, `co-parent`, `caregiver`) for a child, including revoking access.
- **Invite management**
    - **Description**: View pending invites, resend or cancel invitations, and handle token-based acceptance (see “Accept invite flow” above).

### 8. Timezone-Aware Display

- **Timezone-aware timestamps**
    - **Description**: All timestamps shown in the user’s local timezone while stored as UTC in the backend; uses `DateTimeService` and `date.utils.ts`.
    - **Related spec**: `timezone-aware-display.spec.md`
- **Relative time helpers**
    - **Description**: Human-friendly “time ago” and age formatting on timelines, dashboards, and lists (e.g., `formatActivityAge`, `getChildAgeLong`).

### 9. PWA, Performance, and UX Enhancements

- **PWA installability**
    - **Description**: Web app manifest with icons, categories, and shortcuts, enabling install to home screen with a native-style standalone window.
- **Service worker & app shell**
    - **Description**: Angular service worker configuration that caches static assets (shell, lazy chunks, icons) but intentionally does not cache API responses.
- **Update banner**
    - **Description**: In-app banner that detects a new service worker version and offers a one-click “refresh to update” flow.
- **Navigation loading states**
    - **Description**: Consistent loading spinners and disabled states on navigation buttons to give immediate feedback for exhausted users.
- **Dashboard performance optimizations**
    - **Description**: Batched dashboard summary API and skeleton screens to reduce API round-trips and improve perceived load performance.
    - **Related spec**: `dashboard-performance.spec.md`
- **Accessibility and mobile-first design**
    - **Description**: WCAG 2.1 AA-focused UI with large tap targets, one-handed mobile-first layout, ARIA attributes, and strong contrast.

### 10. Cross-Platform and Parity

- **Android parity tracking**
    - **Description**: Frontend features aligned with the Android app’s tracking and analytics capabilities to ensure consistent experience across platforms.
    - **Related spec**: `android-feature-parity.spec.md`
- **Backend template parity**
    - **Description**: Frontend UX and data display remain aligned with backend API capabilities and templates.
    - **Related spec**: `backend-template-parity.spec.md`

---

## Functional Requirements (EARS-style) for This Inventory

- **FR-INV-001** — When a team member needs to understand what user-facing features currently exist in the frontend, the system shall provide this inventory document grouped by functional area.
- **FR-INV-002** — When a new major frontend feature is shipped, the team shall update this inventory with a short description, relevant routes, and links to its dedicated spec (if one exists).
- **FR-INV-003** — When a feature is deprecated or removed, the inventory shall be updated to either remove it or clearly mark it as deprecated.

---

## Non-Functional Requirements

- **NFR-INV-001** — The inventory shall remain accurate to within one release cycle (no more than one minor release out of date).
- **NFR-INV-002** — The document shall be concise enough to scan in under 5 minutes while still listing all major user-facing capabilities.
- **NFR-INV-003** — The inventory shall link to deeper specs in `docs/specs` where they exist, instead of duplicating detailed requirements.

---

## Acceptance Criteria

- **AC-INV-001**
  Given a developer opens `docs/specs/frontend-feature-inventory.spec.md`
  When they scan the “Current Feature Inventory” section
  Then they can see every major user-facing frontend capability grouped into logical areas.

- **AC-INV-002**
  Given a feature has a dedicated spec in `docs/specs`
  When that feature is listed in the inventory
  Then the row includes a reference to the corresponding spec file.

- **AC-INV-003**
  Given the frontend adds a new major feature (e.g., new tracking modality or analytics surface)
  When the next release branch is prepared
  Then this inventory is updated as part of the release checklist.

---

## Error Handling / Maintenance Risks

| Condition                             | Impact                                      | Mitigation                                             |
| ------------------------------------- | ------------------------------------------- | ------------------------------------------------------ |
| Inventory not updated after a release | Team has an incomplete view of capabilities | Add inventory update to release checklist              |
| Feature removed but still documented  | Confusion for QA and PMs                    | Require doc update in PRs that remove major features   |
| New spec added but not linked here    | Specs become harder to discover             | Require link-back from new specs to this inventory doc |

---

## Implementation TODO (Process)

- [x] Create initial frontend feature inventory document under `docs/specs`.
- [ ] Add this document to onboarding materials for new engineers and PMs.
- [ ] Update the release checklist to include “review and update frontend feature inventory”.
- [ ] Periodically (e.g., quarterly) audit the inventory against actual routes/components to ensure continued accuracy.
