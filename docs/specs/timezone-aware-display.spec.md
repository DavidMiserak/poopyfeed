# Feature: Timezone-Aware Display & Mismatch Detection

## Overview

All activity timestamps (feedings, diapers, naps) are stored in UTC and should be displayed using the user's **preferred timezone** from their profile — not the browser's local timezone. Additionally, when the browser detects that the user's current timezone differs from their saved preference (e.g., the user has traveled), the app should show a dismissable banner offering to update the preference.

This is a must-have UX fix. Parents and caregivers traveling across timezones (or with misconfigured system clocks) currently see times in their browser's local timezone, which may not match the timezone they've chosen in account settings.

**Implementation status:** Fully implemented and complete (DateTimeService methods, component updates, TimezoneBanner, TimezoneCheckService, session dismissal; deprecated `isToday()` removed from date.utils).

### User Value

- **Mom (Sarah)**: Sees correct times even when traveling to visit family in a different timezone
- **Dad (Michael)**: Times stay consistent with what Mom sees — no confusion about when baby last ate
- **Caretaker (Maria)**: Preset timezone from account settings is always respected regardless of device

## Functional Requirements

### FR-TZ-001: Absolute Time Display Uses User Preference

The system shall display all absolute timestamps (date/time formatted strings) using the user's `profile.timezone` preference rather than the browser's local timezone.

**Affected locations (audit):**

| #   | File                     | Function/Element         | Current Behavior                        |
| --- | ------------------------ | ------------------------ | --------------------------------------- |
| 1   | `feedings-list.ts`       | `formatDateTime()`       | `toLocaleString` without `timeZone`     |
| 2   | `diapers-list.ts`        | `formatDateTime()`       | `toLocaleString` without `timeZone`     |
| 3   | `naps-list.ts`           | `formatDateTime()`       | `toLocaleString` without `timeZone`     |
| 4   | `naps-list.ts`           | `formatTimeOnly()`       | `toLocaleString` without `timeZone`     |
| 5   | `feeding-delete.ts`      | `formatDateTime()`       | `toLocaleString` without `timeZone`     |
| 6   | `diaper-delete.ts`       | `formatDateTime()`       | `toLocaleString` without `timeZone`     |
| 7   | `nap-delete.ts`          | `formatDateTime()`       | `toLocaleString` without `timeZone`     |
| 8   | `child-timeline.ts`      | gap start/end times      | `toLocaleTimeString` without `timeZone` |
| 9   | `child-timeline.html`    | `date` pipe (`HH:mm`)    | No timezone parameter                   |
| 10  | `filter.service.ts`      | `formatDateForDisplay()` | `toLocaleDateString` without `timeZone` |
| 11  | `export-job-status.html` | `date` pipe (`short`)    | No timezone parameter                   |

### FR-TZ-002: Centralized Formatting via DateTimeService

When a component needs to format a UTC timestamp for display, the system shall provide formatting methods on `DateTimeService` so that the `timeZone` option is always set from `userTimezone`.

### FR-TZ-003: Relative Times Remain Unchanged

The system shall NOT modify relative time functions (`formatTimestamp`, `formatActivityAge`). These compute UTC millisecond diffs and are timezone-agnostic by design.

### FR-TZ-004: Browser Timezone Mismatch Detection

When the user's profile is loaded and the browser's IANA timezone (via `Intl.DateTimeFormat().resolvedOptions().timeZone`) differs from `profile.timezone`, the system shall emit a mismatch signal.

### FR-TZ-005: Timezone Mismatch Banner

While a timezone mismatch is detected and the user has not dismissed the banner this session, the system shall display a dismissable banner at the top of the page informing the user and offering to update their timezone preference.

Banner content example:

> "Your device timezone is **America/Chicago** but your account is set to **America/New_York**. [Update to America/Chicago] [Dismiss]"

### FR-TZ-006: One-Click Timezone Update

When the user clicks the "Update" action on the mismatch banner, the system shall call `PATCH /api/v1/account/profile/` with the browser's detected timezone and dismiss the banner on success.

### FR-TZ-007: Session-Scoped Dismissal

When the user dismisses the timezone mismatch banner, the system shall not show the banner again for the remainder of the browser session. On next login or new session, the check shall run again.

### FR-TZ-008: Deprecated `isToday()` Removal

The system shall remove the deprecated `isToday()` function from `date.utils.ts`. No imports of this function exist in the codebase.

## Non-Functional Requirements

### Performance

- Timezone detection (`Intl.DateTimeFormat().resolvedOptions().timeZone`) is synchronous and sub-millisecond — no performance impact
- `toLocaleString` with `timeZone` option has identical performance to without it
- No additional API calls beyond the existing profile fetch (already happens on app load)

### Security

- No new API endpoints required — uses existing `PATCH /api/v1/account/profile/`
- Timezone value validated server-side against `zoneinfo.available_timezones()` (already implemented)
- `sessionStorage` used for dismissal state (no sensitive data)

### Accessibility

- Banner must be an ARIA `role="alert"` or `role="status"` region
- Update and Dismiss buttons must be keyboard-accessible
- Banner should not auto-dismiss (user controls dismissal)

### SSR Compatibility

- Timezone detection must guard against SSR (`typeof window !== 'undefined'`)
- Banner should not render during SSR (no `Intl` API available server-side)

## Acceptance Criteria

### AC-TZ-001: Absolute Times Use Preferred Timezone

Given a user whose profile timezone is "America/New_York"
And their browser timezone is "America/Los_Angeles"
When they view a feeding logged at 2024-02-25T18:00:00Z
Then the time displays as "1:00 PM" (Eastern), not "10:00 AM" (Pacific)

### AC-TZ-002: Form Inputs Use Preferred Timezone

Given a user whose profile timezone is "America/New_York"
When they open the "New Feeding" form
Then the default datetime shows the current time in Eastern, not browser local

_(Already working via `DateTimeService.toInputFormat()` — verify no regression.)_

### AC-TZ-003: Mismatch Banner Appears

Given a user whose profile timezone is "America/New_York"
And their browser reports "America/Chicago"
When their profile loads on app start
Then a banner appears: "Your device timezone is America/Chicago but your account is set to America/New_York"
And the banner has an "Update" button and a "Dismiss" button

### AC-TZ-004: Update Button Changes Preference

Given the mismatch banner is visible
When the user clicks "Update to America/Chicago"
Then a PATCH request is sent to `/api/v1/account/profile/` with `{ timezone: "America/Chicago" }`
And on success, the banner disappears
And a toast confirms "Timezone updated successfully"
And all displayed times immediately reflect the new timezone

### AC-TZ-005: Dismiss Button Hides Banner for Session

Given the mismatch banner is visible
When the user clicks "Dismiss"
Then the banner disappears
And navigating to other pages does not re-show the banner
And refreshing the page (new session) shows the banner again

### AC-TZ-006: No Banner When Timezones Match

Given a user whose profile timezone is "America/New_York"
And their browser also reports "America/New_York"
When their profile loads
Then no mismatch banner appears

### AC-TZ-007: Timeline Day Grouping Uses Preferred Timezone

Given a user in "America/New_York" (UTC-5)
And a feeding logged at 2024-02-26T03:00:00Z (10:00 PM Feb 25 Eastern)
When viewing the timeline
Then the feeding appears under "February 25" (not February 26)

### AC-TZ-008: SSR Does Not Break

Given the app is rendering server-side
When the timezone detection code runs
Then no errors occur (guarded by `typeof window` check)
And no banner renders during SSR

## Error Handling

| Error Condition                                 | Behavior                                                  | User Message                                   |
| ----------------------------------------------- | --------------------------------------------------------- | ---------------------------------------------- |
| Profile not yet loaded                          | Skip mismatch check, no banner                            | None                                           |
| `Intl.DateTimeFormat` unavailable (old browser) | Skip mismatch check, fall back to browser local           | None                                           |
| PATCH timezone update fails (network error)     | Show error toast, keep banner visible                     | "Failed to update timezone. Please try again." |
| PATCH timezone update fails (invalid tz)        | Show error toast, keep banner visible                     | Server error message                           |
| `sessionStorage` unavailable                    | Banner may re-appear on navigation (graceful degradation) | None                                           |

## Implementation TODO

### Frontend — `DateTimeService` Enhancements

- [x] Add `formatDateTime(utcString)` method — returns "Mon DD, YYYY, H:MM AM/PM" in user tz
- [x] Add `formatTimeOnly(utcString)` method — returns "H:MM AM/PM" in user tz
- [x] Add `formatDateForDisplay(isoDate)` method — returns "Weekday, Mon DD" in user tz
- [x] Add `getBrowserTimezone()` static method — returns `Intl.DateTimeFormat().resolvedOptions().timeZone` with SSR guard
- [x] Add unit tests for all new methods with explicit timezone mocking

### Frontend — Fix Affected Components

- [x] `feedings-list.ts` — replace inline `formatDateTime()` with `DateTimeService.formatDateTime()`
- [x] `diapers-list.ts` — replace inline `formatDateTime()` with `DateTimeService.formatDateTime()`
- [x] `naps-list.ts` — replace inline `formatDateTime()` and `formatTimeOnly()` with `DateTimeService` methods
- [x] `feeding-delete.ts` — replace inline `formatDateTime()` with `DateTimeService.formatDateTime()`
- [x] `diaper-delete.ts` — replace inline `formatDateTime()` with `DateTimeService.formatDateTime()`
- [x] `nap-delete.ts` — replace inline `formatDateTime()` with `DateTimeService.formatDateTime()`
- [x] `child-timeline.ts` — add `timeZone: this.datetimeService.userTimezone` to gap time formatting
- [x] `child-timeline.html` — pass user timezone to `date` pipe
- [x] `filter.service.ts` — add `timeZone` to `formatDateForDisplay()`
- [x] `export-job-status.html` — pass user timezone to `date` pipe
- [x] Update tests for all modified components

### Frontend — Timezone Mismatch Banner

- [x] Create `TimezoneCheckService` — compares browser tz with profile tz, exposes `mismatch` signal and `dismissedThisSession` signal
- [x] Create `TimezoneBannerComponent` — dismissable banner with Update/Dismiss actions
- [x] Wire banner into app layout (above router outlet or in navbar area)
- [x] Add `sessionStorage` key `tz-banner-dismissed` for session-scoped dismissal
- [x] On "Update" click: call `AccountService.updateProfile({ timezone })`, dismiss on success, toast on error
- [x] Add unit tests for `TimezoneCheckService`
- [x] Add unit tests for `TimezoneBannerComponent`

### Frontend — Cleanup

- [x] Remove deprecated `isToday()` from `date.utils.ts`
- [x] Remove `isToday` from `date.utils.spec.ts`

### Backend

- [x] No backend changes required — existing `PATCH /api/v1/account/profile/` with `validate_timezone()` already handles timezone updates

## Out of Scope

- **Auto-updating timezone without user consent** — always prompt, never silently change
- **Multiple timezone support per user** (e.g., "home" vs "travel" timezone)
- **Timezone display in shared views** — each user sees times in their own preferred timezone (already the design)
- **Backend timestamp conversion** — API continues to return UTC; all conversion is frontend-only
- **Relative time changes** — `formatTimestamp()` and `formatActivityAge()` are UTC-diff based and timezone-agnostic

## Open Questions

- [ ] Should the banner also appear if the user's preference is still "UTC" (the default) and their browser reports a real timezone? This would help new users who never set a timezone. **Recommendation: Yes — treat UTC default as "not yet configured" and prompt.**
