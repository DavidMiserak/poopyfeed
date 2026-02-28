# Feature: Catch-Up Mode

## Overview

Catch-Up Mode allows caregivers to retroactively log multiple baby
events (feedings, diapers, naps) in a single session when they've
fallen behind on real-time tracking. Users define a time window, add
events to a visual timeline, reorder them via drag-and-drop, and
submit the entire batch atomically. The system uses smart time
estimation based on typical activity durations to automatically space
events within the window.

This addresses a critical pain point for all three personas: Mom (too
exhausted to log in real time), Dad (catching up after receiving
verbal updates), and Caretaker (logging at end of shift).

**GitHub Issue**: #1 — "Catching Up"

## Functional Requirements

### Entry & Navigation

#### **FR-001: Dashboard Entry Point**

While the user is on the child dashboard, the system shall display a
"Catch Up" button alongside the existing feeding/diaper/nap action
buttons.

#### **FR-002: Route**

When the user clicks the "Catch Up" button, the system shall navigate
to `/children/{childId}/catch-up`.

#### **FR-003: Permission Check**

While the user's role is caregiver, the system shall still allow
access to Catch-Up Mode (caregivers can add events).

### Time Window Setup

#### **FR-010: Time Window Selection**

When the user enters Catch-Up Mode, the system shall prompt for a
start time and end time defining the catch-up window.

#### **FR-011: Default Time Window**

The system shall default the start time to 4 hours ago and the end
time to the current time.

#### **FR-012: Time Window Validation**

When the user sets the time window, the system shall validate that:

- Start time is before end time
- End time is not in the future (with 5-minute tolerance)
- The window does not exceed 24 hours

#### **FR-013: Existing Events Display**

While a time window is set, the system shall fetch and display
existing events (feedings, diapers, naps) from that window as
read-only, non-draggable reference markers on the timeline.

### Event Addition

#### **FR-020: Add Event**

While the timeline is active and the event count is below 20, when the
user taps an "Add" button, the system shall present a type selector
(Feeding, Diaper, Nap).

#### **FR-021: Event Card Creation**

When the user selects an event type, the system shall add a new event
card to the timeline showing:

- Event type icon (feeding: bottle/breast, diaper: droplet/poo, nap: moon)
- Auto-calculated estimated timestamp

#### **FR-022: Event Limit**

While the timeline contains 20 new events, when the user attempts to
add another, the system shall display a message: "Maximum 20 events
per session. Submit these first, then start a new session."

#### **FR-023: Remove Event**

When the user swipes or clicks the remove button on an event card, the
system shall remove it from the timeline and recalculate remaining
event times.

### Smart Time Estimation

#### **FR-030: Proportional Time Distribution**

The system shall distribute events within the time window
proportionally based on typical activity durations:

- Feeding: 20 minutes
- Diaper change: 5 minutes
- Nap: 60 minutes

#### **FR-031: Distribution Algorithm**

When events are added, removed, or reordered, the system shall
recalculate timestamps as follows:

1. Sum the typical durations of all new events
2. Calculate remaining gap time = (window duration) - (total typical durations)
3. Distribute gap time evenly between events (as buffer/transition time)
4. Assign each event a start time = previous event end + gap portion
5. Existing (read-only) events occupy fixed time slots; new events fill around them

#### **FR-032: Minimum Gap**

The system shall enforce a minimum 2-minute gap between consecutive
events.

#### **FR-033: Overflow Handling**

While the total typical duration of new events exceeds the time
window, the system shall display a warning: "These events may not fit
in the selected time window" and compress durations proportionally to
fit.

### Drag-and-Drop Reordering

#### **FR-040: Drag-and-Drop**

When the user long-presses (mobile) or clicks-and-drags (desktop) an
event card, the system shall allow reordering within the timeline.

#### **FR-041: Time Recalculation on Reorder**

When an event is dropped in a new position, the system shall
recalculate all new event timestamps using the proportional
distribution algorithm (FR-031).

#### **FR-042: Visual Feedback During Drag**

While an event card is being dragged, the system shall:

- Show a visual placeholder at the drop target position
- Dim the card being dragged
- Show estimated time labels updating in real-time at potential drop positions

#### **FR-043: Read-Only Event Anchoring**

While dragging events, existing (read-only) events shall remain fixed
in position and serve as anchor points around which new events are
distributed.

### Inline Editing

#### **FR-050: Card Expansion**

When the user taps an event card, the system shall expand it to show
editable fields inline.

#### **FR-051: Feeding Card Fields**

While a feeding event card is expanded, the system shall display:

- Feeding type toggle: Bottle / Breast (default: Bottle)
- Amount (oz) field (for bottle, default: empty)
- Duration (min) and Side fields (for breast)
- Notes field (optional)
- Estimated timestamp (editable)

#### **FR-052: Diaper Card Fields**

While a diaper event card is expanded, the system shall display:

- Change type selector: Wet / Dirty / Both (default: Wet)
- Notes field (optional)
- Estimated timestamp (editable)

#### **FR-053: Nap Card Fields**

While a nap event card is expanded, the system shall display:

- Notes field (optional)
- Estimated start timestamp (editable)
- End timestamp (auto-calculated from typical duration, editable)

#### **FR-054: Manual Time Override**

When the user edits an event's timestamp manually, the system shall:

- Accept the manual time for that event
- Not recalculate that event's time on subsequent reorders (pin it)
- Recalculate only unpinned events around it

#### **FR-055: Collapse Card**

When the user taps outside an expanded card or taps a collapse button,
the system shall collapse the card back to compact view showing type
icon + time + key detail (if entered).

### Batch Submission

#### **FR-060: Submit All**

While the timeline contains at least 1 new event, when the user taps
"Save All", the system shall submit all new events to the backend as a
single atomic batch.

#### **FR-061: Validation Before Submit**

When the user taps "Save All", the system shall validate:

- At least 1 new event exists
- All timestamps are within the defined time window
- Required fields are filled (feeding type, diaper change type)
- No two events share the exact same timestamp

#### **FR-062: Submission Loading State**

While the batch is being submitted, the system shall:

- Disable the "Save All" button and show a spinner
- Prevent adding, removing, or reordering events
- Display "Saving X events..."

#### **FR-063: Success Handling**

When all events are saved successfully, the system shall:

- Show a toast: "X events saved successfully"
- Navigate to the child dashboard

#### **FR-064: Failure Handling**

When the batch submission fails, the system shall:

- Show an error toast with the failure reason
- Keep all events in the timeline (no data loss)
- Re-enable the "Save All" button for retry

#### **FR-065: Discard Session**

When the user taps "Cancel" or navigates away with unsaved events, the
system shall show a confirmation dialog: "Discard X unsaved events?"

### Backend Batch API

#### **FR-070: Batch Create Endpoint**

When POST `/api/v1/children/{childId}/batch/` is called with a JSON
body containing an array of mixed events, the system shall:

- Validate all events in the array
- Create all events within a single database transaction
- Return all created resources with IDs and timestamps
- Return 400 with validation errors if any event is invalid (none saved)

#### **FR-071: Batch Request Schema**

The batch endpoint shall accept:

```json
{
    "events": [
        {
            "type": "feeding",
            "data": {
                "feeding_type": "bottle",
                "fed_at": "2024-02-17T10:00:00Z",
                "amount_oz": 4.0
            }
        },
        {
            "type": "diaper",
            "data": {
                "change_type": "wet",
                "changed_at": "2024-02-17T10:25:00Z"
            }
        },
        {
            "type": "nap",
            "data": {
                "napped_at": "2024-02-17T10:30:00Z",
                "ended_at": "2024-02-17T11:30:00Z"
            }
        }
    ]
}
```

#### **FR-072: Batch Size Limit**

The batch endpoint shall reject requests with more than 20 events,
returning 400: "Maximum 20 events per batch."

#### **FR-073: Batch Response**

When the batch succeeds, the system shall return 201 with:

```json
{
  "created": [
    { "type": "feeding", "id": 42, ... },
    { "type": "diaper", "id": 15, ... },
    { "type": "nap", "id": 8, ... }
  ],
  "count": 3
}
```

#### **FR-074: Batch Validation Errors**

When any event in the batch fails validation, the system shall return
400 with per-event error details:

```json
{
    "errors": [
        {
            "index": 0,
            "type": "feeding",
            "errors": {
                "amount_oz": ["This field is required for bottle feedings."]
            }
        }
    ]
}
```

## Non-Functional Requirements

### Performance

- Timeline UI should render smoothly with up to 20 new events + 20 existing events
- Drag-and-drop reorder should recalculate timestamps in < 16ms (60fps)
- Batch submission of 20 events should complete in < 2 seconds (p95)
- Time estimation algorithm should run in O(n) where n = number of events

### Security

- Authentication: Token authentication required (existing pattern)
- Authorization: User must have add permission for the child (owner, co-parent, or caregiver)
- Input validation: All events validated server-side within the batch endpoint
- Rate limiting: Batch endpoint counts as 1 request toward the create/update throttle (120/hour)

### Accessibility

- Drag-and-drop must have keyboard alternative (arrow keys to reorder)
- Screen reader announcements for: event added, event reordered, time recalculated
- All interactive elements must be focusable and operable via keyboard
- Touch targets minimum 44x44px for mobile (Maria persona - large buttons)

### Mobile UX

- Timeline must be usable one-handed on mobile (Mom persona)
- Swipe-to-remove gesture on event cards
- Long-press to initiate drag on touch devices
- Compact card view optimized for small screens

## Acceptance Criteria

### AC-001: Basic Catch-Up Flow

Given a user on the child dashboard
When they tap "Catch Up"
Then they see a time window selector defaulting to the last 4 hours
And they can add events to the timeline

### AC-002: Add Mixed Events

Given a user in Catch-Up Mode with a 9:00 AM - 1:00 PM window
When they add: 1 feeding, 1 diaper, 1 nap
Then the timeline shows 3 cards with auto-calculated times:

- Events are spaced proportionally (feeding ~20min, diaper ~5min, nap ~60min)
- All times fall within the 9:00 AM - 1:00 PM window

### AC-003: Drag-and-Drop Reorder

Given a timeline with events: Feeding (9:00), Diaper (9:47), Nap (9:54)
When the user drags the Nap to the first position
Then timestamps recalculate with Nap first (heaviest duration)
And all events remain within the time window

### AC-004: Existing Events as Context

Given a child with a feeding logged at 10:30 AM
When the user enters Catch-Up Mode with window 9:00 AM - 12:00 PM
Then the 10:30 AM feeding appears as a read-only marker
And new events are distributed around it

### AC-005: Inline Editing

Given a feeding card on the timeline
When the user taps it
Then it expands to show feeding type, amount, and notes fields
And the user can change the type from bottle to breast
And validators update accordingly (amount vs duration/side)

### AC-006: Manual Time Override

Given a timeline with 3 events with auto-calculated times
When the user manually changes the second event's time to 11:15 AM
Then that event stays at 11:15 AM (pinned)
And only the other events recalculate if reordered later

### AC-007: Successful Batch Submit

Given a timeline with 5 new events, all with valid data
When the user taps "Save All"
Then a spinner shows on the button with "Saving 5 events..."
And all 5 events are created in the database atomically
And a success toast appears: "5 events saved successfully"
And the user is navigated to the child dashboard

### AC-008: Batch Submit Validation Failure

Given a timeline with 3 events, one feeding missing amount_oz
When the user taps "Save All"
Then the invalid event card is highlighted with an error message
And no events are saved (atomic)
And the user can fix the error and retry

### AC-009: Event Limit Reached

Given a timeline with 20 new events
When the user taps "Add" to create a 21st event
Then a message displays: "Maximum 20 events per session"
And no new card is added

### AC-010: Discard Confirmation

Given a timeline with 3 unsaved events
When the user taps "Cancel" or navigates away
Then a confirmation dialog appears: "Discard 3 unsaved events?"
And choosing "Discard" navigates away without saving
And choosing "Keep Editing" returns to the timeline

### AC-011: Empty Window

Given a user in Catch-Up Mode with a time window set
When there are no existing events and no new events added
Then the timeline shows an empty state: "Tap + to start adding events"

### AC-012: Backend Transaction Atomicity

Given a batch of 5 events where the 4th event has a database constraint violation
When the batch endpoint processes the request
Then zero events are created (transaction rolled back)
And the response includes the specific validation error for event index 3

## Error Handling

| Error Condition                     | HTTP Code    | User Message                                                        |
| ----------------------------------- | ------------ | ------------------------------------------------------------------- |
| No events in batch                  | 400          | "Add at least one event before saving"                              |
| Batch exceeds 20 events             | 400          | "Maximum 20 events per batch"                                       |
| Invalid event data                  | 400          | Per-event field errors (see FR-074)                                 |
| End time before start time (window) | N/A (client) | "End time must be after start time"                                 |
| Window exceeds 24 hours             | N/A (client) | "Time window cannot exceed 24 hours"                                |
| End time in the future              | N/A (client) | "End time cannot be in the future"                                  |
| Duplicate timestamps                | N/A (client) | "Two events cannot have the same time"                              |
| Unauthorized                        | 401          | "Please log in to continue"                                         |
| No permission for child             | 404          | "Child not found" (existing pattern)                                |
| Network error during submit         | N/A          | "Failed to save events. Your data is preserved — please try again." |
| Server error                        | 500          | "Something went wrong. Your data is preserved — please try again."  |

## Implementation TODO

### Backend

- [ ] Create `POST /api/v1/children/{childId}/batch/` endpoint
- [ ] Implement `BatchCreateSerializer` that validates a mixed array of events
- [ ] Implement `BatchCreateView` that wraps creation in `transaction.atomic()`
- [ ] Add per-event-type validation using existing serializers (FeedingSerializer, DiaperChangeSerializer, NapSerializer)
- [ ] Add batch size limit validation (max 20)
- [ ] Add structured error response with per-event error indices
- [ ] Add URL routing for the batch endpoint
- [ ] Add permission check (child access + add permission)
- [ ] Add rate limiting (count batch as 1 request)
- [ ] Write unit tests for batch serializer
- [ ] Write API tests for batch endpoint (success, validation errors, transaction rollback, permissions, rate limiting)

### Frontend — Catch-Up Timeline Component

- [ ] Create route `/children/:childId/catch-up`
- [ ] Create `CatchUpComponent` with time window selector
- [ ] Implement time window validation (start < end, not future, max 24h)
- [ ] Fetch and display existing events in the window as read-only markers
- [ ] Create event type selector (feeding/diaper/nap) for adding cards
- [ ] Create compact event card component (icon + time)
- [ ] Implement smart time estimation algorithm (proportional distribution)
- [ ] Implement drag-and-drop reordering (Angular CDK DragDropModule)
- [ ] Implement time recalculation on reorder
- [ ] Implement event pinning (manual time override skips recalculation)
- [ ] Create inline editing forms for each event type
- [ ] Implement card expand/collapse interaction
- [ ] Enforce 20-event limit with user feedback
- [ ] Implement swipe-to-remove gesture (mobile)
- [ ] Implement keyboard reordering (accessibility)

### Frontend — Batch Submission

- [ ] Create `BatchService` with `create(childId, events)` method
- [ ] Implement "Save All" with validation before submit
- [ ] Implement loading state during submission
- [ ] Handle success: toast + navigate to dashboard
- [ ] Handle failure: highlight invalid cards, preserve data
- [ ] Implement "Cancel" with discard confirmation dialog
- [ ] Implement unsaved changes guard (CanDeactivate)

### Frontend — Dashboard Integration

- [ ] Add "Catch Up" button to child dashboard
- [ ] Add loading spinner on Catch Up button during navigation
- [ ] Style button consistently with existing action buttons

### Testing

- [ ] Backend: Unit tests for batch serializer validation
- [ ] Backend: API tests for batch endpoint (10+ scenarios)
- [ ] Frontend: Vitest tests for time estimation algorithm
- [ ] Frontend: Vitest tests for CatchUpComponent (add, remove, reorder)
- [ ] Frontend: Vitest tests for BatchService
- [ ] Frontend: Vitest tests for inline editing interactions
- [ ] Frontend: Vitest tests for discard confirmation guard

## Out of Scope

- **Recurring events / templates**: "Log same routine as yesterday" — future enhancement
- **Cross-child batch**: Adding events for multiple children in one session
- **Undo after submit**: Once batch is saved, individual edit/delete via existing UI
- **Offline support**: Catch-up mode requires network connectivity
- **Custom typical durations**: Fixed defaults (feeding: 20min, diaper: 5min, nap: 60min); user-configurable durations are a future enhancement
- **Bulk edit of existing events**: This feature only creates new events; editing existing events uses the current forms
- **Calendar/day view**: Full calendar visualization is a separate feature

## Resolved Questions

- [x] **Caregiver access**: All roles can use Catch-Up Mode (caregivers can add events)
- [x] **Nap ended_at**: Auto-set from typical duration (napped_at + 60min), editable by user
- [x] **Batch scope**: Create-only; editing existing events uses the standard forms
- [x] **Drag-and-drop library**: Angular CDK DragDropModule
