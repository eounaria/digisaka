# Rough plan: Docker for the web frontend

Branch: `docker/web-frontend`, based on `integration/qa-web`. Local only; never merged or pushed.

## Goal

A developer with Docker Desktop brings up the digisaka web app (the shell and the QA screens) with a short, documented series of commands, then starts the AI_NeSy backend with its own documented commands, and the two talk to each other. No local Node install, no hand-edited proxy settings.

## Shape

- **Frontend only.** The QA API, the scheduler, the Claude proxy and the MLX embedder stay host processes, started from the AI_NeSy runbook (`scripts/scheduler_acceptance/RUNBOOK.md`). The proxy and the embedder need the host (Claude Code login, Apple silicon) and the QA API needs local CV checkpoints, so containerizing them is a different slice.
- **Two services in one compose file** at the digisaka app root:
  - `api`: the Express and SQLite server on port 3000. The shell login and the nav need it, and the QA routes sit behind that login.
  - `web`: the Vite dev server on port 5173, with hot reload. The `/api/v1/scheduler` proxy lives in Vite, and there is no CORS on the backend, so the dev server stays the front door.
- **Proxy targets come from the environment.** `vite.config.js` reads the scheduler and API targets from variables, defaulting to today's values (`http://127.0.0.1:8001`, `http://localhost:3000`) so running outside Docker is unchanged. In compose they point at `http://host.docker.internal:8001` and `http://api:3000`.
- **Config and secrets stay out of images.** The Supabase URL and anon key come from the gitignored `client/.env.local`; the Express `.env` likewise. Seeded SQLite data lives in a named volume.
- **Backend untouched.** On Docker Desktop for Mac, `host.docker.internal` is expected to reach services bound to the host's `127.0.0.1`. This is checked in the live step; if it fails, the fix would be a backend bind change, which would stop for a user decision.

## Out of scope

Containerizing any AI_NeSy service, production images or an nginx front, CI, the Flutter app, and the live `L04` `2026-W24` run itself (a separate step once this lands).

## Exit gate

From a clean checkout with Docker running and the two env files in place, the documented commands bring up `api` and `web`; `http://localhost:5173` loads the shell and the QA sign-in screen; and a request to `/api/v1/scheduler/lines` made through port 5173 reaches the running scheduler (a `401` without a token counts). The existing Vitest suite and `npm test` still pass.
