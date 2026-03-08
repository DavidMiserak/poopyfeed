# Android–front-end feature parity specification

## Overview

This specification defines requirements for bringing the Android app to feature parity with the Angular front-end. The work is delivered in phases: Phase 1 (core tracking and child CRUD), Phase 2 (sharing and invites), Phase 3 (analytics, patterns, export, and Fuss Bus), Phase 4 (catch-up, timeline, notifications, and polish).

**User value:** Caregivers can use the native Android app to perform the same actions as on the web: manage children, log feedings/diapers/naps, manage sharing, accept invites, view pattern alerts, receive push notifications and reminders, and export data.

**Intentionally excluded (web-only):** Public marketing pages (`/`, `/contact`, `/privacy`, `/terms`), PWA installability, service worker caching, and update banner. These are handled by the web app and have no native-app equivalent.

---

## Functional requirements (EARS)

### Authentication and children

- **FR-1** While unauthenticated, when the user opens the app, the system shall show the greeting screen with options to log in or sign up.
- **FR-2** When the user submits valid login credentials, the system shall obtain an auth token, store it, and navigate to the children list.
- **FR-3** While authenticated, when the user opens "Add child", the system shall show a form (name, date of birth, gender) and on submit create the child via the API and navigate back to the children list.
- **FR-4** While viewing a child, when the user chooses "Edit child", the system shall show the child form pre-filled and on submit update the child via the API and navigate back.
- **FR-5** When the user confirms "Delete child", the system shall call the delete API and navigate to the children list.

### Tracking (feedings, diapers, naps)

- **FR-6** While viewing a child dashboard, when the user taps "Add feeding" (or diaper or nap), the system shall navigate to the corresponding create screen and on save create the record and navigate back.
- **FR-7** When the user saves or deletes a feeding, diaper, or nap, the system shall show success or error feedback (e.g. Snackbar or error banner) and refresh the list or dashboard as appropriate.
- **FR-8** While viewing a child, when the user opens the feedings (or diapers or naps) list, the system shall display all records for that child with options to add, edit, and delete.

### Sharing and invites

- **FR-9** While viewing a child with `can_manage_sharing`, when the user opens "Manage sharing", the system shall display current shares and invites and allow creating an invite (role: co-parent or caregiver) and revoking shares or deleting invites.
- **FR-10** When the user opens an invite-accept deep link (e.g. `poopyfeed://invites/accept/{token}`), the system shall show the accept screen and on accept call the API and navigate to the children list.

### Analytics, patterns, and export

- **FR-11** While viewing a child, when the user opens "Export data", the system shall allow choosing format (CSV or PDF) and date range (days); for CSV, the system shall download immediately; for PDF, the system shall start the job, poll status until complete, then offer download/open.
- **FR-12** When the user requests CSV export, the system shall call the export API and save the response to app cache and open it with the system handler (e.g. viewer or share).
- **FR-13** While viewing a child dashboard, when the backend returns pattern alerts (overdue feedings, nap wake-window warnings), the system shall display them prominently on the dashboard.
- **FR-14** While viewing a child, when the user opens "Pediatrician summary", the system shall generate a printable report aggregating recent trends and key stats and allow sharing or saving as PDF.
- **FR-15** While viewing a child, when the user opens "Advanced tools", the system shall show a hub screen with links to analytics, exports, pediatrician summary, Fuss Bus, and filtering options.
- **FR-15a** While viewing a child, when the user opens "Fuss Bus" (from the child dashboard or Advanced tools hub), the system shall show the Fuss Bus wizard: symptom selection (crying, won't sleep, general fussiness; "Refusing food" only for children 12+ months), smart checklist using pattern-alerts, dashboard summary, and timeline data, then targeted suggestions; all roles that can view the child shall be able to access it (no new backend; use existing APIs).

### Notifications, reminders, and quiet hours

- **FR-16** While authenticated, when the user opens the notifications center, the system shall display a list of pattern alerts, reminders, and system messages with unread counts.
- **FR-17** When a time-sensitive event occurs (overdue feeding, nap reminder), the system shall deliver a native push notification via FCM.
- **FR-18** While viewing a child with owner or co-parent role, when the user configures a feeding or nap reminder interval, the system shall schedule notifications when the next feeding or nap is due.
- **FR-19** While on the account screen, when the user configures quiet hours, the system shall suppress non-critical notifications during the configured time window.

### Timezone and accessibility

- **FR-20** When displaying timestamps, the system shall convert UTC values to the device's local timezone and show human-friendly relative times (e.g., "2 hours ago") where appropriate.
- **FR-21** The system shall provide large tap targets, sufficient color contrast (WCAG 2.1 AA), and TalkBack/accessibility service support for all interactive elements.

---

## Non-functional requirements

- **NFR-1** The app shall use the same REST API as the Angular front-end; no backend changes are required for parity.
- **NFR-2** All API errors shall be mapped to user-facing messages (no raw stack traces).
- **NFR-3** Navigation and submit actions shall show loading indicators where appropriate (e.g. disabled buttons, spinners).
- **NFR-4** Dashboard screens shall use batched API calls and skeleton screens to minimize API round-trips and improve perceived load performance.
- **NFR-5** All interactive elements shall meet WCAG 2.1 AA contrast ratios and provide content descriptions for TalkBack.
- **NFR-6** Push notifications shall be delivered via Firebase Cloud Messaging (FCM) and respect quiet-hours configuration.

---

## Acceptance criteria (Given/When/Then)

<!-- markdownlint-disable MD060 -->

| ID   | Given                                        | When                                      | Then                                                                                                                   |
| ---- | -------------------------------------------- | ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| AC1  | User is on children list                     | User taps FAB "Add child"                 | Add-child form is shown                                                                                                |
| AC2  | User submitted child form                    | Create API succeeds                       | User returns to list; new child appears                                                                                |
| AC3  | User is on child dashboard                   | User taps "Add feeding"                   | Feeding create screen is shown                                                                                         |
| AC4  | User submitted feeding                       | Create API succeeds                       | User returns to dashboard; summary updates                                                                             |
| AC5  | User is on sharing screen                    | User creates invite (role CG)             | New invite appears with link                                                                                           |
| AC6  | User opened invite link                      | User taps Accept                          | API is called; on success user sees children list                                                                      |
| AC7  | User is on export screen                     | User selects CSV, 30 days, Export         | CSV is downloaded and opened                                                                                           |
| AC8  | User is on export screen                     | User selects PDF, Export                  | Job is queued; status is polled; on completion PDF is downloaded                                                       |
| AC9  | Child has overdue feeding alert              | User views child dashboard                | Pattern alert banner is displayed prominently                                                                          |
| AC10 | User is on child dashboard                   | User taps "Pediatrician summary"          | Report is generated with recent trends; share/save options shown                                                       |
| AC11 | User is on child dashboard                   | User taps "Advanced tools"                | Hub screen shows links to analytics, export, summary, filters                                                          |
| AC12 | User is authenticated                        | User opens notifications center           | List of alerts and reminders is shown with unread count badge                                                          |
| AC13 | User is owner/co-parent                      | User sets feeding reminder to 3 hours     | Push notification fires when 3 hours since last feeding                                                                |
| AC14 | User configured quiet hours                  | Notification triggers during quiet window | Notification is suppressed until quiet hours end                                                                       |
| AC15 | Event timestamp is in UTC                    | User views timestamp on any screen        | Time is displayed in device local timezone                                                                             |
| AC16 | User is on child dashboard or Advanced tools | User taps "Fuss Bus"                      | Fuss Bus wizard is shown (symptom selection, checklist, suggestions); content is age-appropriate; all roles can access |

<!-- markdownlint-enable MD060 -->

---

## Error handling

<!-- markdownlint-disable MD060 -->

| Scenario                  | Handling                                                        |
| ------------------------- | --------------------------------------------------------------- |
| Network unavailable       | Show "No internet connection" (or similar) from repository      |
| 401 Unauthorized          | Clear token and navigate to greeting (or show re-login message) |
| 400 Validation            | Show field or detail message from API response body             |
| 403 Forbidden             | Show permission-denied message                                  |
| 404 Not found             | Show "Not found" and navigate back where appropriate            |
| Invalid/expired invite    | Show error on accept screen; allow navigation to children list  |
| PDF job failure           | Show error from export status response; stop polling            |
| FCM token registration    | Retry silently; fall back to in-app notifications if push fails |
| Quiet hours misconfigured | Validate start < end; show inline error if invalid              |
| Pattern alerts API error  | Show cached alerts if available; otherwise hide alerts section  |
| Pediatrician summary gen  | Show error toast if report generation fails; allow retry        |

<!-- markdownlint-enable MD060 -->

---

## Implementation checklist (phased)

### Phase 1: Core tracking and child CRUD (done)

- [x] Screen routes: AddChild, EditChild, ChildDelete; FeedingsList, FeedingCreate, FeedingEdit, FeedingDelete; same for Diapers and Naps
- [x] ChildrenApi: PATCH, DELETE; UpdateChildRequest DTO
- [x] FeedingsApi, DiapersApi, NapsApi and DTOs; repositories and ViewModels
- [x] Child create/edit form screen; child delete screen; wire FAB and dashboard edit/delete
- [x] Feedings/Diapers/Naps list, form (create/edit), delete screens; nav from dashboard
- [x] Dashboard quick actions: Add feeding, Add diaper, Add nap; View list links
- [x] Snackbar for success on child form; loading indicators on buttons

### Phase 2: Sharing and invites (done)

- [x] SharingApi: getShares, revokeShare, getInvites, createInvite, deleteInvite; DTOs
- [x] SharingRepository; SharingScreen (list shares, invite form, revoke/delete)
- [x] InvitesApi acceptInvite; AcceptInviteScreen; deep link `poopyfeed://invites/accept/{token}`
- [x] Link "Manage sharing" from child dashboard when `can_manage_sharing`

### Phase 3: Analytics, patterns, and export

- [x] AnalyticsApi: exportCsv, exportPdf, getExportStatus, downloadPdf
- [x] AnalyticsRepository export methods; ExportViewModel (CSV immediate, PDF poll then download)
- [x] ExportScreen: format (CSV/PDF), days (7/14/30), Export button; FileProvider for opening files
- [x] Link "Export data" from child dashboard
- [x] PatternAlertsApi: fetch alerts for child; display alert banners on dashboard
- [x] PediatricianSummaryScreen: generate and display report; share/save as PDF
- [x] AdvancedToolsScreen: hub linking analytics, export, pediatrician summary, Fuss Bus, filters
- [x] Fuss Bus: screen(s) for 3-step wizard (symptom selection, smart checklist, targeted suggestions); entry from child dashboard and Advanced tools; use pattern-alerts, dashboard summary, timeline, and child DOB; age-filtered symptom and checklist items; all roles can access

### Phase 4: Catch-up, timeline, notifications, and polish

- [x] Catch-up mode screen (quick sequential logging)
- [x] Child timeline screen (chronological activity list)
- [x] Account settings parity (e.g. change password) — Profile screen with Account tab (change password, delete account)
- [x] Design system alignment (colors, typography from docs) — Color.kt and Theme.kt match DESIGN_SYSTEM.md; Typography scale added
- [x] NotificationsApi: fetch notifications list with unread counts; mark as read
- [x] NotificationsScreen: in-app notification center with unread badge on nav
- [ ] FCM integration: register device token; receive and display native push notifications
- [x] Feeding/nap reminder configuration: interval picker on child settings (owner/co-parent only)
- [ ] Quiet hours: account settings UI for configuring suppression window; enforce locally
- [ ] Timezone-aware display: convert UTC timestamps to device timezone; relative time helpers ("2 hours ago")
- [ ] Dashboard performance: batched summary API call; skeleton loading screens
- [ ] Accessibility: large tap targets, WCAG 2.1 AA contrast, TalkBack content descriptions

---

## References

- Frontend feature inventory: `docs/specs/frontend-feature-inventory.spec.md`
- Backend API: `front-end/docs/API.md`
- Front-end routes: `front-end/poopyfeed/src/app/app.routes.ts`
- Pattern alerts spec: `docs/specs/pattern-alerts.spec.md`
- Notifications spec: `docs/specs/notifications.spec.md`
- Feeding reminders spec: `docs/specs/feeding-reminders.spec.md`
- Pediatrician summary spec: `docs/specs/pediatrician-summary.spec.md`
- Fuss Bus spec: `docs/specs/fuss-bus.spec.md`
- Plan: `.cursor/plans/Android front-end feature parity-e7521905.plan.md`
