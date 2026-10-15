# Rough plan: web QA screens on the scheduler API

Branch: `integration/qa-web` (staging plus the two web-app commits from `main`, cherry-picked). Local only; never merged or pushed.

## Goal

A Practitioner can run one line-week end to end from the web app against the real backend: sign in to Supabase, upload leaf images to a line-week, answer the symptom confirmation, watch the week fill up, close the week, wait for the cycle, read the proposal, approve or reject it, and record the application.

The backend contract is the committed scheduler spec and its guide (`AI_NeSy_Framework/docs/api/scheduler_openapi.json`, `docs/api/FRONTEND_INTEGRATION.md`). The web app adapts to it (ADR-0028 in that repo).

## How the demo screens map to the scheduler

| Demo app (`digisaka/`) | Scheduler |
|---|---|
| Bulk: one plant, a bulk code, many leaves | Line-week: a line (`L01` to `L14`) and an ISO week (`YYYY-Www`) |
| One scanned leaf | One upload, which is one QA session bound to the line-week |
| Leaf result: stage 0 to 4, healthy, unvalidated | The QA session's `outcome` (null while waiting, then `treatment_result`, `healthy`, `referral` or `not_leaf`) and its `stage` label |
| Per-leaf verify or move to another stage | Symptom confirmation (yes or no), with a re-scan when QA asks. No stage override (ADR-0028) |
| "Was treatment applied?" question | Not modelled. Treatment history comes from the weekly records |
| "Confirm & Schedule" | Closing the week |
| Processing animation | Polling the cycle while `status` is `running` |
| Treatment groups per stage, each with Treatment, Follow-up and Re-assessment steps | One proposal per cycle: treatment, window, reason, constraints, next assessment. A cycle may end in Human Review Required with no proposal |
| Step status Suggested, Confirmed, Applied | Proposal decision (approved or rejected), then the application date |
| Diagnosis History, the list of bulks | The list of lines with each line's status |

## Scope

1. New Vue screens beside the existing ones: a line list, a line-week screen (upload, confirmation, sessions so far, close, cycle status), and a cycle screen (proposal, decision, application).
2. A Supabase sign-in used only by these screens. The bearer token goes on every scheduler call.
3. A Vite dev proxy for `/api/v1/scheduler` to the scheduler on port 8001.
4. A small scheduler API module and helpers, unit-tested with Vitest.

## Out of scope

The legacy scan iframe, the Express stub and its cookie login, the existing bulk, schedule and history screens, the dashboard, notifications, the admin console, the mobile app, and response assessment after an application.

## Exit gate

Against the local stack (QA, scheduler, Claude proxy), the test Practitioner runs `L04` `2026-W24` from upload to recorded application in the browser, and the Vitest suite passes.
