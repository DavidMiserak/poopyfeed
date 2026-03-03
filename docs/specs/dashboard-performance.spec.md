# Feature: Dashboard Performance Optimizations

## Overview

The dashboard (`/children/{id}/dashboard`) scores 93 (mobile) / 91 (desktop) on Lighthouse
performance. While all Core Web Vitals are green except Speed Index (5.1s, orange), the page
fires 11 parallel API calls after hydration, causing incremental visual updates that drag SI
down. Two optimizations target this: a batch API endpoint to reduce round-trips, and skeleton
screens to improve perceived performance during data loading.

**Core value by persona:**

- **Mom (Sarah)**: Dashboard feels instant — skeleton placeholders give immediate feedback that
  data is loading, reducing anxiety that a tap didn't register.
- **Dad (Michael)**: Single API call means the dashboard populates faster on spotty mobile
  connections (fewer round-trips = less latency sensitivity).
- **Maria (Nanny)**: Visual skeleton layout confirms she's on the right page before data loads,
  reducing confusion during quick check-ins between tasks.

**Implementation status:** Fully implemented and complete (backend: `dashboard-summary` endpoint, 5-min cache, invalidation; frontend: batch call, section skeletons, aria attributes).

---

## Baseline (March 2026)

### Lighthouse Scores

| Page                              | Performance | Accessibility | Best Practices | SEO |
| --------------------------------- | ----------- | ------------- | -------------- | --- |
| `/children/1/dashboard` (mobile)  | 93          | 100           | 100            | 100 |
| `/children/1/dashboard` (desktop) | 91          | 100           | 100            | 100 |

### Core Web Vitals (Mobile)

| Metric                   | Value   | Score | Rating |
| ------------------------ | ------- | ----- | ------ |
| First Contentful Paint   | 1,688ms | 92    | green  |
| Largest Contentful Paint | 2,513ms | 89    | orange |
| Total Blocking Time      | 60ms    | 100   | green  |
| Cumulative Layout Shift  | 0       | 100   | green  |
| Speed Index              | 5,130ms | 61    | orange |
| Time to Interactive      | 2,513ms | 98    | green  |

### Resource Budget

- 36 requests, 247 KiB total transfer
- 150 KiB JS (29 chunks), 66 KiB fonts (2 woff2), 13 KiB CSS
- Server TTFB: 20ms (SSR document)
- No render-blocking resources

### API Response Times (Production)

| Endpoint                                     | Server Time | Network TTFB |
| -------------------------------------------- | ----------- | ------------ |
| `GET /children/1/`                           | 24ms        | 37ms         |
| `GET /children/1/feedings/`                  | 38ms        | 62ms         |
| `GET /children/1/diapers/`                   | 28ms        | 49ms         |
| `GET /children/1/naps/`                      | 33ms        | 57ms         |
| `GET /analytics/.../today-summary/`          | 10ms        | 28ms         |
| `GET /analytics/.../weekly-summary/`         | 10ms        | 39ms         |
| `GET /analytics/.../feeding-trends/?days=7`  | 10ms        | 35ms         |
| `GET /analytics/.../diaper-patterns/?days=7` | 16ms        | 32ms         |
| `GET /analytics/.../sleep-summary/?days=7`   | 14ms        | 30ms         |
| `GET /analytics/.../timeline/`               | 16ms        | 34ms         |
| `GET /notifications/unread-count/`           | 12ms        | 30ms         |

### Root Cause

The 11 parallel API calls resolve at different times, each updating a section of the dashboard
UI. Lighthouse measures each visual change as incomplete progress, dragging Speed Index to 5.1s.
The APIs themselves are fast (10–38ms server-side) — the issue is the number of discrete visual
updates, not backend latency.

---

## Part 1: Batch Dashboard Endpoint

### Batch Endpoint — Functional Requirements

**FR-DASH-001** — Batch dashboard summary
When `GET /api/v1/children/{childId}/dashboard-summary/` is called with a valid auth token,
the system shall return a JSON response combining today-summary, weekly-summary, and
notification unread-count in a single payload.

**FR-DASH-002** — Response structure
The system shall return the following structure:

```json
{
    "today": {
        /* today-summary fields */
    },
    "weekly": {
        /* weekly-summary fields */
    },
    "unread_count": 3
}
```

**FR-DASH-003** — Permission check
While the authenticated user does not have access to the child,
when the batch endpoint is called,
the system shall return 404 (consistent with existing permission denial pattern).

**FR-DASH-004** — Cache behavior
The system shall cache the batch response with the same TTL as today-summary (5 minutes),
since today-summary is the most volatile component.

**FR-DASH-005** — Cache invalidation
When a tracking record (feeding, diaper, nap) is created or deleted for the child,
the system shall invalidate the batch dashboard cache
(reuse existing `invalidate_child_cache` signal).

**FR-DASH-006** — Frontend integration
When the dashboard component loads,
the system shall call the batch endpoint instead of three separate calls
(today-summary, weekly-summary, unread-count), reducing API calls from 11 to 9.

**FR-DASH-007** — Backward compatibility
The system shall preserve the individual endpoints (`today-summary/`, `weekly-summary/`,
`notifications/unread-count/`) unchanged, since other components use them independently.

### Batch Endpoint — Non-Functional Requirements

#### Batch Endpoint Performance

- Response time: < 50ms p95 (server-side), matching the sum of the slowest individual endpoint
- Cache hit ratio: same as today-summary (~90% during active use)
- No additional database queries beyond what the three individual endpoints already execute

#### Batch Endpoint Security

- Authentication: Token auth required (existing `IsAuthenticated` permission)
- Authorization: `HasChildAccess` permission (any role: owner, co-parent, caregiver)

---

## Part 2: Dashboard Skeleton Screens

### Skeleton Screens — Functional Requirements

**FR-SKEL-001** — Skeleton layout on initial load
While the dashboard data has not yet loaded,
the system shall display skeleton placeholder elements matching the layout of each dashboard
section (today summary card, weekly summary card, recent activity list, action buttons).

**FR-SKEL-002** — Skeleton appearance
The system shall render skeleton placeholders as rounded grey rectangles with a subtle
shimmer animation, using the existing design token colors (`bg-gray-200` base,
`bg-gray-300` shimmer highlight).

**FR-SKEL-003** — Transition to real content
When API data resolves for a dashboard section,
the system shall replace the skeleton for that section with the real content,
without layout shift (CLS must remain 0).

**FR-SKEL-004** — Section-level granularity
The system shall show/hide skeletons independently per section, so fast-resolving sections
(e.g., today-summary at 10ms) display real data while slower sections (e.g., feedings list
at 38ms) still show skeletons.

**FR-SKEL-005** — SSR behavior
While rendering server-side (SSR),
the system shall render skeleton placeholders (not empty divs), so the initial HTML paint
includes visible layout structure.

**FR-SKEL-006** — Error state
While an API call fails for a dashboard section,
the system shall replace the skeleton with an error message
(reuse existing error handling patterns with toast notifications).

### Skeleton Screens — Non-Functional Requirements

#### Skeleton Performance

- Skeleton CSS must add < 1 KiB to the stylesheet (inline Tailwind classes preferred)
- No additional JavaScript for skeleton rendering (pure CSS shimmer animation)
- CLS impact: 0 (skeletons must match the exact dimensions of loaded content)

#### Accessibility

- Skeleton elements shall include `aria-busy="true"` while loading
- Skeleton elements shall include `aria-label="Loading [section name]"`
- When content loads, `aria-busy` shall be removed

---

## Acceptance Criteria

### Batch Endpoint

**AC-DASH-001**: Batch returns combined data
Given an authenticated user with access to child 1
When `GET /api/v1/children/1/dashboard-summary/` is called
Then the response contains `today`, `weekly`, and `unread_count` keys
And the `today` object matches the structure of `today-summary/`
And the `weekly` object matches the structure of `weekly-summary/`
And `unread_count` is an integer >= 0

**AC-DASH-002**: Batch respects permissions
Given a user with no access to child 1
When `GET /api/v1/children/1/dashboard-summary/` is called
Then the response is 404

**AC-DASH-003**: Batch is cached
Given the batch endpoint has been called for child 1
When the same endpoint is called within 5 minutes with no data changes
Then the response is served from cache (no additional DB queries)

**AC-DASH-004**: Cache invalidates on tracking change
Given the batch endpoint response is cached for child 1
When a new feeding is created for child 1
Then the next batch endpoint call returns fresh data

**AC-DASH-005**: Frontend uses batch endpoint
Given the dashboard component loads for child 1
When the network requests are observed
Then there is one call to `/dashboard-summary/` instead of three separate calls
And the total API call count is 9 or fewer (down from 11)

### Skeleton Screens

**AC-SKEL-001**: Skeletons visible during load
Given the dashboard is loading data
When the page is rendered
Then each dashboard section shows skeleton placeholders
And no section is blank/empty during loading

**AC-SKEL-002**: No layout shift on content load
Given skeleton placeholders are displayed
When real content replaces the skeletons
Then CLS is 0 (no visible jump or reflow)

**AC-SKEL-003**: Accessibility attributes present
Given the dashboard is loading
When a screen reader accesses the page
Then skeleton sections announce "Loading [section name]"
And `aria-busy="true"` is set on loading sections

**AC-SKEL-004**: SSR renders skeletons
Given the page is rendered server-side
When the initial HTML is inspected
Then skeleton placeholder elements are present in the document

---

## Error Handling

| Error Condition             | HTTP Code | User Message                                     | Notes                              |
| --------------------------- | --------- | ------------------------------------------------ | ---------------------------------- |
| Unauthenticated             | 401       | "Your session expired"                           | Redirect to login                  |
| Child not found / no access | 404       | Page not found                                   | Consistent with existing pattern   |
| Backend unavailable         | 500       | Toast: "Failed to load dashboard"                | Skeleton replaced with error state |
| Individual sub-query fails  | 500       | Batch endpoint returns error for entire response | Do not partially succeed           |

---

## Implementation TODO

### Backend

- [x] Create `DashboardSummaryView` in `analytics/views.py` (or new file)
- [x] Reuse `get_today_summary()`, `get_weekly_summary()` utility functions
- [x] Query `Notification.objects.filter(recipient=user, is_read=False).count()` for unread
- [x] Add `HasChildAccess` permission check
- [x] Add 5-minute cache with key `analytics:dashboard-summary:{child_id}`
- [x] Register cache key in `invalidate_child_cache()` for signal-based invalidation
- [x] Add URL route: `children/<pk>/dashboard-summary/` in `api_urls.py`
- [x] Write tests: permission check, response structure, cache behavior, cache invalidation

### Frontend

- [x] Add `getDashboardSummary(childId)` method to analytics or children service
- [x] Create `DashboardSkeletonComponent` (standalone, pure template + Tailwind CSS)
- [x] Add shimmer animation CSS (Tailwind `animate-pulse` or custom keyframes)
- [x] Update dashboard component to use batch endpoint for today/weekly/unread
- [x] Add `isLoading` signals per dashboard section
- [x] Show skeletons while `isLoading()` is true, real content when false
- [x] Add `aria-busy` and `aria-label` to skeleton containers
- [x] Ensure skeleton dimensions match loaded content (prevent CLS)
- [x] Write tests: skeleton renders during loading, replaced on data arrival, aria attributes

### Testing

- [x] Backend unit tests for `DashboardSummaryView` (8–10 tests)
- [x] Frontend unit tests for skeleton component (3–5 tests)
- [x] Frontend unit tests for batch endpoint integration (3–5 tests)
- [ ] Lighthouse re-audit after implementation to measure SI improvement
- [ ] Manual CLS verification (Chrome DevTools > Performance > Layout Shifts)

---

## Out of Scope

- **SSR data preloading**: Requires forwarding auth tokens to backend during server-side
  rendering — significant architectural change to the auth flow for marginal gain. The auth
  guard returns `true` on server to allow SSR shell rendering; preloading data would need
  a separate server-side auth mechanism.
- **Combining all 11 API calls into one**: The remaining 8 calls (child detail, feedings,
  diapers, naps, feeding-trends, diaper-patterns, sleep-summary, timeline) serve distinct
  UI sections and are used by other components independently. Batching them would create a
  monolithic endpoint with poor cache characteristics.
- **Service worker API caching**: The app intentionally avoids caching API responses in the
  service worker (real-time baby data must be fresh). This decision is documented in the PWA
  configuration section of CLAUDE.md.

## Expected Impact

| Metric                       | Before           | Target                        | Notes                            |
| ---------------------------- | ---------------- | ----------------------------- | -------------------------------- |
| API calls per dashboard load | 11               | 9                             | 3 calls merged into 1            |
| Speed Index (mobile)         | 5,130ms          | ~4,000ms                      | Fewer discrete visual updates    |
| Performance score (mobile)   | 93               | 95–97                         | SI improvement drives score up   |
| CLS                          | 0                | 0                             | Skeletons must maintain zero CLS |
| Perceived load time          | ~3s visual churn | < 1s to skeleton, ~2s to full | Skeleton gives instant feedback  |
