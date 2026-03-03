# Feature: The Fuss Bus

## Overview

The Fuss Bus is a guided troubleshooting wizard that helps parents and caregivers identify the cause of a child's fussiness and provides targeted soothing solutions. It uses a 3-step decision tree (symptom selection, smart checklist, targeted suggestions) that integrates with existing tracking data to auto-check items like recent feedings, diaper changes, and naps. Content is age-filtered using the child's date of birth and includes a persistent safety/self-care section.

**User value**: When a baby is crying and a parent is exhausted, they need quick, structured guidance — not a wall of text. The Fuss Bus acts like a pediatric nurse walking them through the most common causes, leveraging the data they already track to eliminate possibilities faster.

**Target personas**: All three — Sarah (exhausted mom needing quick guidance), Michael (data-driven dad who appreciates smart integration), and Maria (caregiver needing simple, clear steps with big tap targets).

**Priority**: High

**Implementation approach**: Frontend-only (no new backend models or endpoints). Uses existing APIs: `pattern-alerts`, `today-summary`, and child profile data. Accessible from both the child dashboard (quick-access button) and the Advanced Tools grid.

## Functional Requirements

### Navigation & Entry Points

#### FR-FB-001: Dashboard Entry Point

While viewing a child's dashboard, the system shall display a "Fuss Bus" action button with a bus icon that navigates to `/children/:childId/fuss-bus`.

#### FR-FB-002: Advanced Tools Entry Point

While viewing a child's Advanced Tools grid, the system shall display a "Fuss Bus" card in the "Insights & Reports" section that navigates to `/children/:childId/fuss-bus`.

#### FR-FB-003: Navigation Loading Indicator

When the user taps the Fuss Bus button, the system shall display a loading spinner on the button until navigation completes (consistent with existing dashboard button pattern).

#### FR-FB-004: Role Access

The system shall allow all roles (owner, co-parent, caregiver) to access The Fuss Bus for any child they have access to.

### Step 1: Symptom Selection

#### FR-FB-010: Symptom Type Selection

When the user opens The Fuss Bus, the system shall display four large tap targets for symptom selection:

- **Crying** — general distress, inconsolable
- **Refusing food** — visible only for children aged 12+ months
- **Won't sleep** — fighting naps, restless
- **General fussiness** — irritable, clingy, unsettled

#### FR-FB-011: Age-Filtered Symptom Options

While the child is under 12 months old (calculated from `date_of_birth`), the system shall hide the "Refusing food" option since food neophobia and toddler fussy eating are age-inappropriate.

### Step 2: Smart Checklist

#### FR-FB-020: Auto-Checked Items from Tracking Data

When the user selects a symptom type, the system shall fetch the child's recent tracking data (using existing `today-summary` and `pattern-alerts` APIs) and auto-populate checklist items:

| Checklist Item  | Data Source                                           | Auto-Check Logic                                            |
| --------------- | ----------------------------------------------------- | ----------------------------------------------------------- |
| Fed recently    | Last feeding from `pattern-alerts` or `today-summary` | Checked if fed within last feeding interval (or 3h default) |
| Clean diaper    | Last diaper change from timeline                      | Checked if changed within last 2 hours                      |
| Nap on schedule | Last nap end from `pattern-alerts`                    | Checked if wake window < age-appropriate threshold          |

#### FR-FB-021: Auto-Check Display Format

While a checklist item is auto-checked, the system shall display a green checkmark with contextual detail (e.g., "Fed 45 min ago (bottle, 4oz)") and the item shall be non-interactive (read-only).

#### FR-FB-022: Warning State for Borderline Items

While a tracked metric is near the threshold (e.g., wake window approaching limit), the system shall display the item with an amber warning icon and text (e.g., "Last nap ended 3.5 hours ago").

#### FR-FB-023: Missing Data Handling

While no tracking data exists for a checklist item (e.g., no feedings logged today), the system shall display the item as unchecked with a hint message (e.g., "No feedings logged today — check if hungry").

#### FR-FB-024: Manual Checklist Items

The system shall display manual (non-data-driven) checklist items that the user can tap to check/uncheck. Items vary by symptom type and child age:

**Common to all symptom types:**

- Comfortable temperature (not too hot/cold)
- Not overstimulated (calm environment)
- Held/comforted recently

**Age-filtered items (shown only when relevant):**

- No teething signs (4–24 months)
- No illness symptoms (fever, rash, vomiting)
- Not in a growth spurt (context: common at 2-3 weeks, 6 weeks, 3 months)
- Not experiencing separation anxiety (6+ months)

**Symptom-specific items:**

- "Crying" adds: Gas/burping needed, Witching hour (late afternoon, 0–4 months)
- "Refusing food" adds: Offering variety without pressure, Mealtime is relaxed, Milk intake < 400ml/day (12+ months)
- "Won't sleep" adds: Consistent sleep routine, Dark/quiet room, Not overtired (missed sleep window)

#### FR-FB-025: Age-Filtered Checklist Items

While the child's age (from `date_of_birth`) does not match the age range for a checklist item, the system shall hide that item from the checklist.

#### FR-FB-026: Checklist Progress Indicator

While the user is on Step 2, the system shall display a progress indicator showing how many items have been checked (auto + manual) out of total visible items.

### Step 3: Targeted Suggestions

#### FR-FB-030: Data-Driven Suggestions

When the user proceeds to Step 3, the system shall generate prioritized suggestions based on:

1. **Unchecked auto-check items** — highest priority (e.g., "Baby may be overtired — last nap ended 3.5 hours ago")
2. **Unchecked manual items** — contextual tips for items the parent hasn't confirmed
3. **Symptom-specific soothing techniques** — from the soothing toolkit

#### FR-FB-031: Soothing Toolkit

The system shall display a "Soothing Toolkit" section with categorized techniques:

- **Comforting Touch**: Rock, cuddle, massage, baby carrier, colic hold
- **Calming Sounds**: White noise, soft music, singing
- **Rhythmic Motion**: Stroller walk, car ride, gentle bouncing
- **Other**: Warm bath, swaddling, pacifier

#### FR-FB-032: Age-Specific Developmental Context

While the child's age matches a known developmental phase, the system shall display relevant context:

| Age Range                    | Context                                                                           |
| ---------------------------- | --------------------------------------------------------------------------------- |
| 0–4 months                   | "Witching hour (late afternoon fussiness) is normal and temporary"                |
| 2–3 weeks, 6 weeks, 3 months | "Growth spurts cause increased hunger and fussiness — increase feeding frequency" |
| 4–24 months                  | "Teething can cause discomfort — offer a chilled teething ring"                   |
| 6+ months                    | "Separation anxiety is normal — offer reassurance and consistent routines"        |
| 12+ months                   | "Appetite naturally decreases after the first year — don't force feed"            |

#### FR-FB-033: When to Call the Doctor

The system shall display a "When to Call the Doctor" section with warning signs:

- Fever (temperature thresholds by age)
- Persistent vomiting or diarrhea
- Rash or unusual skin changes
- Crying that sounds different from normal
- Lethargy or unresponsiveness
- Refusing fluids for extended period

#### FR-FB-034: Colic Guidance

While the child is 0–4 months old and the symptom is "Crying," the system shall include a colic information section explaining the 3-3-3 rule (>3 hours/day, >3 days/week, for 3+ weeks) and recommending pediatrician consultation.

### Safety & Self-Care

#### FR-FB-040: Parent Self-Care Section

The system shall display a persistent "Take Care of Yourself" section visible on Step 3 (and optionally collapsible) with:

- "Never shake a baby" warning with brief explanation
- "It's okay to put the baby in a safe place and step away for 10–15 minutes"
- "Ask for help — call a partner, family member, or friend"
- "Trust your instincts — you know your child best"

#### FR-FB-041: Self-Care Emphasis for Extended Sessions

While the user has been on The Fuss Bus for more than 5 minutes, the system shall visually elevate the self-care section (e.g., expand if collapsed, add emphasis styling).

### Navigation & Flow

#### FR-FB-050: Back Navigation

While on Step 2 or Step 3, the system shall provide a back button to return to the previous step, preserving any checked/unchecked state.

#### FR-FB-051: Start Over

While on any step, the system shall provide a "Start Over" action that resets the wizard to Step 1.

#### FR-FB-052: Step Indicator

The system shall display a 3-step progress indicator showing the current step (e.g., "Step 1 of 3: What's happening?").

#### FR-FB-053: Quick Log Shortcut

While on Step 2 and an auto-check item indicates a need (e.g., feeding overdue), the system shall provide a "Log now" link that navigates to the relevant tracking form (e.g., new feeding form) with a return path back to The Fuss Bus.

## Non-Functional Requirements

### Performance

- Step transitions shall feel instant (< 100ms for client-side state changes)
- API data fetch (today-summary + pattern-alerts) shall complete within 500ms (p95) — these endpoints are already cached
- Total wizard load time (Step 1 render + API fetch) shall be < 1 second
- No layout shift during data loading — use skeleton placeholders for auto-check items

### Accessibility

- All tap targets shall be minimum 44x44px (Maria persona requirement)
- All interactive elements shall be keyboard-navigable
- Screen reader support: ARIA labels on all checklist items, step indicators, and navigation controls
- Color is not the only indicator — icons accompany all status states (check, warning, unchecked)
- Respects `prefers-reduced-motion` for any animations

### UX

- One-handed operation: all primary actions reachable in the lower 2/3 of the screen
- Large, clear typography for reading in low light (common during night wake-ups)
- Minimal cognitive load: no more than 8 items visible per checklist category
- Warm, reassuring tone in all copy — no alarming language except in the "When to call the doctor" section

### Security

- No new backend endpoints — uses existing authenticated APIs
- No PII collected or stored beyond what's already in tracking data

## Acceptance Criteria

### AC-001: Full Happy Path — Crying Baby

Given a logged-in user viewing their 2-month-old child's dashboard
When they tap the "Fuss Bus" button
Then they see Step 1 with three symptom options (Crying, Won't sleep, General fussiness — "Refusing food" hidden for <12 months)
When they select "Crying"
Then they see Step 2 with auto-checked items from tracking data and manual checklist items including "Gas/burping needed" and "Witching hour"
When they check a few manual items and tap "Next"
Then they see Step 3 with prioritized suggestions based on unchecked items, a soothing toolkit, colic information (0-4 months), "When to call the doctor," and parent self-care section

### AC-002: Auto-Check with Recent Data

Given a child who was fed (bottle, 4oz) 30 minutes ago, had a diaper change 15 minutes ago, and last nap ended 2 hours ago
When the user opens The Fuss Bus and selects any symptom
Then the "Fed recently" item shows a green check with "Fed 30 min ago (bottle, 4oz)"
And the "Clean diaper" item shows a green check with "Changed 15 min ago"
And the "Nap on schedule" item shows a green check with "Last nap ended 2h ago"

### AC-003: Auto-Check with Missing Data

Given a child with no feedings logged today
When the user opens The Fuss Bus and selects any symptom
Then the "Fed recently" item shows unchecked with hint "No feedings logged today — check if hungry"

### AC-004: Auto-Check with Warning State

Given a child whose last nap ended 4 hours ago (exceeding age-appropriate wake window)
When the user opens The Fuss Bus and selects any symptom
Then the "Nap on schedule" item shows an amber warning icon with "Last nap ended 4h ago"

### AC-005: Age-Filtered Content for Toddler

Given a child who is 18 months old
When the user opens The Fuss Bus
Then Step 1 shows all four symptom options including "Refusing food"
When they select "Refusing food"
Then Step 2 includes toddler-specific items: "Offering variety without pressure," "Mealtime is relaxed," and "Milk intake"
And Step 3 includes developmental context about decreased appetite after first year

### AC-006: Age-Filtered Content for Newborn

Given a child who is 2 weeks old
When the user opens The Fuss Bus and selects "Crying"
Then Step 2 does NOT show teething, separation anxiety, or food-related items
And Step 2 DOES show growth spurt item (2-3 weeks)
And Step 3 includes colic information

### AC-007: Caregiver Access

Given a user with caregiver role for a child
When they navigate to the child's dashboard
Then the Fuss Bus button is visible
And they can complete the full 3-step wizard

### AC-008: Back Navigation Preserves State

Given a user on Step 3 who checked 3 manual items on Step 2
When they tap the back button
Then they return to Step 2
And all 3 previously checked manual items remain checked

### AC-009: Start Over Resets State

Given a user on Step 3
When they tap "Start Over"
Then they return to Step 1
And all previous selections and checks are cleared

### AC-010: Advanced Tools Grid Entry

Given a user on a child's Advanced Tools page
Then a "Fuss Bus" card is visible in the "Insights & Reports" section
When they tap it
Then they navigate to The Fuss Bus for that child

### AC-011: Self-Care Section After Extended Use

Given a user who has been on The Fuss Bus for more than 5 minutes
Then the parent self-care section is visually elevated (expanded, emphasized)

## Error Handling

| Error Condition                                   | Behavior                                                                                                                                     |
| ------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| API fetch fails (today-summary or pattern-alerts) | Show all checklist items as manual (unchecked) with message "Couldn't load tracking data — check items manually." Silent error, no blocking. |
| Child has no date_of_birth set                    | Show all age-dependent items (don't filter). Log warning.                                                                                    |
| Network offline                                   | Fuss Bus still works (content is client-side). Auto-check items show "Offline — check items manually."                                       |
| Child not found (invalid childId in URL)          | Redirect to children list with error toast "Child not found."                                                                                |
| Unauthorized access                               | Redirect to login (standard auth guard behavior).                                                                                            |

## Implementation TODO

### Frontend

- [ ] Create `FussBusComponent` at `features/fuss-bus/fuss-bus.ts` with 3-step wizard state management
- [ ] Create `SymptomSelectionComponent` (Step 1) with 4 large radio-card tap targets
- [ ] Create `SmartChecklistComponent` (Step 2) with auto-check + manual items
- [ ] Create `SuggestionsComponent` (Step 3) with prioritized suggestions, soothing toolkit, doctor section, self-care
- [ ] Create `StepIndicatorComponent` — 3-step progress bar
- [ ] Create `fuss-bus.data.ts` — all content data (causes, solutions, age ranges, soothing toolkit) as typed constants
- [ ] Create `fuss-bus.utils.ts` — age calculation, threshold logic, suggestion prioritization
- [ ] Add route `/children/:childId/fuss-bus` to children routing module
- [ ] Add Fuss Bus button to `child-dashboard.html` with loading spinner pattern
- [ ] Add Fuss Bus card to `advanced-tools-grid.html` in "Insights & Reports" section
- [ ] Integrate with existing `PatternAlertsService` and `TodaySummaryService` (or `DashboardSummaryService`) for auto-check data
- [ ] Implement age filtering using child's `date_of_birth`
- [ ] Implement back navigation with state preservation
- [ ] Implement "Start Over" reset
- [ ] Implement 5-minute timer for self-care emphasis (using `afterNextRender` + `setTimeout`, cleared on destroy)
- [ ] Style using design system tokens (rose/amber palette, Fredoka headings, radio-card pattern)
- [ ] Ensure SSR compatibility (`typeof window` checks for timer)
- [ ] Add `prefers-reduced-motion` support for any step transition animations

### Testing

- [ ] Unit tests for `fuss-bus.utils.ts` — age calculation, threshold logic, suggestion prioritization
- [ ] Unit tests for `SmartChecklistComponent` — auto-check states (checked, warning, missing, unchecked)
- [ ] Unit tests for `SymptomSelectionComponent` — age filtering of "Refusing food" option
- [ ] Unit tests for `SuggestionsComponent` — age-filtered developmental context
- [ ] Unit tests for `FussBusComponent` — step navigation, state preservation on back, reset on start over
- [ ] E2E test: full happy path (select symptom → check items → view suggestions)
- [ ] E2E test: age filtering (verify "Refusing food" hidden for infant, shown for toddler)
- [ ] E2E test: entry from dashboard button
- [ ] E2E test: entry from Advanced Tools grid
- [ ] E2E test: back navigation preserves state

### Backend

- [ ] No backend changes required for v1

## Out of Scope

- **Persistence / logging**: No tracking of troubleshooting sessions in v1. Consider for v2 to enable "what worked before" pattern detection.
- **Push notifications**: The Fuss Bus does not trigger notifications. It's an on-demand tool.
- **Custom content**: Parents cannot add their own causes or solutions in v1.
- **Multi-language support**: English only in v1.
- **Audio/video content**: No embedded media for soothing sounds or technique demonstrations.
- **AI-powered suggestions**: No ML-based cause prediction. Uses deterministic rules based on tracking data and age.
- **Integration with external health APIs**: No connection to pediatric databases or symptom checkers.

## Resolved Questions

- [x] Interaction model: Guided decision tree (3-step wizard)
- [x] Data integration: Yes, uses existing tracking data to auto-check items
- [x] Entry points: Dashboard button + Advanced Tools grid
- [x] Persistence: No persistence in v1 (frontend-only)
- [x] Age filtering: Auto-filter content by child's date_of_birth
- [x] Safety content: Always visible, emphasized after 5 minutes
- [x] Flow depth: 3 steps (symptom → checklist → suggestions)
- [x] Priority: High
- [x] Missing data handling: Show unchecked with hint message
- [x] Permissions: All roles (owner, co-parent, caregiver)
- [x] Fussy eating: Included in v1 for 12+ month children

## Open Questions

- [ ] Should the "Quick Log" shortcut (FR-FB-053) deep-link back to The Fuss Bus after logging, or just navigate to the form normally?
- [ ] What age-appropriate wake window thresholds should be used for the nap auto-check? (e.g., 0-3mo: 1-1.5h, 4-6mo: 1.5-2.5h, 7-12mo: 2-3.5h, 12+mo: 3-5h)
