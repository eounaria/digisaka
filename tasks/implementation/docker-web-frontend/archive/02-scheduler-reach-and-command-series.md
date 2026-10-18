# 02: Reach the host scheduler and document the command series

**What to build:** With the AI_NeSy backend running on the host, the containerized web app's scheduler calls reach it, so the Practitioner screens work from the browser. The digisaka README gives the ordered series of commands to run the whole demo: the backend commands (named by path to the AI_NeSy runbook, not copied) and the frontend compose commands.

**Blocked by:** 01

**Status:** done

- [x] In compose, the scheduler proxy target is the host's scheduler on port 8001, and a request to the scheduler's lines route made through the web port reaches the running scheduler (a 401 without a token counts). Checked against a throwaway stub on the host's `127.0.0.1:8001`, not the real scheduler, because starting it applies migrations to the dev Supabase project; the stub's 401 came back through port 5173, and the proxy answered 502 once the stub stopped.
- [x] The Supabase URL and anon key reach the client at run time from the gitignored local env file, and the QA sign-in screen uses them; no value is committed.
- [x] If the host scheduler is not reachable from the container, the ticket stops and reports it for a user decision instead of changing the backend.
- [x] The README lists the series in order: backend start (pointing at the AI_NeSy runbook), env files, seed, compose up, and the URL to open, plus how to stop and reset.
- [x] The README states which pieces stay on the host and why, and that the Express login and the Supabase sign-in are separate.
- [x] The known limits are written down: dev server only, no production image, backend not containerized.

Verified 2026-10-16: host loopback is reachable from the web container, so no backend change was needed. The Supabase values were checked with dummy values in `client/.env.local` (removed afterwards): the served client module carried them. The real scheduler and the Supabase login were not run; that is the live step. Found along the way: with the scheduler down the screens show the generic error message, because the client maps only JSON error bodies; the README says so.
