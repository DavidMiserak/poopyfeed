# Notifications Feature — Specification

## Overview

In-app notifications alert shared users (co-parents, caregivers) when someone logs a feeding, diaper change, or nap for a shared child. This closes the #1 gap identified in persona analysis: Dad (Michael) and others no longer need to open the app to discover new activity. Notifications are in-app only (bell icon and dropdown), with per-child preferences and global quiet hours. **Fully implemented and complete.**

## Implementation Status

| Phase       | Scope                                                                     | Status       |
| ----------- | ------------------------------------------------------------------------- | ------------ |
| **Phase 1** | Backend — Django app, models, signal, Celery tasks, REST API, tests       | **Complete** |
| **Phase 2** | Frontend — models, service, bell component, header, preferences UI, tests | **Complete** |

---

## Functional Requirements (EARS)

### Creation and delivery

**FR-NOTIF-001** — Activity-triggered creation
When a feeding, diaper change, or nap is created for a child (single or batch), the system shall enqueue a task to create in-app notifications for all users with access to that child except the actor.

**FR-NOTIF-002** — No self-notification
When notifications are created for an activity, the system shall exclude the user who performed the action (actor) from the recipient set.

**FR-NOTIF-003** — Per-child preference
While a user has a notification preference row for a child with a given event type disabled, when a notification would be created for that event type for that child, the system shall not create a notification for that user.

**FR-NOTIF-004** — Quiet hours
While a user has quiet hours enabled and the current time (in the user’s timezone) falls within the configured range, when a notification would be created for that user, the system shall not create the notification.

**FR-NOTIF-005** — Retention
The system shall delete notifications older than 30 days; cleanup shall run daily via Celery Beat.

### API — Notifications

**FR-NOTIF-006** — List notifications
While the user is authenticated, when GET `/api/v1/notifications/` is called, the system shall return the recipient’s notifications, paginated and ordered by `-created_at`.

**FR-NOTIF-007** — Unread count
When GET `/api/v1/notifications/unread-count/` is called, the system shall return `{"count": N}` where N is the number of unread notifications for the authenticated user.

**FR-NOTIF-008** — Mark all read
When POST `/api/v1/notifications/mark-all-read/` is called, the system shall set `is_read=True` for all unread notifications of the authenticated user and return the number updated.

**FR-NOTIF-009** — Mark single read
When PATCH `/api/v1/notifications/{id}/` is called for a notification owned by the authenticated user, the system shall set that notification’s `is_read=True` and return the updated notification.

**FR-NOTIF-010** — No direct create
When POST `/api/v1/notifications/` is called, the system shall respond with 405 Method Not Allowed.

### API — Preferences and quiet hours

**FR-NOTIF-011** — List preferences
When GET `/api/v1/notifications/preferences/` is called, the system shall ensure a preference row exists for each child the user can access (creating missing rows), then return all per-child notification preferences for the user.

**FR-NOTIF-012** — Update preference
When PATCH `/api/v1/notifications/preferences/{id}/` is called for a preference owned by the user, the system shall update the preference and return the updated representation.

**FR-NOTIF-013** — Get quiet hours
When GET `/api/v1/notifications/quiet-hours/` is called, the system shall return the user’s quiet hours (creating default if missing).

**FR-NOTIF-014** — Update quiet hours
When PATCH `/api/v1/notifications/quiet-hours/` is called with valid payload, the system shall update the user’s quiet hours and return the updated representation.

### Frontend requirements (Phase 2)

**FR-NOTIF-015** — Unread count polling
While the user is on a client with document (non-SSR), when the notification feature is active, the system shall poll GET `/api/v1/notifications/unread-count/` at least every 30 seconds and update the displayed unread count, pausing when the document is hidden and refreshing on focus.

**FR-NOTIF-016** — Bell and dropdown
When the user clicks the notification bell, the system shall toggle a dropdown that lists recent notifications (activity icon, message, relative time, read state) and provide a “Mark all read” action; when the user clicks a notification, the system shall navigate to that child’s dashboard and mark it read.

**FR-NOTIF-017** — Preferences UI
When the user opens account settings, the system shall display a Notifications section with per-child toggles (feedings, diapers, naps) and global quiet hours (enabled, start time, end time), persisting changes via the API on change.

---

## Non-Functional Requirements

### Performance

- Notification list and unread-count endpoints: respond within 200 ms p95 under normal load.
- Celery task `create_notifications_for_activity`: complete within 60 s time limit.
- Cleanup task: complete within 120 s time limit.
- Frontend polling interval: 30 s (configurable in code).

### Security

- All notification, preference, and quiet-hours endpoints require authentication (Token/session).
- Users may only read/update their own notifications, preferences, and quiet hours; access to another user’s notification or preference returns 404 Not Found (no information leakage).

### Data

- Notification message: max 255 characters.
- Quiet hours: interpreted in the user’s timezone (CustomUser.timezone); overnight ranges (e.g. 22:00–07:00) supported.

---

## Acceptance Criteria (Given / When / Then)

### Backend — Creation and isolation

**AC-001: Shared user receives notification**
Given user A and user B both have access to child C, and user B has not disabled notifications for that event type
When user A logs a feeding for child C
Then a notification is created for user B with the correct message and event type
And no notification is created for user A (actor).

**AC-002: Preference suppresses notification**
Given user B has a notification preference for child C with “Feedings” disabled
When user A logs a feeding for child C
Then no notification is created for user B
And other shared users still receive the notification if their preferences allow.

**AC-003: Quiet hours suppress notification**
Given user B has quiet hours enabled and current time (in user B’s timezone) is within that range
When user A logs an activity for a shared child
Then no notification is created for user B during that period.

**AC-004: Cleanup removes old notifications**
Given a notification older than 30 days exists for a user
When the daily cleanup task runs
Then that notification is deleted
And notifications younger than 30 days remain.

### Backend — API

**AC-005: List returns only own notifications**
Given user A is authenticated and has notifications, and user B has different notifications
When user A calls GET `/api/v1/notifications/`
Then the response contains only user A’s notifications, ordered newest first and paginated.

**AC-006: Unread count is correct**
Given user A has 3 unread notifications
When user A calls GET `/api/v1/notifications/unread-count/`
Then the response is `{"count": 3}`.

**AC-007: Mark all read**
Given user A has unread notifications
When user A calls POST `/api/v1/notifications/mark-all-read/`
Then all of user A’s notifications are marked read
And a subsequent unread-count returns 0.

**AC-008: Mark single read**
Given user A has an unread notification with id N
When user A calls PATCH `/api/v1/notifications/N/` (e.g. body `{}` or `{"is_read": true}`)
Then that notification is marked read and the updated notification is returned.

**AC-009: Cannot access other user’s notification**
Given user B has a notification with id N
When user A calls PATCH `/api/v1/notifications/N/`
Then the system returns 404 Not Found
And user B’s notification is unchanged.

**AC-010: Preferences auto-created**
Given user A has access to children C1 and C2 and no notification preference rows exist
When user A calls GET `/api/v1/notifications/preferences/`
Then preference rows are created for C1 and C2
And the response lists both with default toggles (all enabled).

**AC-011: Quiet hours round-trip**
Given user A has no quiet hours row
When user A calls GET `/api/v1/notifications/quiet-hours/` then PATCH with `{"enabled": true, "start_time": "22:00", "end_time": "07:00"}`
Then GET subsequently returns the updated values.

### Frontend (Phase 2)

**AC-012: Bell shows unread count**
Given the user is logged in and has unread notifications
When the header is displayed
Then the bell shows a badge with the unread count
And when unread count is 0, the badge is hidden.

**AC-013: Dropdown shows list and mark all read**
Given the user has notifications
When they click the bell
Then a dropdown opens with the list of notifications (icon, message, relative time)
And a “Mark all read” control is available
And when they click it, all are marked read and the badge updates.

**AC-014: Click notification navigates and marks read**
Given the dropdown is open and a notification for child X is shown
When the user clicks that notification
Then the app navigates to `/children/{childId}/dashboard` for child X
And that notification is marked read.

**AC-015: Preferences persist**
Given the user is on account settings Notifications section
When they toggle “Feedings” off for a child
Then a PATCH is sent to update that preference
And the UI reflects the new state.

---

## Error Handling

| Condition                                            | HTTP | User-facing / behavior                              |
| ---------------------------------------------------- | ---- | --------------------------------------------------- |
| Unauthenticated request to any notification endpoint | 401  | Require login (standard auth flow).                 |
| Notification or preference not found or not owned    | 404  | “Notification not found.” / “Preference not found.” |
| POST to create notification (direct)                 | 405  | “Method not allowed.”                               |
| Invalid quiet hours payload (e.g. invalid time)      | 400  | Validation errors per field (Django/DRF).           |
| Invalid preference payload                           | 400  | Validation errors per field.                        |
| Polling GET unread-count fails (network/5xx)         | —    | Silent (no toast); retry on next poll.              |
| Explicit list/mark-read/preferences call fails       | —    | Show error (e.g. toast) per app error handling.     |

---

## Implementation TODO

### Backend (Phase 1 — complete)

- [x] Create `notifications` app and models (Notification, NotificationPreference, QuietHours)
- [x] Add migrations, indexes, `unique_together`; register in `INSTALLED_APPS`
- [x] Define `tracking_created` signal and handler; dispatch from `tracking_api.py` and `batch_api.py`
- [x] Implement Celery tasks: `create_notifications_for_activity`, `cleanup_old_notifications`
- [x] Schedule cleanup in `CELERY_BEAT_SCHEDULE`
- [x] Implement views: NotificationViewSet (list, unread_count, mark_all_read, partial_update), NotificationPreferenceViewSet, QuietHoursView
- [x] Implement serializers (actor_name, child_name, child_id, etc.)
- [x] Register URLs in `api_urls.py`
- [x] Model/signal/task tests in `notifications/tests.py`
- [x] API tests in `notifications/tests_api.py`

### Frontend implementation (Phase 2 — complete)

- [x] Add `notification.model.ts` (Notification, UnreadCountResponse, MarkAllReadResponse, NotificationPreference, QuietHours) and export in `models/index.ts`
- [x] Create `notification.service.ts`: signals (notifications, unreadCount, isPolling), polling (30 s), visibility/SSR guards, list, markAsRead, markAllRead, getPreferences, updatePreference, getQuietHours, updateQuietHours
- [x] Create `notification-bell` component (bell, badge, dropdown, list on open, mark all read, click notification → navigate + mark read, click-outside close, aria)
- [x] Add NotificationBell to header (desktop and mobile)
- [x] Add Notifications section to account settings (quiet hours form fully implemented)
- [x] Add per-child notification toggles UI (implemented on child edit page)
- [x] `notification.service.spec.ts`: unread count, list, mark read, mark all read, polling, errors (18 tests)
- [x] `notification-bell.spec.ts`: bell, badge visibility, dropdown, mark all read, navigation, outside click (8 tests)
- [x] Account settings notification section unit tests (quiet hours — 5 tests)
- [x] Per-child notification toggles UI tests

### Verification

- [x] Backend: `make migrate`, `make test-backend-parallel-fast`, manual two-user notification check (complete)
- [x] Frontend: `make test-frontend` (2593 tests passing), `make build-frontend`, manual polling and bell flow (complete)
    - 39 notification-related tests all passing
    - Bell component tested and integrated in header
    - Quiet hours fully functional in account settings
    - Per-child toggles fully functional on child edit page
- [x] E2E: `make test-e2e` (existing tests pass after header change)

---

## Out of Scope

- Push notifications to device (FCM/APNs).
- Email or SMS delivery.
- Notifications for events other than feeding, diaper, nap (e.g. invites, profile changes).
- Per-child quiet hours (only global per-user quiet hours in scope).
- Real-time delivery (WebSocket/SSE); delivery is polling-based (e.g. 30 s).

---

## Reference — Key implementation details

### Backend

- **Signal**: `notifications.signals.tracking_created` — provides `instance`, `actor_id`, `event_type`. Handler calls `create_notifications_for_activity.delay(child_id, actor_id, event_type)`.
- **Event type mapping**: `Feeding` → `feeding`, `DiaperChange` → `diaper`, `Nap` → `nap`.
- **Recipients**: `child.parent_id` ∪ `ChildShare.user_id` for that child, minus `actor_id`.
- **Quiet hours**: `QuietHours.is_quiet_now()` uses `CustomUser.timezone` and supports overnight ranges (e.g. 22:00–07:00).
- **Authorization**: Notification and preference views filter by `recipient`/`user`; requests for another user’s resource yield 404 (not 403) to avoid leaking existence.

### API base path

All endpoints under `/api/v1/` (e.g. `/api/v1/notifications/`, `/api/v1/notifications/unread-count/`, `/api/v1/notifications/preferences/`, `/api/v1/notifications/quiet-hours/`).

### Frontend patterns

- Polling: same pattern as `export-job-status.ts` (e.g. `timer(0, 30_000)`, `switchMap`, `takeUntilDestroyed`).
- Service: signal-based state and ErrorHandler consistent with other app services.
- SSR: only start polling when `typeof document !== 'undefined'`; pause when `document.hidden`, refresh on focus.

### Files to create (frontend)

- `front-end/poopyfeed/src/app/models/notification.model.ts`
- `front-end/poopyfeed/src/app/services/notification.service.ts` + `.spec.ts`
- `front-end/poopyfeed/src/app/components/notification-bell/` (`.ts`, `.html`, `.css`, `.spec.ts`)

### Files to modify (frontend)

- `models/index.ts` — export notification types
- `components/header/header.ts` — import NotificationBell
- `components/header/header.html` — add bell (desktop nav ~line 37, mobile ~line 110)
- `account/settings/account-settings.ts` + `.html` — Notifications section
