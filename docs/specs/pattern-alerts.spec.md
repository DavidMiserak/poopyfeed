# Feature Spec: Pattern Alerts

## Context

Pattern Alerts surface data-driven nudges on the dashboard when a child's current state
deviates from their own historical patterns. Unlike feeding reminders (fixed-interval push
notifications set by the user), pattern alerts are computed from each child's actual history
and displayed inline on the dashboard — no push notification infrastructure required.

**Core value by persona:**

- **Mom (Sarah)**: "It's been 3h 30m — baby usually feeds every 3h" lets her act before the
  baby gets distressed, without needing to calculate intervals herself.
- **Dad (Michael)**: Glancing at the dashboard immediately shows whether anything is overdue,
  even if he forgot to enable feeding reminders.
- **Maria (Nanny)**: Clear amber alert at the top of the dashboard removes guesswork about
  when the next feed or nap is due.

**Decisions:**

- Two alert types: **feeding** (based on average inter-feeding interval) and **nap** (based
  on average wake window — time from nap end to next nap start)
- Pattern computed from last 7 days of history
- Alert fires at 1.1× the computed average (10% buffer to avoid false positives)
- Minimum data requirements before an alert can fire: 4+ feedings (3+ intervals) for feeding;
  3+ completed naps (2+ wake windows) for nap
- Alerts are non-dismissible, non-persistent — they resolve automatically when a feeding or
  nap is logged
- Dashboard loads alerts separately (after main content) so they never delay the primary render
- Alerts are display-only; they do not create notification records or send push notifications

---

## Functional Requirements (EARS)

### Backend — Computation

**FR-PAL-001** — Average feeding interval
When computing pattern alerts for a child, the system shall calculate the mean duration
between consecutive feedings logged in the last 7 days, in minutes.

**FR-PAL-002** — Average wake window
When computing pattern alerts for a child, the system shall calculate the mean duration
between the end of one completed nap and the start of the next nap, for naps in the last 7
days. Naps without `ended_at` shall be excluded from this calculation.

**FR-PAL-003** — Feeding alert threshold
When the time elapsed since the most recent feeding exceeds `avg_feeding_interval × 1.1`,
and at least 4 feedings exist in the last 7 days, the system shall set `feeding.alert = true`
with a human-readable message.

**FR-PAL-004** — Nap alert threshold
When the time elapsed since the most recently completed nap's end time exceeds
`avg_wake_window × 1.1`, and at least 3 completed naps exist in the last 7 days, the system
shall set `nap.alert = true` with a human-readable message.

**FR-PAL-005** — Insufficient data
While a child has fewer than 4 feedings in the last 7 days, the system shall return
`feeding.alert = false` regardless of time elapsed. While a child has fewer than 3 completed
naps in the last 7 days, the system shall return `nap.alert = false`.

**FR-PAL-006** — No feedings on record
While a child has no feeding history at all, the system shall return `feeding.alert = false`.

**FR-PAL-007** — No completed naps on record
While a child has no completed nap history (no naps with `ended_at` set), the system shall
return `nap.alert = false`.

### Backend — API

**FR-PAL-008** — Endpoint
The system shall expose `GET /api/v1/analytics/children/<pk>/pattern-alerts/` returning a
JSON object with `child_id`, `feeding`, and `nap` keys.

**FR-PAL-009** — Access control
When a user requests pattern alerts for a child they do not have access to, the system shall
return HTTP 404.

**FR-PAL-010** — Caching
The system shall cache pattern alert responses per child for 120 seconds to avoid computing
intervals on every dashboard load.

**FR-PAL-011** — Message format
When `feeding.alert = true`, the message shall read:
`"Baby usually feeds every {X}h — it's been {Y}h {Z}m"`.
When `nap.alert = true`, the message shall read:
`"Baby usually naps after ~{X}h awake — awake for {Y}h {Z}m"`.

### Frontend — Dashboard

**FR-PAL-012** — Separate load
When the dashboard finishes loading its primary data (child, feedings, diapers, naps,
today-summary), the system shall issue a separate HTTP request for pattern alerts so that
alert loading never delays the dashboard render.

**FR-PAL-013** — Alert cards display
When one or more pattern alerts have `alert = true`, the system shall display an amber alert
card for each active alert at the top of the dashboard content (above the Quick Log section).

**FR-PAL-014** — No alert when none active
While all pattern alerts have `alert = false`, the system shall not render any alert cards.

**FR-PAL-015** — Silent error handling
When the pattern alerts endpoint returns an error, the system shall silently suppress the
error and render the dashboard without alert cards. Pattern alerts are non-critical and shall
not block or degrade the main dashboard.

**FR-PAL-016** — Auto-resolve
When a feeding is logged via Quick Log or the feeding form, the system shall trigger a
re-fetch of pattern alerts so the feeding alert clears immediately if the new feeding
resolves the overdue condition.

---

## Non-Functional Requirements

- **Performance**: `compute_pattern_alerts` queries at most 2 DB tables (Feeding, Nap),
  both filtered to last 7 days with indexed timestamp columns. Must complete in < 50 ms.
- **Freshness**: 2-minute cache is acceptable; alerts are advisory, not safety-critical.
- **Accuracy**: Computation uses wall-clock time from DB timestamps, not cached values, to
  ensure the elapsed time is accurate at cache-miss moments.
- **No side effects**: Endpoint is read-only; it never creates Notification records or
  FeedingReminderLog entries.

---

## Acceptance Criteria

**AC-001: Feeding alert fires when overdue**
Given a child has 6 feedings in the last 7 days with an average interval of 3h, and the last
feeding was 3h 25m ago
When the pattern-alerts endpoint is called
Then `feeding.alert = true` and `feeding.message` contains "3h" and "3h 25m".

**AC-002: Feeding alert does not fire when not overdue**
Given the same child and average interval, but the last feeding was 2h 50m ago
When the pattern-alerts endpoint is called
Then `feeding.alert = false`.

**AC-003: Feeding alert suppressed with insufficient data**
Given a child has only 2 feedings in the last 7 days
When the pattern-alerts endpoint is called
Then `feeding.alert = false` and `feeding.data_points = 2`.

**AC-004: Feeding alert suppressed with no feedings**
Given a child has never had a feeding logged
When the pattern-alerts endpoint is called
Then `feeding.alert = false`.

**AC-005: Nap alert fires when wake window exceeded**
Given a child has 4 completed naps in the last 7 days with an average wake window of 2h,
and the last nap ended 2h 15m ago
When the pattern-alerts endpoint is called
Then `nap.alert = true` and `nap.message` contains "2h" and "2h 15m".

**AC-006: Nap alert suppressed with insufficient naps**
Given a child has only 2 completed naps in the last 7 days
When the pattern-alerts endpoint is called
Then `nap.alert = false`.

**AC-007: Incomplete naps excluded from wake window**
Given a child has 5 naps but 2 have no `ended_at`
When the pattern-alerts endpoint is called
Then only the 3 completed naps are used for wake window computation.

**AC-008: Access control**
Given user B has no access to child C
When user B calls `GET /api/v1/analytics/children/C/pattern-alerts/`
Then the response is HTTP 404.

**AC-009: Dashboard renders without alerts when endpoint errors**
Given the pattern-alerts endpoint returns 500
When the dashboard loads
Then the main dashboard content is visible with no error state and no alert cards.

**AC-010: Alert card appears above Quick Log**
Given `feeding.alert = true`
When the dashboard renders
Then an amber card with the feeding message is visible above the Quick Log section.

**AC-011: Alert clears after logging a feeding**
Given the feeding alert card is visible
When the user logs a feeding via Quick Log
Then the pattern-alerts endpoint is re-fetched and the alert card disappears if the new
feeding resolves the overdue condition.

---

## Response Shape

```json
{
    "child_id": 1,
    "feeding": {
        "alert": true,
        "message": "Baby usually feeds every 3h — it's been 3h 30m",
        "avg_interval_minutes": 180,
        "minutes_since_last": 210,
        "last_fed_at": "2026-02-28T10:30:00Z",
        "data_points": 14
    },
    "nap": {
        "alert": false,
        "message": null,
        "avg_wake_window_minutes": 120,
        "minutes_awake": 95,
        "last_nap_ended_at": "2026-02-28T12:00:00Z",
        "data_points": 6
    }
}
```

---

## Error Handling

| Condition                            | Behavior                                                  |
| ------------------------------------ | --------------------------------------------------------- |
| Child not found or user lacks access | HTTP 404 (consistent with all analytics endpoints)        |
| No feedings in last 7 days           | `feeding.alert = false`, `data_points = 0`                |
| No completed naps in last 7 days     | `nap.alert = false`, `data_points = 0`                    |
| Frontend fetch error (network, 5xx)  | Silent suppression; dashboard renders without alert cards |
| Cache miss during high load          | DB query runs; response time acceptable (< 50 ms target)  |

---

## Implementation Notes

**Backend — `back-end/analytics/utils.py`**
Add `compute_pattern_alerts(child_id, now=None)` using `Feeding` and `Nap` models.
Two private helpers: `_compute_interval_alert` (feeding gaps) and `_compute_wake_alert`
(nap end → next nap start gaps).

**Backend — `back-end/analytics/views.py`**
Add `pattern_alerts` action to `AnalyticsViewSet` using existing `_get_cached_data` helper
with `cache_ttl=120`. Follow same pattern as `today_summary`.

**Backend — `back-end/analytics/urls.py`**
Add `path("children/<pk>/pattern-alerts/", ..., name="analytics-pattern-alerts")`.

**Frontend — models**
Add `PatternAlertItem` and `PatternAlertsData` interfaces to the analytics model file.

**Frontend — `analytics.service.ts`**
Add `getPatternAlerts(childId)` method following existing service patterns.

**Frontend — `child-dashboard.ts`**
Add `patternAlerts` signal and `activeAlerts` computed. Load via separate subscription
after `forkJoin` completes. Re-fetch after `onQuickLogged()` callback (feeding only).

**Frontend — `child-dashboard.html`**
Insert `@if (activeAlerts().length > 0)` block above the Quick Log section using Tailwind
amber palette (`bg-amber-50`, `border-amber-200`, `text-amber-900`).
