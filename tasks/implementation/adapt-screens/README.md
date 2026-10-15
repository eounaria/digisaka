# Implementation tickets: Adapt the original screens to the scheduler

Tracer-bullet tickets for adapting the team's original web screens (the `AppLayout` shell and its scan, history and schedule screens) to the scheduler API, replacing the separate QA screens. Local files under `issues/`, numbered in dependency order, status in each ticket's own `**Status:**` line.

Branch: `qa-web/adapt-screens`, based on `auth/supabase-only`. Local only; never merged or pushed.

Source: [rough plan](../../wayfinder/adapt-screens/rough-plan.md).

## Dependency graph

| # | Ticket | Blocked by |
|---|---|---|
| 01 | Supabase sign-in and the original shell | none |
| 02 | Scan: add leaves, upload and verify | 01 |
| 03 | Scan: group, confirm and schedule | 02 |
| 04 | History, schedule list and stages on line statuses | 02 |
| 05 | Treatment detail: decide and record the application | 03, 04 |
| 06 | Remove the separate QA screens and run the exit gate | 05 |

Tickets 03 and 04 can run in either order once 02 is done. Each ticket is demoable against the local stack on its own, except 06, which is the end-to-end run.

## Not ticketed

The Dashboard, Notifications and Settings screens (deferred to a later slice), the `legacy/` prototype, Express changes, the admin console's screens (only its sign-in source changes), the mobile app, and response assessment after an application.

## Known risk

The scan screen has no existing web design. It follows the mobile app's leaf-scan flow in the web app's styles; ticket 02 ends with the user looking at the screen before 03 builds on it.
