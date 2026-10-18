# Implementation tickets: stub backend for local web development

Tracer-bullet tickets for a standalone stub that stands in for Supabase, the scheduler and the Knowledge Maintenance API, so the web app runs with no host services. Local files under `issues/` (completed tickets move to `archive/`), numbered in dependency order, status in each ticket's own `**Status:**` line.

Branch: `qa-web/stub-backend`, based on `qa-web/km-integration`. Local only; never merged or pushed.

Source: [rough plan](../../wayfinder/stub-backend/rough-plan.md).

## Shape of the stub

- Code in `digisaka/stub/`: one Node server, no new dependencies, one port (9000), routing by path: `/auth/v1/*` (Supabase), `/api/v1/scheduler/*`, `/api/v1/knowledge-maintenance/*`. It depends on nothing outside this repo.
- Started by `docker-compose.stub.yml`, an override file that adds a `stub` service and repoints `web` and `api`:
  `docker compose -f docker-compose.yml -f docker-compose.stub.yml up -d --build`. Plain `docker compose up` keeps using the real backend.
- Three URLs differ by who reads them: the browser needs `VITE_SUPABASE_URL=http://localhost:9000`; the `web` container proxies scheduler and Knowledge Maintenance to `http://stub:9000`; the `api` container verifies tokens against `SUPABASE_URL=http://stub:9000` (`server/config.js` already prefers `SUPABASE_URL` over the `VITE_` one). Vite lets process env beat `client/.env.local`, so no file edit is needed.
- Scenarios are fixed named data, not switches: the line, the document title or the sign-in user decides what happens. `POST /__stub/reset` restores the seed.
- Contract tests live in `client/src/stub-contract/` and run with the rest of vitest: they start the stub in-process and drive the real Pinia stores against it.

## Dependency graph

| # | Ticket | Blocked by |
|---|---|---|
| 01 | Stub server, Supabase sign-in and compose override | none |
| 02 | Scheduler read side: lines, history, evidence | 01 |
| 03 | Scan and close a week | 02 |
| 04 | Treatment proposal: decide and apply | 03 |
| 05 | Knowledge Maintenance workflows and fact review | 01 |
| 06 | Documentation and exit gate | 04, 05 |

Each ticket is demoable against the stub stack on its own, except 06.

## Not ticketed

Stubbing the Express admin API (it keeps running for real and only needs to accept stub tokens); a stub for the Scan image model beyond canned outcomes; load or latency realism beyond a timer; any change to client stores, views or `api.js`; the mobile app.

## Known risks

- The stub's shapes come from the client code and test fixtures, so a field the client never reads is a guess. Only the manual run against the real backend catches drift.
- Admin pages need `/auth/v1/user` to answer exactly as `server/supabaseAuth.js` expects (`email`, `app_metadata.roles`).
