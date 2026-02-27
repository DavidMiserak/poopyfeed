# Feature Spec: Feeding Reminders

## Context

Feeding reminders address the #1 missing need for Mom (Sarah): proactive alerts when no feeding has been logged for a configurable time window. Unlike the existing notification system (which fires reactively when someone _logs_ an activity), reminders fire on a schedule when _nothing_ has been logged. Dad (Michael) also benefits — he can see overdue status without manually opening the app.

**Decisions captured from interview:**

- Recipients: all users with access (owner + co-parents + caregivers)
- Interval: per-child, set by owner or co-parent; fixed options 2h / 3h / 4h / 6h; null = off; default 3h when enabled
- Repeat: fire once at t=interval, once more at t=interval×1.5 if still no feeding logged
- Delivery: in-app notification bell only (existing system)
- Quiet hours: reminders **bypass** quiet hours (safety-critical)
- notify_feedings toggle: reminders **respect** per-child `notify_feedings` (not separately asked, reasonable default)
- Never fires if no feedings on record for that child
- Enable/disable: interval = null means off

---

## Functional Requirements (EARS)

### Configuration

**FR-REM-001** — Interval field on child
When an owner or co-parent edits a child profile, the system shall allow setting a `feeding_reminder_interval` value of `null` (off), `2`, `3`, `4`, or `6` (hours).

**FR-REM-002** — Default off
When a child is created, the system shall set `feeding_reminder_interval` to `null` (reminders disabled by default).

**FR-REM-003** — Permission to configure
When a caregiver (non-owner, non-co-parent) accesses the child edit page, the system shall not expose or accept changes to `feeding_reminder_interval`.

### Reminder Firing

**FR-REM-004** — Initial reminder
When `feeding_reminder_interval` is non-null and the time elapsed since `last_feeding.fed_at` is greater than or equal to `interval` hours, and no initial reminder has been sent in the current feeding window, the system shall enqueue a reminder notification for all users with access to that child.

**FR-REM-005** — Repeat reminder
When an initial reminder has already been sent in the current feeding window and the time elapsed since `last_feeding.fed_at` is greater than or equal to `interval × 1.5` hours, and no repeat reminder has been sent in this window, the system shall enqueue one additional reminder notification.

**FR-REM-006** — No reminder without history
While a child has no feeding records, the system shall not send feeding reminders regardless of the configured interval.

**FR-REM-007** — Window reset
When a new feeding is logged for a child, the system shall treat the new `fed_at` as the start of a fresh reminder window, allowing the next reminder cycle to begin independently of previous ones.

**FR-REM-008** — Quiet hours bypass
When a feeding reminder notification is created, the system shall send it to all eligible recipients regardless of their quiet hours settings.

**FR-REM-009** — Respect notify_feedings preference
While a user has `notify_feedings = False` for a child, the system shall not send that user feeding reminder notifications for that child.

### Periodic Task

**FR-REM-010** — Polling interval
The system shall run the feeding-reminder check task every 30 minutes via Celery Beat.

**FR-REM-011** — Idempotency
The system shall guarantee that at most one initial reminder and one repeat reminder are sent per feeding window per child, even if the task runs multiple times.

### Frontend

**FR-REM-012** — Interval picker on child edit form
When editing a child, the system shall display a "Feeding Reminders" section with a dropdown: Off / 2 hours / 3 hours / 4 hours / 6 hours. Changes shall be saved immediately via PATCH on form submit.

**FR-REM-013** — Bell display
When a feeding reminder notification is received, the system shall display it in the notification bell dropdown with a distinct icon (e.g. 🍼⏰) and message.

---

## Non-Functional Requirements

- **Performance**: `check_feeding_reminders` must complete within 60 s under normal load (≤ 100 active children with reminders). Use `select_related` and batch queries; avoid N+1.
- **Security**: Only authenticated owners/co-parents may update `feeding_reminder_interval`; API must enforce role check.
- **Idempotency**: `FeedingReminderLog.unique_together = (child, window_start, reminder_number)` prevents duplicate sends even on task retry.
- **Accuracy**: Reminder task queries DB directly (not Redis cache) for `last_feeding` to avoid stale 30-min cache values.

---

## Acceptance Criteria

**AC-001: Reminder fires at threshold**
Given child has `feeding_reminder_interval = 3`, last feeding was 3h 5m ago, no reminders sent in this window
When the check task runs
Then a reminder notification is created for all users with access to the child
And a `FeedingReminderLog` entry with `reminder_number=1` is created.

**AC-002: Repeat reminder fires at 1.5× threshold**
Given child has `feeding_reminder_interval = 3`, last feeding was 4h 35m ago, one reminder already sent
When the check task runs
Then a second reminder notification is created
And a `FeedingReminderLog` entry with `reminder_number=2` is created.

**AC-003: No third reminder**
Given two reminders already sent for the current window
When the check task runs
Then no additional reminders are created.

**AC-004: Window resets on new feeding**
Given two reminders sent, then a new feeding is logged
When the check task runs 3h later
Then a new initial reminder fires (new window_start, no existing log entry).

**AC-005: No reminder without feeding history**
Given a child with `feeding_reminder_interval = 3` and no feedings ever logged
When the check task runs
Then no reminders are sent.

**AC-006: notify_feedings respected**
Given user A has `notify_feedings = False` for child C
When a feeding reminder fires for child C
Then user A receives no notification.

**AC-007: Quiet hours bypassed**
Given user B has quiet hours enabled covering the current time
When a feeding reminder fires for child C
Then user B still receives the notification.

**AC-008: Interval picker saves correctly**
Given the user selects "4 hours" in the interval dropdown and submits the form
When the backend receives the PATCH
Then `child.feeding_reminder_interval = 4` is saved and returned.

**AC-009: Caregivers cannot change interval**
Given user with role `caregiver` tries to PATCH `feeding_reminder_interval` on a child
When the request is processed
Then the system returns 403 Forbidden.

---

## Error Handling

| Condition                                                                          | Behavior                                                                                          |
| ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `check_feeding_reminders` task fails (DB down)                                     | Celery retries with exponential backoff; no duplicate log entries on retry due to unique_together |
| `FeedingReminderLog` unique constraint violated (race condition on duplicate task) | IntegrityError caught silently; treat as "already sent"                                           |
| Child deleted mid-task                                                             | Task catches `Child.DoesNotExist`, skips, continues                                               |
| `feeding_reminder_interval` value not in [2,3,4,6]                                 | API returns 400 validation error                                                                  |
| Bell displays unknown event_type                                                   | Falls back to default icon; no crash                                                              |

---

## Implementation Sections

See IMPLEMENTATION_PLAN.md for step-by-step backend and frontend implementation tasks.
