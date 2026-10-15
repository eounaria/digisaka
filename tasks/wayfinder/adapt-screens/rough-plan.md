# Rough plan: the original web screens on the scheduler API

Branch: `qa-web/adapt-screens`, based on `auth/supabase-only`. Local only; never merged or pushed.

## Goal

A Practitioner runs one line-week end to end in the team's original web app (the `AppLayout` shell and its Dashboard, Diagnosis History, Treatment Schedule, Notifications and Settings screens) against the real scheduler: sign in, scan leaves for a line-week, verify each leaf, close the week, read the proposal, approve or reject it, and record the application. The separate QA screens added earlier are removed. The backend contract is `AI_NeSy_Framework/docs/api/scheduler_openapi.json` and `docs/api/FRONTEND_INTEGRATION.md`; the web app adapts to it (ADR-0028 in that repo).

## What is removed

- The QA views and their shell: `QaHomeView`, `QaLineWeekView`, `QaCycleView`, `QaSignInView`, `SignInView`, `ShellLayout`.
- The `client/src/scheduler/` folder and its tests. Their logic is rewritten inside the original app's stores and `api.js`, with tests rewritten for the new home.
- The "QA Scheduler" entry in `AppLayout`'s menu.

Nothing in `legacy/` is used. `LegacyFrame` stays unrouted. Express stays as it is (admin API only).

## Where the logic lives

- `api.js`: the one fetch helper, with the Supabase bearer token, the scheduler's `{error, detail}` error shape, and the scheduler routes.
- `stores/auth.js`: Supabase email and password sign-in (password grant, plain `fetch`), the token in `sessionStorage`, roles read from the token, sign-out, and 401 handling. The admin console uses the same store.
- `stores/farm.js`: lines and line statuses, feeding Diagnosis History and Treatment Schedule.
- A new `stores/scan.js`: the scan flow (upload, symptom confirmation, re-scan, close week, cycle polling).
- ISO week and image helpers as small modules beside the stores.

Unit tests (Vitest) cover the stores and helpers with a fake `fetch`. No component tests.

## How the screens map

| Original screen | Adapted |
|---|---|
| `LoginView` | Supabase sign-in. Register is shown greyed out as not available yet. After sign-in a Practitioner lands in the app shell, a Technical User in `/admin`; someone with both roles gets the existing "Switch to Admin Web" link. |
| `AppLayout` | Kept with its sidebar, bottom tab bar, "New Scan" pill, bell and avatar. The use-case switcher is hidden for Practitioners; the app is fixed to Black Sigatoka. |
| Disease Detection (`/scan`) | A new Vue screen in the original app's style, following the mobile app's `leaf_scan` screens: Leaf Scan (pick a line and an ISO week where the Bulk ID was, add up to 8 leaves), Validation (each image uploaded in turn, with real progress), Assessment Result (one verification row per leaf: QA's symptom checklist with Yes and No, a re-scan prompt when QA asks), Treatment Recommendation (leaves grouped by QA's stage label), Treatment History (greyed out), then "Confirm & Schedule" closes the week and the screen polls the cycle until it ends. |
| `DashboardView` | Deferred. Stays unrouted. |
| `HistoryView` | Lines, each with its recent weeks, proposals and applications. Delete is greyed out. |
| `ScheduleListView` | Lines that have a proposal. |
| `BulkStagesView` | One line's proposals, one per week. |
| `TreatmentDetailView` | The proposal on the calendar: the treatment window and the next-assessment week. Approve or reject with a note; "Mark as done" on the treatment records the application date. A failed cycle can be retried; Human Review Required shows as the banner outcome with its reason. Dates come from the data. |
| `NotificationsView` | Deferred. Stays unrouted; the bell is hidden. |
| `SettingsView` | Deferred. Stays unrouted. Sign-out stays in the sidebar's Account group and shows the signed-in email. |

## Deferred

The Dashboard, Notifications and Settings screens are left for a later slice. They stay unrouted with their files untouched, the bell is hidden, and `/` redirects to `/scan`. Nothing in the exit gate depends on them.

## Features the backend does not support

Shown greyed out with a "not available yet" note, never faked: register, the stage override ("Move to…"), the treatment-history question, follow-up steps, the proof-of-treatment photo, the re-assessment outcome, bulk delete, push notifications (the bell is hidden rather than greyed out).

## Out of scope

The `legacy/` prototype, Express changes, the admin console's screens (only its sign-in source changes), the mobile app, deleting the old unmounted server routes, and response assessment after an application.

## Exit gate

Against the local stack (QA, scheduler, Claude proxy) with Docker running the web side: the test Practitioner runs `L04` `2026-W24` from scan to recorded application through the adapted screens only; a Technical User reaches the admin console and is kept out of the Practitioner screens' scheduler calls; the Vitest suite and the server tests pass; the build succeeds.
