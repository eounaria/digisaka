# Rough plan: stub backend for local web development

Branch: `qa-web/stub-backend`, based on `qa-web/km-integration`. Local only; never merged or pushed.

## Goal

A developer runs the web app with no host services: one command starts a stub that stands in for Supabase, the scheduler (:8001) and the Knowledge Maintenance API (:8000). Every screen can be driven, including failure and slow-workflow states the real backend cannot produce on demand. The default `docker compose up` still uses the real backend.

## Where it plugs in

- The Vite dev proxy already routes `/api/v1/scheduler` and `/api/v1/knowledge-maintenance` to `SCHEDULER_URL` and `KM_URL` (`client/vite.proxy.js`). Pointing both at the stub needs no change to stores, views or `api.js`.
- Sign-in is the one call that skips the proxy: `stores/auth.js` posts to `VITE_SUPABASE_URL`. That value is read by the browser, so it must be a host-reachable URL (`http://localhost:<stub port>`), not `host.docker.internal`.
- The Express `api` service verifies admin bearer tokens against Supabase (`server/supabaseAuth.js`). The stub also answers that verification call, so admin screens work on stub tokens.

## What the stub is

A standalone Node server with no new dependencies, started by a compose `stub` profile and a `.env.stub` that sets the three URLs. Switching back is a plain `docker compose up`. The proxy targets are read at Vite start, so switching needs `docker compose restart web`.

- **Supabase surface:** password grant (`/auth/v1/token`) returning a token whose `app_metadata.roles` and `email` claims match what the client decodes; the user-lookup call the Express verifier makes. Sample users: a practitioner, a Technical User, and one with both.
- **Scheduler surface:** lines, weeks, diagnoses (scan), history, cycle close, proposal, evidence, treatment decisions. Seeded in memory.
- **Knowledge Maintenance surface:** create (text and multipart), get, facts (paged, filter by disposition), claim, release, review, approve. Workflows advance state on a timer so polling is exercised; named scenarios give failed, slow, 409-on-approve and empty states.
- Error bodies use each service's real shape (scheduler flat `{error, detail}`, KM nested `{error:{code,message,details}}`).

## Source of the response shapes

The stub is standalone: it depends on nothing outside this repo. Its contract is what the web client already consumes, taken from the Pinia stores in `client/src/stores/` (every backend call goes through the shared `api.js`, except sign-in in `auth.js`), the helpers in `client/src/helpers/`, `api.js` error handling, and the payloads in the existing `*.test.js` fixtures. Fields the client ignores are filled with a plausible minimum.

## Tests and honesty

- Contract tests feed every stub response through the real client stores and helpers (with `fetch` pointed at the stub) and assert they parse and render state correctly. This proves stub and client agree; it cannot prove the stub matches the real services.
- Client unit tests keep their fake `fetch`; they never use the stub or the real backend.
- The acceptance gate stays a manual run against the real backend, and is the only guard against drift from the real services.

## Fog

- Response fields the client never reads, so the fixtures do not show them: the stub supplies a plausible minimum and records each guess in its README.

## Out of scope

Any change to client stores, views or `api.js`; the real backend; the mobile app; replacing the unit-test fakes with the stub.

## Exit gate

`docker compose --profile stub up` with no host services: sign in as each sample user, drive Scan, History, Schedule, Treatment and a full Knowledge Maintenance workflow to `completed`, and open the admin screens; client tests, server tests and the stub's contract tests pass.
