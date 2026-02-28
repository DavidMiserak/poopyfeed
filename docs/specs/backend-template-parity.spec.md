# Feature: Back-end template feature parity

## Overview

This specification defines requirements for bringing the **back-end submodule’s Django template-rendered Web UI** to feature parity with the **front-end (Angular)** application. Users who access the site via the backend only (e.g. `http://localhost:8000`) shall be able to perform the same workflows as on the Angular app: child dashboard with today summary and recent activity, analytics and export, catch-up mode, and unified timeline.

**User value:** Caregivers using the server-rendered backend UI get the same capabilities as the SPA—single-child dashboard, today’s summary, recent activity, analytics, data export, catch-up logging, and timeline—without requiring the front-end stack.

**Scope:** Back-end only. No API or front-end changes. All data and permissions use existing APIs or server-side equivalents (same models, permissions, and analytics/export logic).

**Implementation status:** Complete for Phase 1–3 (dashboard, timeline, analytics, export, catch-up). Optional tracking list filtering not implemented.

---

## Current state summary

<!-- markdownlint-disable MD060 -->

| Area                  | Back-end template UI                                        | Front-end (Angular)                                  |
| --------------------- | ----------------------------------------------------------- | ---------------------------------------------------- |
| Auth                  | ✅ Login, signup, account settings (allauth)                | ✅ Same                                              |
| Children              | ✅ List, add, edit, delete, sharing, invites, accept-invite | ✅ Same                                              |
| Per-child entry point | ✅ Child name → dashboard; card shows “Open dashboard”      | ✅ Child dashboard (hub) then lists                  |
| Child dashboard       | ✅ Today summary, recent activity, quick actions, nav       | ✅ Same                                              |
| Tracking (F/D/N)      | ✅ List, add, edit, delete (per type)                       | ✅ Same                                              |
| Analytics             | ✅ Tables (7/14/30 days)                                    | ✅ Analytics dashboard (charts/trends)               |
| Export                | ✅ CSV immediate, PDF queue + status (meta refresh poll)    | ✅ Export page (CSV/PDF, date range, poll, download) |
| Catch-up              | ✅ Date range + event timeline; links to add F/D/N          | ✅ Catch-up page (time window, event timeline)       |
| Timeline              | ✅ Merged feed, pagination                                  | ✅ Unified activity feed (all types, one list)       |
| Tracking list filter  | ❌ No filter UI (optional)                                  | ✅ Filter by type and date                           |

<!-- markdownlint-enable MD060 -->

---

## Decisions (resolved)

1. **Priority / phasing** — Delivered in three phases:
    - **Phase 1:** Child dashboard, timeline.
    - **Phase 2:** Analytics dashboard (read-only), Export page.
    - **Phase 3:** Catch-up page. Tracking list filtering left as optional (not implemented).

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

---

## Error handling

| Error condition            | HTTP / context | User-facing behaviour                                                                  |
| -------------------------- | -------------- | -------------------------------------------------------------------------------------- |
| Child not found            | 404            | Show "Child not found" and link back to children list                                  |
| No permission for child    | 404            | Return 404; show "You don't have access to this child" and link back (no data leakage) |
| Export CSV validation      | 400 / form     | Show field or message from server response (e.g. invalid days)                         |
| Export PDF job failed      | —              | Show error from export-status response; stop polling; allow retry or back to export    |
| Export status poll timeout | —              | Show "Export is taking longer than expected"; offer link to try again or go back       |
| Catch-up create validation | Form           | Show form errors same as existing tracking add forms                                   |
| Unauthenticated            | 302 → login    | Redirect to login; return to intended page where supported                             |

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

- [ ] **Tracking list filtering (optional)**
    - [ ] Add optional date range (and type) query params to diaper/feeding/nap list views.
    - [ ] Add filter form or links in list templates; preserve filter in pagination links.

- [x] **Tests**
    - [x] Test dashboard: required context (child, summary, recent activity), permission (owner vs no-access 404).
    - [x] Test timeline: combined list, ordering, pagination; timezone for date headers.
    - [x] Test analytics view: days param, data present.
    - [x] Test export: CSV download, PDF queue + status + download (Celery/AsyncResult).
    - [x] Test catch-up: time window, event list, access control.

- [x] **Docs**
    - [x] Update `back-end/CLAUDE.md` with template UI URLs and view names (Dashboard, Timeline, Analytics, Export, Catch-up).

---

## Out of scope

- **API or front-end changes** — This feature is back-end template UI only; no new REST endpoints or Angular changes.
- **Chart.js or client-side charts** — Analytics use server-rendered HTML tables; no JavaScript charting in the template UI.
- **Real-time or WebSocket updates** — Export status uses full-page or meta-refresh polling only.
- **Tracking list filtering** — Optional; may be added later (FR-FILTER-001).

---

## Open questions

- None; decisions are resolved and implementation is complete for Phase 1–3.

---

## References

- Back-end Web UI: `back-end/children/views.py`, `back-end/children/urls.py`, `back-end/children/tracking_views.py`, `back-end/templates/`.
- Front-end routes and features: `front-end/poopyfeed/src/app/app.routes.ts`, child dashboard and analytics/export/catch-up/timeline components.
- API: `back-end/django_project/api_urls.py`, `back-end/analytics/views.py`, `back-end/children/batch_api.py` (catch-up batch).
- Android parity spec (phasing style): `specs/android-feature-parity.spec.md`.
