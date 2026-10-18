# Implementation tickets: Knowledge Maintenance in the web app

Tracer-bullet tickets for replacing the admin console's Express-backed Document Extractions and KG Processing screens with screens on the Knowledge Maintenance API (`/api/v1/knowledge-maintenance`, main API on port 8000). Local files under `issues/` (completed tickets move to `archive/`), numbered in dependency order, status in each ticket's own `**Status:**` line.

Branch: `qa-web/km-integration`, based on `qa-web/adapt-screens`. Local only; never merged or pushed.

Source: [rough plan](../../wayfinder/web-km-integration/rough-plan.md).

## Dependency graph

| # | Ticket | Blocked by |
|---|---|---|
| 01 | Submit a document and keep a list of my workflows | none |
| 02 | Workflow status: follow, retry and cancel | 01 |
| 03 | Extraction review: claim, approve and reject facts | 02 |
| 04 | Final review, approval and commit | 03 |
| 05 | Remove the old screens and run the acceptance gate | 04 |

Each ticket is demoable against the local stack on its own, except 05, which is the end-to-end run.

## Not ticketed

Tracing, Knowledge Graph, Ontologies, Overview, Datasets, Audit and Users screens; Practitioner screens; the mobile app; reversal and remediation workflows; real GPU provisioning; any backend change (including a workflow-list endpoint).

## Known risks

- The API has no endpoint that lists workflows. The screens remember the workflows submitted from this browser and can open any workflow by its id; a list endpoint would be a later backend ticket.
- Phase 1 on the Paviso document takes tens of minutes, so tickets 02 and 05 must tolerate long waits without re-signing in per call.
