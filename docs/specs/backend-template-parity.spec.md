# Back-end template feature parity specification

## Overview

This specification defines requirements for bringing the **back-end submodule’s Django template-rendered Web UI** to feature parity with the **front-end (Angular)** application. Users who access the site via the backend only (e.g. `http://localhost:8000`) will be able to perform the same workflows as on the Angular app: child dashboard with today summary and recent activity, analytics and export, catch-up mode, and unified timeline.

**User value:** Caregivers using the server-rendered backend UI get the same capabilities as the SPA—single-child dashboard, today’s summary, recent activity, analytics, data export, catch-up logging, and timeline—without requiring the front-end stack.

**Scope:** Back-end only. No API or front-end changes. All data and permissions use existing APIs or server-side equivalents (same models, permissions, and analytics/export logic).

---

## Current state summary

<!-- markdownlint-disable MD060 -->

| Area                  | Back-end template UI                                        | Front-end (Angular)                                                                                 |
| --------------------- | ----------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Auth                  | ✅ Login, signup, account settings (allauth)                | ✅ Same                                                                                             |
| Children              | ✅ List, add, edit, delete, sharing, invites, accept-invite | ✅ Same                                                                                             |
| Per-child entry point | ❌ Child list links directly to diapers/naps/feedings lists | ✅ Child dashboard (hub) then lists                                                                 |
| Child dashboard       | ❌ None                                                     | ✅ Today summary, recent activity, quick actions, nav to analytics/export/catch-up/timeline/sharing |
| Tracking (F/D/N)      | ✅ List, add, edit, delete (per type)                       | ✅ Same                                                                                             |
| Analytics             | ❌ API only                                                 | ✅ Analytics dashboard (charts/trends)                                                              |
| Export                | ❌ API only                                                 | ✅ Export page (CSV/PDF, date range, poll, download)                                                |
| Catch-up              | ❌ API (batch) only                                         | ✅ Catch-up page (time window, event timeline)                                                      |
| Timeline              | ❌ None                                                     | ✅ Unified activity feed (all types, one list)                                                      |
| Tracking list filter  | ❌ No filter UI                                             | ✅ Filter by type and date                                                                          |

<!-- markdownlint-enable MD060 -->

---

## Clarifications (discovery)

Before implementation, please confirm:

1. **Priority / phasing**
   Should delivery be phased? Suggested phases:
    - **Phase 1 (Must):** Child dashboard, timeline.
    - **Phase 2 (Should):** Analytics dashboard (read-only), Export page.
    - **Phase 3 (Could):** Catch-up page, tracking list filtering.
      If you prefer a single phase or different order, specify.

2. **Child list navigation**
   Should the child list link to the **new child dashboard** (e.g. “View” / child name) instead of (or in addition to) the current direct links to Diapers / Naps / Feedings?
    - **A:** Add dashboard as primary entry (e.g. click child name → dashboard; keep Diapers/Naps/Feedings buttons).
    - **B:** Keep current behaviour only; dashboard is reachable via a separate “Dashboard” link per child.
    - **C:** Other (describe).

3. **Analytics and export technology**
   For analytics dashboard and export in the template UI:
    - **Charts:** Prefer server-rendered (e.g. static images or simple HTML/CSS), or minimal JS (e.g. Chart.js from CDN) to mirror front-end behaviour?
    - **Export PDF polling:** Prefer full-page refresh polling, or a small amount of JS for status polling and download link (to avoid page reloads)?

Once these are decided, the implementation TODO can be ordered accordingly.

---

## Functional requirements (EARS)

### Child dashboard

- **FR-1** When an authenticated user with access to a child opens the child dashboard (e.g. `children/<id>/` or `children/<id>/dashboard/`), the system shall display that child’s profile (name, date of birth, gender, age), today’s summary counts (feedings, diapers, naps), and a recent activity feed (combined feedings, diapers, naps, e.g. last 10 items).
- **FR-2** When the user is on the child dashboard, the system shall show quick-action links or buttons to add a feeding, diaper, or nap (linking to existing add views) and navigation links to Feedings, Diapers, Naps, Analytics, Export, Catch-up, Timeline, and Sharing (where permitted).
- **FR-3** When the user is on the child dashboard, the system shall enforce the same permission rules as the API: owner sees all actions; co-parent sees add/edit and analytics/export/timeline but not sharing management; caregiver sees add and view-only for lists/analytics/export/timeline.

### Timeline

- **FR-4** When the user opens the timeline for a child (e.g. `children/<id>/timeline/`), the system shall display a single chronological list of feedings, diapers, and naps for that child (newest first or configurable), with type, timestamp, and key details (e.g. amount/duration for feedings, change type for diapers, duration for naps).
- **FR-5** When the timeline is displayed, the system shall support pagination or “load more” so large datasets do not overload the page.

### Analytics

- **FR-6** When the user opens the analytics view for a child (e.g. `children/<id>/analytics/`), the system shall display feeding trends, diaper patterns, and sleep summary for a configurable period (e.g. 7, 14, 30 days) using the same data as the API (feeding-trends, diaper-patterns, sleep-summary).
- **FR-7** When the user is on the analytics view, the system shall allow selecting the number of days (e.g. 7, 14, 30) and the view shall update to show data for that range.

### Export

- **FR-8** When the user opens the export page for a child (e.g. `children/<id>/analytics/export/` or `children/<id>/export/`), the system shall present options for format (CSV, PDF) and date range (e.g. last 7, 14, 30 days).
- **FR-9** When the user submits CSV export with valid parameters, the system shall trigger the existing export API (or equivalent server-side call), return the CSV file for download, and show success feedback.
- **FR-10** When the user submits PDF export with valid parameters, the system shall queue the existing PDF export job, show a “processing” state, poll export-status until completion (or failure), and then offer a download link or redirect to download; on failure, the system shall display the error message from the API.

### Catch-up

- **FR-11** When the user opens the catch-up page for a child (e.g. `children/<id>/catch-up/`), the system shall display a time window selector (e.g. start and end date/time) and an event timeline for that window showing existing feedings, diapers, and naps.
- **FR-12** When the user adds an event from the catch-up page (feeding, diaper, nap), the system shall create the record via the same validation and API or server logic as the existing add forms; new events shall appear in the catch-up timeline after creation.

### Tracking list filtering (optional)

- **FR-13** When the user is on a tracking list (feedings, diapers, or naps), the system shall allow filtering by date range (and optionally by type where applicable, e.g. diaper change type) so that the list shows only matching records.

---

## Non-functional requirements

- **NFR-1** All new template views shall use the existing permission mixins and child access rules (e.g. `ChildAccessMixin`, `ChildEditMixin`, `ChildOwnerMixin`); no new permission models.
- **NFR-2** Dashboard, timeline, and analytics shall use existing APIs or the same server-side logic (e.g. `get_today_summary`, trend endpoints, export endpoints) to avoid duplication and keep behaviour consistent with the front-end.
- **NFR-3** Export PDF flow shall use the existing Celery task and export-status/download endpoints; the template UI only orchestrates form submit, polling, and download.
- **NFR-4** All user-facing errors (validation, 403, 404, export failure) shall be shown with clear messages; no raw stack traces in production.
- **NFR-5** New pages shall follow existing back-end conventions: extend `_base.html`, use same nav/header, and match existing template structure and styling (e.g. Bootstrap 5, existing CSS).

---

## Acceptance criteria (Given/When/Then)

<!-- markdownlint-disable MD060 -->

| ID   | Given                       | When                                  | Then                                                                 |
| ---- | --------------------------- | ------------------------------------- | -------------------------------------------------------------------- |
| AC1  | User is on children list    | User clicks child name or “Dashboard” | Child dashboard is shown with summary, recent activity, quick links  |
| AC2  | User is on child dashboard  | User clicks “Add feeding”             | Feeding add form is shown for that child                             |
| AC3  | User is on child dashboard  | User clicks “Analytics”               | Analytics view is shown with trends for default period               |
| AC4  | User is on child dashboard  | User clicks “Export data”             | Export page is shown with format and date range options              |
| AC5  | User is on export page      | User selects CSV, 30 days, submits    | CSV is generated and downloaded; success message shown               |
| AC6  | User is on export page      | User selects PDF, submits             | Job is queued; status is polled until done; download link is offered |
| AC7  | User is on child dashboard  | User clicks “Timeline”                | Timeline page shows combined feedings, diapers, naps (chronological) |
| AC8  | User is on child dashboard  | User clicks “Catch-up”                | Catch-up page shows time window and event timeline for that window   |
| AC9  | User is on catch-up page    | User adds a feeding in the past       | Feeding is created and appears in catch-up timeline                  |
| AC10 | User is caregiver for child | User opens child dashboard            | Sharing management is not shown; add/view/analytics/export allowed   |

<!-- markdownlint-enable MD060 -->

---

## Error handling

<!-- markdownlint-disable MD060 -->

| Scenario                   | Handling                                                                         |
| -------------------------- | -------------------------------------------------------------------------------- |
| Child not found / 404      | Show “Child not found” and link back to children list                            |
| No permission (403)        | Return 404 or show “You don’t have access to this child” and link back           |
| Export CSV validation      | Show field or message from server response (e.g. invalid days)                   |
| Export PDF job failed      | Show error from export-status response; stop polling; allow retry                |
| Export status poll timeout | Show “Export is taking longer than expected”; offer link to try again or go back |
| Catch-up create validation | Show form errors same as existing tracking forms                                 |

<!-- markdownlint-enable MD060 -->

---

## Implementation TODO checklist

- [ ] **URLs and routing**
    - [ ] Add `children/<id>/dashboard/` (or `children/<id>/` as dashboard).
    - [ ] Add `children/<id>/timeline/`.
    - [ ] Add `children/<id>/analytics/` (analytics dashboard).
    - [ ] Add `children/<id>/analytics/export/` or `children/<id>/export/` (export page).
    - [ ] Add `children/<id>/catch-up/`.

- [ ] **Child dashboard**
    - [ ] Create `ChildDashboardView` (DetailView or custom) with permission mixin.
    - [ ] Use existing `get_child_last_activities` / cache and today-summary (API or server-side).
    - [ ] Template: child header, today summary block, recent activity list (last N combined), quick-action buttons, nav links (Feedings, Diapers, Naps, Analytics, Export, Catch-up, Timeline, Sharing if owner).
    - [ ] Update child list template: add link to dashboard (e.g. child name or “View” → dashboard).

- [ ] **Timeline**
    - [ ] Create `ChildTimelineView`; fetch feedings, diapers, naps; merge and sort by timestamp; paginate.
    - [ ] Template: single list with type icon/label, time, and brief details; “Load more” or pagination.

- [ ] **Analytics dashboard**
    - [ ] Create `ChildAnalyticsView`; call or replicate feeding-trends, diaper-patterns, sleep-summary (same as API).
    - [ ] Template: days selector (7/14/30); display trends (tables or charts per NFR/tech choice).
    - [ ] Optional: minimal JS + Chart.js for charts if chosen.

- [ ] **Export page**
    - [ ] Create `ChildExportView` (GET: form; POST: submit to export API or server-side).
    - [ ] Template: format (CSV/PDF), date range (e.g. days dropdown), submit button.
    - [ ] CSV: POST export-csv, stream or redirect to file download; show success message.
    - [ ] PDF: POST export-pdf, receive task_id; poll export-status (full refresh or small JS); on success, show download link (analytics/download/<filename>/); on failure, show error.

- [ ] **Catch-up**
    - [ ] Create `ChildCatchUpView` (GET: time window form + timeline; POST for new events or use existing add URLs with return_url).
    - [ ] Fetch events in selected window (reuse API or ORM); render event timeline.
    - [ ] “Add feeding” / “Add diaper” / “Add nap” link to existing add views with query param or session to return to catch-up and pre-fill time; or inline forms on catch-up page that POST to existing create endpoints.

- [ ] **Tracking list filtering (optional)**
    - [ ] Add optional date range (and type) query params to diaper/feeding/nap list views.
    - [ ] Add filter form or links in list templates; preserve filter in pagination links.

- [ ] **Tests**
    - [ ] Test dashboard: required context (child, summary, recent activity), permission (owner vs co-parent vs caregiver).
    - [ ] Test timeline: combined list, ordering, pagination.
    - [ ] Test analytics view: days param, data present.
    - [ ] Test export: CSV download, PDF queue + status + download (mocked Celery).
    - [ ] Test catch-up: time window, event list, create from catch-up.
    - [ ] Test filter on list views if implemented.

- [ ] **Docs**
    - [ ] Update `back-end/CLAUDE.md` (or equivalent) with new URLs and view names.
    - [ ] Optional: short “Back-end Web UI” section in root `CLAUDE.md` or `DEPLOYMENT.md` listing dashboard, timeline, analytics, export, catch-up.

---

## References

- Back-end Web UI: `back-end/children/views.py`, `back-end/children/urls.py`, `back-end/children/tracking_views.py`, `back-end/templates/`.
- Front-end routes and features: `front-end/poopyfeed/src/app/app.routes.ts`, child dashboard and analytics/export/catch-up/timeline components.
- API: `back-end/django_project/api_urls.py`, `back-end/analytics/views.py`, `back-end/children/batch_api.py` (catch-up batch).
- Android parity spec (phasing style): `specs/android-feature-parity.spec.md`.
