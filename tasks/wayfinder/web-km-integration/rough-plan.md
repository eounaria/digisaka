# Rough plan: Knowledge Maintenance in the web app, on the real KM API

Branch: `qa-web/km-integration`, based on `qa-web/adapt-screens`. Local only; never merged or pushed.

## Goal

A Technical User runs one document through the Knowledge Maintenance Workflow from the existing admin console against the real backend: sign in, submit a text or PDF document, watch GPU phase 1, review each extracted fact (approve or reject), watch phase 2, give final approval, and see the commit complete. The backend contract is `docs/api/NESY_API_PLAN.md` (`/api/v1/knowledge-maintenance/...`), served by the main API on port 8000. The web app adapts to it, as it did to the scheduler.

## What exists

- Backend, built and served: create, get, retry, cancel, facts list, fact review, claim, release, approve (`src/ai_nesy/apps/api/routes/knowledge_maintenance*.py`). Reversal endpoints are specified, not in this slice.
- Web admin console (`client/src/admin/`), today on the Express stub (`/api/admin/*`): Document Extractions, KG Processing, Tracing, Knowledge Graph, Ontologies, Datasets, Overview, Audit, Users.
- Auth already uses the Supabase bearer token (`stores/auth.js`), so the same token goes on KM calls. Roles come from the token; KM needs the Technical User role.

## How the admin screens map

| Admin screen (today) | On the KM API |
|---|---|
| Document Extractions (list, upload, extract) | Workflow list and create. Upload modal posts text (JSON) or PDF (multipart). Rows show workflow state, failure, retry and cancel. |
| KG Processing (review triples, edit, confirm pending) | Fact review for one workflow: `GET facts` (paged, document order), claim, approve or reject with a note, release. Edit and "confirm pending" are removed; the skeleton has no edit power. Final approval is the `approve` call. |
| Tracing | Deferred: no audit-log read endpoint exists (decision 0012). |
| Knowledge Graph, Ontologies | Out of this slice; they stay on their current source. |
| Overview, Datasets, Audit, Users | Untouched. |

## Where the logic lives

- `api.js`: add the KM base path and the `{error, detail}` mapping (already shared).
- New `stores/workflows.js` (list, create, poll, retry, cancel) and `stores/review.js` (facts page, claim, review with `lock_version`, release, approve). Polling stops on any terminal or review-gate state, with a cap like the cycle poll.
- Vitest with a fake `fetch`, same as the scheduler stores. No component tests.

## Features the backend does not support

Shown greyed out with a "not available yet" note: edit-and-accept, scoped rework, reinstating a rejected fact, ontology-picker edits, reversal, audit view, AI fact summary.

## Out of scope

Practitioner screens, the mobile app, reversal and remediation workflows, real GPU provisioning, and changes to the backend.

## Decisions

- The KM screens replace the Express-backed Extractions and Processing screens outright. The Express stub stays only for the screens not touched.
- The test Technical User exists in Supabase with the role the KM API checks.
- Acceptance documents come from the backend's end-to-end acceptance run (`AI_NeSy_Framework/tasks/implementation/knowledge-maintenance/issues/36-end-to-end-acceptance-run.md`): the Plantix `yellow_and_black_sigatoka` record is committed first as the dedup seed, then the Paviso terminal report (about 13.6K characters, 7 chunks) is the acceptance document, then the FAO stage excerpt runs as a separate workflow. All are submitted as text entries from `data/docs/bls_sample.jsonl` and `fao_manual.jsonl`; PDF upload is built but not part of the gate.
- The branch is based on `qa-web/adapt-screens`.

## Design notes from the live runs

- The Paviso run has about 100 facts and phase 1 takes tens of minutes, so the fact list must page, filter by disposition and `requires_action`, and the workflow screen must poll patiently with a visible state.
- Reviewing is one call per fact, so the review UI keeps the signed-in token and never re-logs-in per call (the backend's test client hit 429s doing that).
- Unresolved facts and Gate 3 violations are common; show the gate 3, MEND and dedup blocks of `FactResponse` rather than hiding them.

## Exit gate

Against the local stack (main API on 8000, local vLLM, Fuseki, Supabase), the test Technical User takes the seed, then the Paviso document, from upload to `completed` in the browser, the accepted facts show in Fuseki under the run graph, and the Vitest suite and build pass.
