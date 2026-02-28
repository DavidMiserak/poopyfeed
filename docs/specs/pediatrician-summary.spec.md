# Pediatrician Summary — Specification

## Overview

The Pediatrician Summary gives parents (primary persona: Mom / Sarah) one place to view and optionally print a last-7-days summary of feeding, diaper, and sleep data for a child, so they can answer the doctor’s questions at a visit or bring a one-page printout. The feature uses the existing weekly-summary API; no new backend endpoint is required for the screen. MVP delivers a dedicated screen and print-friendly layout; one-page PDF download is out of scope for the first iteration.

## Functional Requirements (EARS)

### Display

**FR-PED-001** — Load weekly summary
While the user has access to the child, when they open the Pediatrician summary screen, the system shall request and display the last 7 days’ aggregated data (feedings: count, total oz, bottle/breast breakdown, avg duration; diapers: count, wet/dirty/both; sleep: naps, total minutes, avg duration) using GET `/api/v1/analytics/children/{child_id}/weekly-summary/`. The summary shall include **daily averages** (e.g. feedings per day, oz per day, diaper changes per day, naps per day, sleep per day) so the parent can answer doctor-style questions such as “how many per day?”.

**FR-PED-002** — Child context
When the Pediatrician summary screen is displayed, the system shall show the child’s name and the period label (e.g. “Last 7 days”) so the user and doctor can identify the subject.

**FR-PED-003** — Loading state
While the weekly-summary request is in progress, the system shall show a loading indicator (skeleton or spinner) and not display summary content.

**FR-PED-004** — Empty state
When the weekly-summary response indicates no activity in the last 7 days (all counts zero), the system shall display an empty state that explains there is no data for the period and does not imply an error.

**FR-PED-005** — Error state and retry
When the weekly-summary request fails (network error, 4xx/5xx), the system shall display an error message and a retry control so the user can attempt to load the summary again.

### Print

**FR-PED-006** — Print action
While the summary is displayed, when the user triggers the Print action, the system shall invoke the browser print flow (e.g. `window.print()`) so the user can print or save as PDF from the print dialog.

**FR-PED-007** — Print-friendly layout
When the user prints the Pediatrician summary page, the system shall present a one-page, doctor-friendly layout (via print stylesheet or media query) that includes the child name, period, and feeding/diaper/sleep aggregates, and hides or simplifies navigation and non-essential UI so the printed output is readable and compact.

### Access control

**FR-PED-008** — Authorization
The Pediatrician summary screen shall be protected by the same authentication and child-access rules as other child-scoped screens (e.g. dashboard, analytics). When the user does not have access to the child, the system shall respond with the same error behavior as other child routes (e.g. 403/404 and user-facing error).

## Non-Functional Requirements

### Performance

- Weekly-summary response uses existing analytics cache (e.g. 10-minute TTL); no new server-side caching is required.
- Screen shall display loading state until data is received; target first contentful paint consistent with other child dashboard/analytics pages.

### Security

- Same authorization as analytics: user must have access to the child (owner, co-parent, or caregiver).
- No new API surface; reuse existing `weekly-summary` endpoint and auth.

### Usability

- Layout optimized for quick scanning (headings, clear numbers, bottle vs breast, wet/dirty/both).
- Print output readable at default print scale (e.g. A4/Letter one page where possible).

## Acceptance Criteria (Given / When / Then)

**AC-001: Summary displays after load**
Given the user has access to the child and the child has at least one feeding, diaper, or nap in the last 7 days
When the user navigates to the Pediatrician summary for that child
Then the system displays the child’s name, “Last 7 days” (or equivalent period), and the feeding, diaper, and sleep aggregates from the weekly-summary API.

**AC-002: Loading and empty states**
Given the user has access to the child
When the user opens the Pediatrician summary and the API has not yet responded
Then a loading indicator is shown.
When the API returns with all zero counts
Then an empty state is shown (no error).

**AC-003: Error and retry**
Given the user has access to the child
When the weekly-summary request fails
Then an error message is displayed and the user can retry loading the summary.

**AC-004: Print**
Given the summary is displayed
When the user clicks Print
Then the browser print dialog opens.
When the user prints the page
Then the printed output shows the summary in a readable, one-page-friendly layout with navigation/buttons hidden or simplified.

**AC-005: Unauthorized access**
Given the user does not have access to the child
When the user navigates to the Pediatrician summary URL for that child
Then the system shows an appropriate error (e.g. from API 403/404) and does not expose other children’s data.

## Error Handling

<!-- markdownlint-disable MD060 -->

| Condition                | HTTP / context | User-facing behavior                    |
| ------------------------ | -------------- | --------------------------------------- |
| Child not found / 404    | 404            | Error message; link back to My Children |
| No access to child / 403 | 403            | Error message; link back to My Children |
| API / network error      | 5xx / network  | Error message and retry button          |
| Invalid childId in URL   | —              | Error state and back navigation         |

<!-- markdownlint-enable MD060 -->

## Implementation TODO

### Frontend

- [x] Add route `/children/:childId/pediatrician-summary` with auth guard (same as other child routes).
- [x] Create `PediatricianSummaryComponent` that:
    - Resolves `childId` from route; loads child name (e.g. via `ChildrenService.get`) and weekly summary via `AnalyticsService.getWeeklySummary(childId)`.
    - Renders child name, period, and feeding/diaper/sleep sections from `WeeklySummaryData`.
    - Handles loading (skeleton/spinner), empty (all zeros), and error (message + retry).
- [x] Add Print button that calls `window.print()`.
- [x] Add print stylesheet (or `@media print`) to hide nav/footer/buttons and format summary for one-page print.
- [x] Add link to Pediatrician summary from child context (e.g. Advanced options and optionally dashboard or analytics).
- [x] Set page title (e.g. “Pediatrician summary - PoopyFeed”).

### Testing

- [x] Unit tests: component loads weekly summary and child; displays loading, content, empty, and error states; retry triggers reload; Print button calls `window.print()`.
- [ ] Optional E2E: navigate to Pediatrician summary from child context; assert summary section and Print button visible.

### Backend

- No backend changes required for MVP (existing `weekly-summary` endpoint and `get_weekly_summary` are sufficient).

## Out of Scope (this iteration)

- Configurable date range (e.g. 14 or 30 days).
- Dedicated “Download PDF” endpoint for one-page summary (user may use browser “Save as PDF” from print dialog).
- Sharing the summary to a doctor portal or external system.

## Open Questions

- None; MVP scope is print-only. One-page PDF download can be added in a follow-up if needed.
