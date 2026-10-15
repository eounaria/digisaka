# Decision record: implement, Knowledge Maintenance in the web app

Developer audit only. Nothing else may link here.

## Preface

Branch `qa-web/km-integration`, based on `qa-web/adapt-screens`. Tickets 01 and 02 built so far. Rules in force: minor and standard questions follow the recommendation; destructive or breaking ones halt for the user. Test seams were approved by recommendation: the store behind each screen, the API client's error shape and the dev proxy targets, all with a fake `fetch`; no component tests.

## Decisions

1. Ticket 01: the KM API nests its error as `{error: {code, message, details}}`, unlike the scheduler. The shared API client reads both shapes. Ranked minor. Self-decided.
2. Ticket 01: KM calls go to the main API on port 8000 through a new dev proxy target (`KM_URL`) and rule, ahead of the Express rule. Ranked minor. Self-decided.
3. Ticket 01: the remembered workflow list is keyed by the signed-in email in `localStorage`, not `sessionStorage`, so it survives a new tab. Ranked minor. Self-decided.
4. Ticket 02: the service has no retry or cancel route (only the commit retry through approve exists), and `failure` and `retrying` are always null. Retry and Cancel are shown greyed out as not available yet, matching the plan's rule of never faking unsupported features; the status screen renders `failure` and `retrying` if the API sends them. Ranked standard. Self-decided; ticket 02 was reworded to match. Follow-up for the backend: implement the two endpoints.
5. Ticket 02: polling every 15 seconds (the API's suggested range), pausing while the tab is hidden, stopping at the two review gates and at terminal or failed states. Ranked minor. Self-decided.
6. Ticket 03: the panel opens on "Needing review" (`pending`) and pages 25 at a time. The API filters only by disposition, so "facts that still need action" is the pending filter, not a separate one. Ranked minor. Self-decided; ticket wording kept as the screen's behaviour.
7. Ticket 03: Accept and Reject are enabled only for `pending` facts; Claim is disabled when the fact is already mine, Release unless it is mine. A colleague's claim is shown with its expiry and does not disable Claim or the decisions, since the API lets any reviewer take over. Ranked minor. Self-decided.
8. Ticket 03: after each accept or reject the panel calls `workflowRun.recheck`, so the page follows the workflow on its own after the last fact. Edit, Rework and Reinstate are shown greyed out. Ranked minor. Self-decided.
