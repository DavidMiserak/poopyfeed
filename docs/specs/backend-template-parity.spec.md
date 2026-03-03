# Feature: Back-end template feature parity

## Overview

This specification defines requirements for bringing the **back-end submodule’s Django template-rendered Web UI** to feature parity with the **front-end (Angular)** application. Users who access the site via the backend only (e.g. `http://localhost:8000`) shall be able to perform the same workflows as on the Angular app: child dashboard with pattern alerts, analytics and export, catch-up mode, unified timeline, pediatrician summary, notifications, and quiet hours.

**User value:** Caregivers using the server-rendered backend UI get the same capabilities as the SPA—child dashboard with pattern alerts, today’s summary, recent activity, analytics, data export, catch-up logging, timeline, pediatrician summary, in-app notifications, and quiet hours—without requiring the front-end stack.

**Scope:** Back-end only. No API or front-end changes. All data and permissions use existing APIs or server-side equivalents (same models, permissions, and analytics/export logic).

**Implementation status:** Complete for Phase 1–4 (dashboard, timeline, analytics, export, catch-up, pattern alerts, pediatrician summary, notifications, quiet hours). Accessibility improvements (WCAG 2.1 AA audit, keyboard nav, timezone in timestamps) are partially done and may be refined further.

---

## Current state summary

<!-- markdownlint-disable MD060 -->

| Area                   | Back-end template UI                                                  | Front-end (Angular)                                  |
| ---------------------- | --------------------------------------------------------------------- | ---------------------------------------------------- |
| Auth                   | ✅ Login, signup, account settings (allauth)                          | ✅ Same                                              |
| Children               | ✅ List, add, edit, delete, sharing, invites, accept-invite           | ✅ Same                                              |
| Per-child entry point  | ✅ Child name → dashboard; card shows “Open dashboard”                | ✅ Child dashboard (hub) then lists                  |
| Child dashboard        | ✅ Today summary, pattern alerts, recent activity, quick actions, nav | ✅ Pattern alerts, same                              |
| Tracking (F/D/N)       | ✅ List, add, edit, delete (per type)                                 | ✅ Same                                              |
| Pattern alerts         | ✅ Display on dashboard (feeding/nap overdue warnings)                | ✅ Dashboard alerts + notifications                  |
| Analytics              | ✅ Tables (7/14/30 days)                                              | ✅ Analytics dashboard (charts/trends)               |
| Pediatrician summary   | ✅ Printable 7-day report (child_pediatrician_summary)                | ✅ Report with trends and stats                      |
| Export                 | ✅ CSV immediate, PDF queue + status (meta refresh poll)              | ✅ Export page (CSV/PDF, date range, poll, download) |
| Catch-up               | ✅ Date range + event timeline; links to add F/D/N                    | ✅ Catch-up page (time window, event timeline)       |
| Timeline               | ✅ Merged feed, pagination                                            | ✅ Unified activity feed (all types, one list)       |
| Tracking list filter   | ✅ Date range + type (feedings/diapers); date range (naps)            | ✅ Filter by type and date                           |
| Notifications          | ✅ In-app list (/notifications/), mark read, unread badge in nav      | ✅ Notification center with unread badge             |
| Quiet hours            | ✅ Account settings form (enabled, start/end time)                    | ✅ Configurable in account settings                  |
| Timezone-aware display | ✅ UTC → local timezone conversion                                    | ✅ Same                                              |
| Accessibility          | 🔄 WCAG 2.1 AA (in progress)                                          | ✅ WCAG 2.1 AA compliance                            |

<!-- markdownlint-enable MD060 -->

---

## Decisions (resolved)

1. **Priority / phasing** — Delivered in four phases:
    - **Phase 1:** Child dashboard, timeline.
    - **Phase 2:** Analytics dashboard (read-only), Export page.
    - **Phase 3:** Catch-up page. Tracking list filtering left as optional (not implemented).
    - **Phase 4:** Pattern alerts on dashboard, pediatrician summary, in-app notifications, quiet hours, accessibility improvements.

2. **Child list navigation** — **A.** Child name links to child dashboard; card footer shows “Open dashboard.” No separate Diapers/Naps/Feedings buttons on the list card; those are reached from the dashboard.

3. **Analytics and export technology:**
    - **Charts:** Server-rendered tables (no Chart.js). Feeding trends, diaper patterns, and sleep summary shown as HTML tables.
    - **Export PDF polling:** Full-page refresh via `<meta http-equiv="refresh">` on the export-status page until completed or failed; then download link or error is shown.

---

## Functional requirements (EARS)

### Child dashboard

- **FR-DASH-001** — Dashboard display
  When an authenticated user with access to a child opens the child dashboard (e.g. `children/<id>/dashboard/`), the system shall display that child’s profile (name, date of birth, gender, age), today’s summary counts (feedings, diapers, naps), and a recent activity feed (combined feedings, diapers, naps, last N items).

- **FR-DASH-002** — Quick actions and navigation
  While the user is on the child dashboard, the system shall show quick-action links or buttons to add a feeding, diaper, or nap (linking to existing add views) and navigation links to Feedings, Diapers, Naps, Analytics, Export, Catch-up, Timeline, and Sharing (where permitted).

- **FR-DASH-003** — Dashboard permissions
  While the user is on the child dashboard, the system shall enforce the same permission rules as the API: owner sees all actions; co-parent sees add/edit and analytics/export/timeline but not sharing management; caregiver sees add and view-only for lists/analytics/export/timeline.

### Timeline

- **FR-TL-001** — Timeline display
  When the user opens the timeline for a child (e.g. `children/<id>/timeline/`), the system shall display a single chronological list of feedings, diapers, and naps for that child (newest first), with type, timestamp, and key details (e.g. amount/duration for feedings, change type for diapers, duration for naps).

- **FR-TL-002** — Timeline pagination
  When the timeline is displayed, the system shall support pagination or “load more” so large datasets do not overload the page.

### Analytics

- **FR-ANAL-001** — Analytics display
  When the user opens the analytics view for a child (e.g. `children/<id>/analytics/`), the system shall display feeding trends, diaper patterns, and sleep summary for a configurable period (7, 14, or 30 days) using the same data as the API (feeding-trends, diaper-patterns, sleep-summary).

- **FR-ANAL-002** — Days selector
  While the user is on the analytics view, when they select the number of days (7, 14, or 30), the system shall update the view to show data for that range.

### Export

- **FR-EXP-001** — Export page options
  When the user opens the export page for a child (e.g. `children/<id>/export/`), the system shall present options for format (CSV, PDF) and date range (last 7, 14, or 30 days).

- **FR-EXP-002** — CSV export
  When the user submits CSV export with valid parameters, the system shall generate the CSV (via existing logic or equivalent server-side call), return the file for download, and provide success feedback.

- **FR-EXP-003** — PDF export
  When the user submits PDF export with valid parameters, the system shall queue the existing PDF export job, show a “processing” state, poll export-status until completion or failure, and then offer a download link or display the error message from the API.

### Catch-up

- **FR-CU-001** — Catch-up page display
  When the user opens the catch-up page for a child (e.g. `children/<id>/catch-up/`), the system shall display a time window selector (start and end date) and an event timeline for that window showing existing feedings, diapers, and naps.

- **FR-CU-002** — Add event from catch-up
  When the user adds an event from the catch-up page (feeding, diaper, or nap) via the existing add forms, the system shall create the record using the same validation and server logic; the new event shall appear in the catch-up timeline when the user returns and refreshes or re-applies the date range.

### Tracking list filtering (optional)

- **FR-FILTER-001** — Filter tracking lists
  When the user is on a tracking list (feedings, diapers, or naps), the system shall allow filtering by date range (and optionally by type where applicable, e.g. diaper change type) so that the list shows only matching records.

### Pattern alerts

- **FR-ALERT-001** — Display pattern alerts on dashboard
  When the user views the child dashboard, if pattern alerts exist (e.g. overdue feeding, nap wake-window warning), the system shall display them prominently with a clear message and relevant action links.

### Pediatrician summary

- **FR-PED-001** — Pediatrician summary page
  When the user opens the pediatrician summary page for a child (e.g. `children/<id>/pediatrician-summary/`), the system shall display a printable report aggregating recent feeding trends, diaper patterns, sleep summary, and key statistics for that period (e.g. 30 days).

- **FR-PED-002** — Summary print/export
  When the user views the pediatrician summary, the system shall provide a print-friendly layout (no nav, full width) and shall allow printing or saving as PDF via browser print dialog.

### Notifications

- **FR-NOT-001** — Notifications center
  When the user opens the notifications center (e.g. `account/notifications/`), the system shall display a paginated list of in-app notifications (pattern alerts, reminders, system messages) with unread count badge on the nav/account menu.

- **FR-NOT-002** — Mark notification as read
  When the user clicks a notification in the list, the system shall mark it as read and navigate to the related context (e.g. child dashboard for a pattern alert) or show the message details.

### Quiet hours

- **FR-QH-001** — Configure quiet hours
  When the user is on the account settings page, the system shall show a form to configure quiet hours (start time and end time) to suppress notifications during that window; when the user saves, the system shall store the preference.

- **FR-QH-002** — Enforce quiet hours
  When a notification would be shown and the current time falls within the user's quiet hours, the system shall suppress the notification display (but may queue it for later display or in-app review).

---

## Non-functional requirements

### Performance

- Dashboard, timeline, and analytics shall use existing cached or efficient server-side logic (e.g. `get_today_summary`, trend helpers) so page load remains consistent with other template pages.
- Timeline shall paginate results so large datasets do not overload the page or cause timeouts.

### Security

- All new template views shall use the existing permission mixins and child access rules (e.g. `ChildAccessMixin`, `ChildEditMixin`, `ChildOwnerMixin`); no new permission models.
- When a user requests a child they do not have access to, the system shall return 404 (or equivalent) and shall not expose other children’s data.

### Consistency and usability

- Dashboard, timeline, and analytics shall use the same server-side logic as the API (e.g. `get_today_summary`, feeding-trends, diaper-patterns, sleep-summary) to avoid duplication and keep behaviour consistent with the front-end.
- Export PDF flow shall use the existing Celery task and export-status/download endpoints; the template UI only orchestrates form submit, polling, and download.
- All user-facing errors (validation, 403, 404, export failure) shall be shown with clear messages; no raw stack traces in production.
- New pages shall follow existing back-end conventions: extend `_base.html`, use same nav/header, and match existing template structure and styling (e.g. Bootstrap 5, existing CSS).

### Accessibility

- All template pages shall meet WCAG 2.1 AA contrast ratios, use semantic HTML, and include ARIA labels for interactive elements.
- Forms, tables, and lists shall be keyboard-navigable; focus indicators shall be visible.
- Timezone conversion shall be explicit and clear in all displayed timestamps (e.g. "2:30 PM local time").

### Performance and caching

- Dashboard, timeline, and analytics views shall use cached or efficient server-side queries to minimize database load and API calls.
- Pattern alerts shall be fetched via the same backend API/cache as the front-end to ensure consistency.
- Notifications list shall paginate results to avoid loading all notifications at once.

---

## Acceptance criteria (Given/When/Then)

### AC-001: Navigate from child list to dashboard

Given the user is on the children list and has access to at least one child
When they click the child name or the card (Open dashboard)
Then the child dashboard is shown with profile, today summary, recent activity, and quick links.

### AC-002: Add feeding from dashboard

Given the user is on the child dashboard for a child they can edit
When they click “Add feeding”
Then the feeding add form is shown for that child.

### AC-003: Open analytics from dashboard

Given the user is on the child dashboard
When they click “Analytics”
Then the analytics view is shown with feeding trends, diaper patterns, and sleep summary for the default period (e.g. 30 days).

### AC-004: Open export from dashboard

Given the user is on the child dashboard
When they click “Export data”
Then the export page is shown with format (CSV/PDF) and date range (7/14/30 days) options.

### AC-005: CSV export success

Given the user is on the export page for a child
When they select CSV, choose 30 days, and submit
Then a CSV file is generated and downloaded and success feedback is provided (e.g. download completes).

### AC-006: PDF export and download

Given the user is on the export page for a child
When they select PDF and submit
Then the job is queued, a processing/status page is shown, status is polled until complete or failed, and on success a download link is offered.

### AC-007: Open timeline from dashboard

Given the user is on the child dashboard
When they click “Timeline”
Then the timeline page shows a combined chronological list of feedings, diapers, and naps (newest first) with pagination.

### AC-008: Open catch-up from dashboard

Given the user is on the child dashboard
When they click “Catch-up”
Then the catch-up page shows a time window selector and an event timeline for the selected (or default) window.

### AC-009: Add event from catch-up page

Given the user is on the catch-up page for a child they can edit
When they use “Add feeding” (or diaper or nap) and complete the existing add form
Then the record is created and, when the user returns to catch-up and applies the date range, the new event appears in the timeline.

### AC-010: Caregiver does not see sharing management

Given the user has caregiver role for a child (not owner or co-parent)
When they open the child dashboard
Then sharing management is not shown; add and view links for feedings, diapers, naps, analytics, export, and timeline are allowed.

### AC-011: No access to child returns 404

Given a user does not have access to a child (not in parent or shares)
When they request the child dashboard, timeline, analytics, export, or catch-up URL for that child
Then the system returns 404 (or equivalent) and does not expose the child’s data.

### AC-012: Export PDF job failure

Given the user has submitted a PDF export and is on the export status page
When the PDF job fails
Then the error message from the API is displayed, polling stops, and the user can retry or return to the export page.

### AC-013: Pattern alert displayed on dashboard

Given a child has an overdue feeding or nap wake-window warning
When the user views the child dashboard
Then the pattern alert is displayed prominently with the alert message and relevant action links.

### AC-014: Open pediatrician summary

Given the user is on the child dashboard
When they click "Pediatrician summary"
Then the report page is shown with feeding trends, diaper patterns, sleep summary, and key statistics for the default period (e.g. 30 days).

### AC-015: Print pediatrician summary

Given the user is on the pediatrician summary page
When they click Print or use the browser print dialog
Then a print-friendly version is shown without navigation; the user can save as PDF via browser.

### AC-016: View notifications center

Given the user is authenticated
When they click the notifications icon or link in the account menu
Then the notifications list is shown with all in-app alerts and reminders, unread items highlighted, and pagination for large lists.

### AC-017: Notifications unread badge

Given the user has unread notifications
When they view the account menu or navigation
Then an unread count badge is shown on the notifications link.

### AC-018: Configure quiet hours

Given the user is on the account settings page
When they set quiet hours (e.g. 10 PM to 7 AM) and save
Then the preference is stored and the user is shown confirmation.

### AC-019: Quiet hours suppress notifications

Given a user has configured quiet hours from 10 PM to 7 AM
When a notification would be triggered at 11 PM
Then the notification is not displayed but is queued in the notifications center for later review.

---

## Error handling

| Error condition                 | HTTP / context | User-facing behaviour                                                                  |
| ------------------------------- | -------------- | -------------------------------------------------------------------------------------- |
| Child not found                 | 404            | Show "Child not found" and link back to children list                                  |
| No permission for child         | 404            | Return 404; show "You don't have access to this child" and link back (no data leakage) |
| Export CSV validation           | 400 / form     | Show field or message from server response (e.g. invalid days)                         |
| Export PDF job failed           | —              | Show error from export-status response; stop polling; allow retry or back to export    |
| Export status poll timeout      | —              | Show "Export is taking longer than expected"; offer link to try again or go back       |
| Catch-up create validation      | Form           | Show form errors same as existing tracking add forms                                   |
| Unauthenticated                 | 302 → login    | Redirect to login; return to intended page where supported                             |
| Pattern alerts API error        | —              | Show cached alerts if available; otherwise hide alerts section                         |
| Quiet hours time validation     | Form           | Validate start < end; show inline error if invalid                                     |
| Pediatrician summary generation | —              | Show error message if report generation fails; allow user to retry or go back          |
| Notifications fetch error       | —              | Show cached notifications if available; otherwise show "Unable to load notifications"  |

---

## Implementation TODO checklist

- [x] **URLs and routing**
    - [x] Add `children/<id>/dashboard/` (or `children/<id>/` as dashboard).
    - [x] Add `children/<id>/timeline/`.
    - [x] Add `children/<id>/analytics/` (analytics dashboard).
    - [x] Add `children/<id>/export/` (export page); `children/<id>/export/status/<task_id>/` for PDF status.
    - [x] Add `children/<id>/catch-up/`.

- [x] **Child dashboard**
    - [x] Create `ChildDashboardView` (DetailView or custom) with permission mixin.
    - [x] Use existing `get_today_summary` (analytics.utils) and in-view recent-activity merge.
    - [x] Template: child header, today summary block, recent activity list (last N combined), quick-action buttons, nav links (Feedings, Diapers, Naps, Analytics, Export, Catch-up, Timeline, Sharing if owner).
    - [x] Update child list template: child name links to dashboard; card shows “Open dashboard.”

- [x] **Timeline**
    - [x] Create `ChildTimelineView`; fetch feedings, diapers, naps; merge and sort by timestamp; paginate.
    - [x] Template: single list with type icon/label, time, and brief details; pagination.

- [x] **Analytics dashboard**
    - [x] Create `ChildAnalyticsView`; call get_feeding_trends, get_diaper_patterns, get_sleep_summary (same as API).
    - [x] Template: days selector (7/14/30); display trends as HTML tables (no Chart.js).

- [x] **Export page**
    - [x] Create `ChildExportView` (GET: form; POST: CSV stream or PDF queue redirect).
    - [x] Template: format (CSV/PDF), date range (7/14/30 days), submit button.
    - [x] CSV: server-side generation and download; success via download.
    - [x] PDF: queue task, redirect to `ChildExportStatusView`; meta refresh polling; on success, download link; on failure, error message.

- [x] **Catch-up**
    - [x] Create `ChildCatchUpView` (GET: date range form + event timeline).
    - [x] Fetch events in selected window (ORM); render event timeline by date.
    - [x] “Add feeding” / “Add diaper” / “Add nap” link to existing add views; user returns to catch-up manually or via browser back.

- [x] **Tracking list filtering (optional)**
    - [x] Add optional date range (and type) query params to diaper/feeding/nap list views.
    - [x] Add filter form or links in list templates; preserve filter in pagination links.

- [x] **Tests**
    - [x] Test dashboard: required context (child, summary, recent activity), permission (owner vs no-access 404).
    - [x] Test timeline: combined list, ordering, pagination; timezone for date headers.
    - [x] Test analytics view: days param, data present.
    - [x] Test export: CSV download, PDF queue + status + download (Celery/AsyncResult).
    - [x] Test catch-up: time window, event list, access control.

- [x] **Docs**
    - [x] Update `back-end/CLAUDE.md` with template UI URLs and view names (Dashboard, Timeline, Analytics, Export, Catch-up).

### Phase 4: Pattern alerts, pediatrician summary, notifications, and quiet hours

- [x] **Pattern alerts on dashboard**
    - [x] Fetch pattern alerts via existing API/cache and display on child dashboard.
    - [x] Render alerts prominently with message and action links.
    - [x] Test: alerts appear on dashboard when present; hidden when none.

- [x] **Pediatrician summary page**
    - [x] Create `ChildPediatricianSummaryView`; aggregate feeding trends, diaper patterns, sleep summary.
    - [x] Template: print-friendly layout (no nav); include date range selector if needed.
    - [x] Test: summary page loads, data matches analytics API, print layout renders correctly.

- [x] **Notifications center**
    - [x] Create `NotificationsListView` (paginated).
    - [x] Fetch notifications from backend (in-app notification model or API).
    - [x] Template: notification list with unread badge on nav; mark-as-read action.
    - [x] Test: notifications appear, unread badge shows, mark-as-read works.

- [x] **Quiet hours in account settings**
    - [x] Add quiet hours form to account settings (start time, end time).
    - [x] Store preference in user profile or settings model.
    - [x] Enforce quiet hours when triggering notifications (suppress display if within window).
    - [x] Test: quiet hours form submits, time validation works, notifications suppressed during quiet window.

- [ ] **Accessibility improvements**
    - [ ] Audit all template pages for WCAG 2.1 AA: contrast ratios, semantic HTML, ARIA labels.
    - [ ] Ensure keyboard navigation and visible focus indicators.
    - [ ] Explicit timezone display in all timestamps.
    - [ ] Test: keyboard navigation, screen reader compatibility, contrast validation.

- [ ] **Docs**
    - [ ] Update `back-end/CLAUDE.md` with new template URLs (Pediatrician Summary, Notifications, Account Quiet Hours).

---

## Out of scope

- **API or front-end changes** — This feature is back-end template UI only; no new REST endpoints or Angular changes.
- **Chart.js or client-side charts** — Analytics use server-rendered HTML tables; no JavaScript charting in the template UI.
- **Real-time or WebSocket updates** — Export status uses full-page or meta-refresh polling only.
- **Tracking list filtering** — Optional; may be added later (FR-FILTER-001).

---

## Open questions

- None; decisions are resolved for Phases 1–4. Phase 4 (pattern alerts, pediatrician summary, notifications, quiet hours) is implemented; accessibility improvements remain optional for further refinement.

---

## References

- Frontend feature inventory: `docs/specs/frontend-feature-inventory.spec.md`
- Back-end Web UI: `back-end/children/views.py`, `back-end/children/urls.py`, `back-end/children/tracking_views.py`, `back-end/templates/`.
- Front-end routes and features: `front-end/poopyfeed/src/app/app.routes.ts`, child dashboard and analytics/export/catch-up/timeline components.
- API: `back-end/django_project/api_urls.py`, `back-end/analytics/views.py`, `back-end/children/batch_api.py` (catch-up batch).
- Pattern alerts spec: `docs/specs/pattern-alerts.spec.md`
- Notifications spec: `docs/specs/notifications.spec.md`
- Pediatrician summary spec: `docs/specs/pediatrician-summary.spec.md`
- Android parity spec (phasing style): `docs/specs/android-feature-parity.spec.md`
