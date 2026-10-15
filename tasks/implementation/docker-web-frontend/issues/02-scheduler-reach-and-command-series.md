# 02: Reach the host scheduler and document the command series

**What to build:** With the AI_NeSy backend running on the host, the containerized web app's scheduler calls reach it, so the Practitioner screens work from the browser. The digisaka README gives the ordered series of commands to run the whole demo: the backend commands (named by path to the AI_NeSy runbook, not copied) and the frontend compose commands.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] In compose, the scheduler proxy target is the host's scheduler on port 8001, and a request to the scheduler's lines route made through the web port reaches the running scheduler (a 401 without a token counts).
- [ ] The Supabase URL and anon key reach the client at run time from the gitignored local env file, and the QA sign-in screen uses them; no value is committed.
- [ ] If the host scheduler is not reachable from the container, the ticket stops and reports it for a user decision instead of changing the backend.
- [ ] The README lists the series in order: backend start (pointing at the AI_NeSy runbook), env files, seed, compose up, and the URL to open, plus how to stop and reset.
- [ ] The README states which pieces stay on the host and why, and that the Express login and the Supabase sign-in are separate.
- [ ] The known limits are written down: dev server only, no production image, backend not containerized.
