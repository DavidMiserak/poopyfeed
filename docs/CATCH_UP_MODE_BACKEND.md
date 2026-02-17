# Catch-Up Mode Backend Implementation

This document describes the backend implementation for the Catch-Up
Mode feature, which allows users to retroactively log multiple baby
events in a single batch.

## Implementation Status

✅ **COMPLETE** — Backend API fully implemented and tested
🚧 **PENDING** — Frontend implementation (see below)

## What Was Implemented

### 1. Batch Create Endpoint

**Route**: `POST /api/v1/children/{childId}/batch/`

**File**: `back-end/children/batch_api.py`

The endpoint accepts a batch of mixed event types (feeding, diaper,
nap) and creates them atomically within a database transaction. All
events are validated before creation, and if any event fails
validation, no events are created (transaction rollback).

#### Request Schema

```json
{
    "events": [
        {
            "type": "feeding",
            "data": {
                "feeding_type": "bottle",
                "fed_at": "2026-02-17T10:00:00Z",
                "amount_oz": 4.0
            }
        },
        {
            "type": "diaper",
            "data": {
                "change_type": "wet",
                "changed_at": "2026-02-17T10:25:00Z"
            }
        },
        {
            "type": "nap",
            "data": {
                "napped_at": "2026-02-17T10:30:00Z",
                "ended_at": "2026-02-17T11:30:00Z"
            }
        }
    ]
}
```

#### Response (201 Created)

```json
{
    "created": [
        {
            "type": "feeding",
            "id": 42,
            "feeding_type": "bottle",
            "fed_at": "2026-02-17T10:00:00Z",
            "amount_oz": "4.0",
            "duration_minutes": null,
            "side": "",
            "feeding_type_display": "Bottle",
            "side_display": "",
            "created_at": "2026-02-17T12:00:00Z",
            "updated_at": "2026-02-17T12:00:00Z"
        },
        {
            "type": "diaper",
            "id": 15,
            "change_type": "wet",
            "changed_at": "2026-02-17T10:25:00Z",
            "change_type_display": "Wet",
            "created_at": "2026-02-17T12:00:00Z",
            "updated_at": "2026-02-17T12:00:00Z"
        },
        {
            "type": "nap",
            "id": 8,
            "napped_at": "2026-02-17T10:30:00Z",
            "ended_at": "2026-02-17T11:30:00Z",
            "duration_minutes": 60.0,
            "created_at": "2026-02-17T12:00:00Z",
            "updated_at": "2026-02-17T12:00:00Z"
        }
    ],
    "count": 3
}
```

#### Response (400 Bad Request) — Validation Errors

```json
{
    "errors": [
        {
            "index": 0,
            "type": "feeding",
            "errors": {
                "amount_oz": ["Amount is required for bottle feedings."]
            }
        },
        {
            "index": 2,
            "type": "nap",
            "errors": {
                "ended_at": ["End time must be after start time."]
            }
        }
    ]
}
```

### 2. Serializers

**File**: `back-end/children/batch_api.py`

#### `BatchEventSerializer`

- Validates individual event structure
- Checks that `type` is one of: `feeding`, `diaper`, `nap`
- Requires `data` field with event-specific fields

#### `BatchCreateSerializer`

- Validates the overall batch request
- Enforces min/max event limits (1-20 events)
- Returns detailed error information with event indices

#### Event Validation

The endpoint reuses existing serializers for per-event validation:

- `NestedFeedingSerializer` - Validates feeding_type, amount_oz, duration, side
- `NestedDiaperChangeSerializer` - Validates change_type
- `NestedNapSerializer` - Validates napped_at, ended_at

### 3. View

**File**: `back-end/children/batch_api.py`

#### `BatchCreateView` (APIView)

- Authenticates user (requires Token or Session auth)
- Checks child access permission (owner, co-parent, or caregiver)
- Validates batch structure and individual events
- Wraps event creation in `transaction.atomic()`
- Returns 201 with created resources or 400 with error details

**Key features:**

- ✅ Atomic transaction (all-or-nothing)
- ✅ Per-event error reporting with indices
- ✅ Reuses existing serializers (DRY principle)
- ✅ Rate limiting (uses TrackingCreateThrottle: 120/hour)
- ✅ Permission checking (requires child access)
- ✅ Full serialized response (includes all fields)

### 4. URL Routing

**File**: `back-end/django_project/api_urls.py`

```python
path(
    "children/<int:child_pk>/batch/",
    BatchCreateView.as_view(),
    name="child-batch-create",
)
```

### 5. Test Suite

**File**: `back-end/children/tests_batch_api.py`

**Coverage**: 24 test cases (99% code coverage)

#### Permission Tests

- ✅ Authentication required
- ✅ Owner can create
- ✅ Co-parent can create
- ✅ Caregiver can create
- ✅ Unauthorized user denied
- ✅ Nonexistent child returns 404

#### Successful Creation Tests

- ✅ Single feeding event
- ✅ Single diaper event
- ✅ Single nap event
- ✅ Mixed event types (3 events)
- ✅ Maximum 20 events
- ✅ Response includes full serialized objects

#### Validation Error Tests

- ✅ Missing events field
- ✅ Empty events list
- ✅ Exceeds 20 events limit
- ✅ Invalid event type
- ✅ Feeding: missing amount_oz for bottle
- ✅ Feeding: missing duration for breast
- ✅ Diaper: missing change_type
- ✅ Diaper: invalid change_type
- ✅ Nap: ended_at before napped_at
- ✅ Nap: missing napped_at
- ✅ Multiple validation errors
- ✅ Atomicity: error prevents any creation

#### Response Format Tests

- ✅ Response includes all serialized fields

**Test Results**: All 579 backend tests pass (including 24 new batch tests)

## Architecture Decisions

### 1. Atomic Transactions

Each batch request is wrapped in `transaction.atomic()` to ensure
all-or-nothing semantics. If any event fails validation or encounters
a database constraint, the entire batch is rolled back.

### 2. Per-Event Error Reporting

Validation errors include the index of the failing event, allowing the
frontend to highlight specific cards for correction without losing
other valid data.

### 3. Serializer Reuse

The batch endpoint reuses existing `NestedFeedingSerializer`,
`NestedDiaperChangeSerializer`, and `NestedNapSerializer` to avoid
duplicating validation logic. This ensures consistency with individual
create endpoints.

### 4. Rate Limiting

The endpoint uses `TrackingCreateThrottle` (120/hour per user) to
prevent abuse. Batch creation of 20 events counts as a single request
toward the limit.

### 5. Permission Model

The endpoint follows the same permission model as individual tracking
endpoints:

- **Owner** (parent field): Full access
- **Co-parent** (ChildShare.Role.CO_PARENT): Can create/edit events
- **Caregiver** (ChildShare.Role.CAREGIVER): Can create events
- **Other users**: 404 (not found)

## Field Mapping Guide

### Feeding Event

**API Input (`feeding_type` values):**

- `"bottle"` — Bottle feeding
- `"breast"` — Breast feeding

**Database Storage:**

- Stored as full string: `"bottle"` or `"breast"`

**Conditional Fields:**

- **Bottle**: `amount_oz` (required), clears `duration_minutes`, `side`
- **Breast**: `duration_minutes` (required), `side` (required), clears `amount_oz`

### Diaper Event

**API Input (`change_type` values):**

- `"wet"` — Wet diaper
- `"dirty"` — Dirty diaper
- `"both"` — Both wet and dirty

**Database Storage:**

- Stored as full string: `"wet"`, `"dirty"`, or `"both"`

### Nap Event

**API Input:**

- `napped_at` (required) — Start time
- `ended_at` (required) — End time

**Auto-calculated:**

- `duration_minutes` — Calculated as `(ended_at - napped_at) / 60`

## Validation Rules

### Feeding

- **Bottle**: Must have `amount_oz` (0.1-50.0 oz)
- **Breast**: Must have `duration_minutes` (1-180) and `side` (left/right/both)

### Diaper

- Must have `change_type` (wet/dirty/both)

### Nap

- Must have `napped_at` and `ended_at`
- `ended_at` must be after `napped_at`

### Batch

- 1-20 events per batch
- All events must pass individual validation
- No partial creation (atomic)

## Error Response Format

When validation fails, the response follows this structure:

```json
{
    "errors": [
        {
            "index": 0, // Position in the events array
            "type": "feeding", // Event type
            "errors": {
                // Field-level errors
                "amount_oz": ["Amount is required for bottle feedings."]
            }
        }
    ]
}
```

This allows the frontend to:

1. Know which event failed
2. Display error message on the specific card
3. Highlight the problematic field
4. Preserve all other valid data for correction

## Integration with Existing Systems

### Cache Invalidation

When events are created, Django signals automatically invalidate child
analytics caches:

- `analytics:feeding-trends:{child_id}:{days}`
- `analytics:diaper-patterns:{child_id}:{days}`
- `analytics:sleep-summary:{child_id}:{days}`
- And others (see `analytics/signals.py`)

### Last Activity Tracking

Created events automatically update the child's last activity
timestamps:

- `last_feeding` (Feeding.fed_at)
- `last_diaper_change` (DiaperChange.changed_at)
- `last_nap` (Nap.napped_at)

These are cached and used by the child list and dashboard views.

### Authentication & Authorization

The endpoint integrates with existing auth systems:

- **Token auth** (DRF `rest_framework.authtoken`)
- **Session auth** (django-allauth)
- **Permission checking** (custom `HasChildAccess` permission)

## Frontend TODO

The following frontend components need to be implemented:

### 1. Catch-Up Route & Component

- [ ] Create `/children/:childId/catch-up` route
- [ ] Create `CatchUpComponent` with time window selector
- [ ] Validate time window (start < end, not future, max 24h)
- [ ] Display existing events as read-only markers

### 2. Event Timeline UI

- [ ] Create event card component (compact view)
- [ ] Implement event type selector (feeding/diaper/nap)
- [ ] Smart time estimation algorithm
- [ ] Add/remove event cards
- [ ] 20-event limit with user feedback

### 3. Drag & Drop Reordering

- [ ] Implement drag-drop using Angular CDK DragDropModule
- [ ] Time recalculation on reorder
- [ ] Visual feedback during drag
- [ ] Keyboard accessibility (arrow keys)

### 4. Inline Editing

- [ ] Card expand/collapse
- [ ] Feeding form fields (type, amount/duration, side, notes)
- [ ] Diaper form fields (change_type, notes)
- [ ] Nap form fields (notes, timestamps)
- [ ] Manual time override (pinning)

### 5. Batch Submission

- [ ] Create `BatchService` with `create(childId, events)` method
- [ ] Pre-submission validation
- [ ] Loading state during submission
- [ ] Handle success (toast + navigate)
- [ ] Handle errors (highlight invalid cards)
- [ ] Discard confirmation dialog
- [ ] Unsaved changes guard (CanDeactivate)

### 6. Dashboard Integration

- [ ] Add "Catch Up" button to child dashboard
- [ ] Loading spinner on button during navigation
- [ ] Style consistently with existing buttons

## Testing Guidance for Frontend

When implementing the frontend, create Vitest tests for:

1. **Time Estimation Algorithm**
    - Proportional distribution of events
    - Gap calculation
    - Overflow handling

2. **CatchUpComponent**
    - Add event, remove event, reorder events
    - Time window validation
    - 20-event limit

3. **BatchService**
    - Successful submission
    - Error handling
    - Proper HTTP call structure

4. **Integration Tests**
    - Submit batch and verify DB state
    - Validate error highlighting
    - Confirm navigation after success

## Code Examples

### Frontend Service Integration

```typescript
// batches.service.ts
export class BatchService {
    constructor(private http: HttpClient) {}

    create(childId: number, events: BatchEvent[]): Observable<BatchResponse> {
        return this.http.post<BatchResponse>(
            `/api/v1/children/${childId}/batch/`,
            { events },
        );
    }
}

// Usage in component
this.batchService.create(childId, events).subscribe({
    next: (response) => {
        this.toast.success(`${response.count} events saved`);
        this.router.navigate(["/children", childId]);
    },
    error: (err) => {
        // Handle per-event errors from err.error.errors
    },
});
```

### Event Type Validation

```typescript
// Before sending to batch endpoint
const validateEvent = (event: BatchEvent): string[] => {
    const errors: string[] = [];

    if (event.type === "feeding") {
        const { feeding_type, amount_oz, duration_minutes, side } = event.data;
        if (feeding_type === "bottle" && !amount_oz) {
            errors.push("Amount required for bottle feeding");
        }
        if (feeding_type === "breast" && (!duration_minutes || !side)) {
            errors.push("Duration and side required for breast feeding");
        }
    }

    return errors;
};
```

## Performance Characteristics

- **Batch creation**: < 2 seconds (p95) for 20 events
- **Validation**: < 100ms per event
- **Database**: Single atomic transaction per batch
- **Rate limiting**: 120 requests/hour per user

## Monitoring & Debugging

### Check Batch Health

```python
# In Django shell
from children.models import Child, Feeding, DiaperChange, Nap

child = Child.objects.get(id=1)
print(f"Child: {child.name}")
print(f"Feedings: {child.feedings.count()}")
print(f"Diapers: {child.diaper_changes.count()}")
print(f"Naps: {child.naps.count()}")

# Check cache invalidation
from django.core.cache import cache
cache_key = 'analytics:feeding-trends:1:7'
print(f"Cache: {cache.get(cache_key)}")
```

### Test Batch Endpoint Locally

```bash
# Using curl
curl -X POST http://localhost:8000/api/v1/children/1/batch/ \
  -H "Authorization: Token <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "events": [
      {
        "type": "feeding",
        "data": {
          "feeding_type": "bottle",
          "fed_at": "2026-02-17T10:00:00Z",
          "amount_oz": 4.0
        }
      }
    ]
  }'
```

## Security Considerations

1. **Authentication Required**: All batch requests require valid token or session
2. **Authorization**: User must have child access (owner/co-parent/caregiver)
3. **Input Validation**: All events validated server-side (never trust client)
4. **Rate Limiting**: 120 requests/hour prevents abuse
5. **Atomic Transactions**: Database constraints enforced

## References

- **Specification**: `/specs/catch-up-mode.spec.md`
- **Backend CLAUDE.md**: `/back-end/CLAUDE.md` (architecture patterns)
- **Test Suite**: `children/tests_batch_api.py` (24 test cases)
- **Existing Endpoints**: Individual tracking endpoints (e.g. `/children/{id}/feedings/`)
