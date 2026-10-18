# 02: Scheduler read side: lines, history, evidence

**What to build:** The stub serves the scheduler's read endpoints from seed data, so Dashboard, Schedule and the line picker on Scan show content. Endpoints: `GET /lines`, `GET /lines/{id}` (status with `proposals`, `applications`, `latest_cycle`, `human_review_required`, `weeks_assessed`, `leaves_scanned`), `GET /lines/{id}/weeks/{week}/history` (the last three weekly `yls`, `yli`, `rainfall_mm`, with gaps for missing values) and `GET /cycles/{id}/evidence` (weeks, disease and rainfall blocks the evidence captions read, or `404 unknown_evidence`). Errors use `{error: code, detail}` with the codes in `helpers/messages.js` (`unknown_line`, `unknown_cycle`, `invalid_week`). Seed lines: L01 empty; L02 with an applied proposal; L03 with a proposal awaiting a decision; L04 ready to scan (the default demo line); L05 with a human-review outcome; L06 whose next cycle fails. "Today" is 2026-W24, matching the app. Every request needs a stub bearer token, else 401 `unauthenticated`; a Technical-User-only token is 403 `forbidden`.

**Blocked by:** 01

**Status:** not started

- [ ] Dashboard totals, recent proposals and the Schedule list show the seeded lines.
- [ ] Choosing a line and week on Scan shows three weeks of history, including a gap.
- [ ] A cycle with trend evidence draws the charts with captions; a cycle without it shows the "no evidence" state.
- [ ] An unknown line, an invalid week and a missing token give the real error shapes and the client's readable messages.
- [ ] Contract tests drive the lines, line-history and evidence stores against the stub.
- [ ] Stub unit tests cover the routes and seed consistency (every proposal's cycle exists).
