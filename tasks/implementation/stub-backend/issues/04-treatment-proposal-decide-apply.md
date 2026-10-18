# 04: Treatment proposal: decide and apply

**What to build:** The Treatment detail screen works against the stub. `GET /cycles/{id}/proposal` returns the proposal (`proposal_id`, `treatment {id, name}`, `window {start, end}`, `reason`, `constraints`, `next_assessment`, and `decision {decision, note?}` once decided); `POST /proposals/{id}/decision` takes `{decision, note?}` with `approved` or `rejected`; `POST /proposals/{id}/application` takes `{applied_on}` and records it (409 `proposal_not_approved` before approval, `application_already_recorded` on a repeat); a second decision is 409 `proposal_already_decided`. Decisions and applications show up in the line status (`proposals[].status`, `applications`). A proposal on a human-review cycle has constraints that explain why.

**Blocked by:** 03

**Status:** not started

- [ ] From the seed, L03's proposal can be approved or rejected with a note, and L02's shows as applied.
- [ ] An approved proposal accepts an application date and shows as applied on the calendar and in the Schedule list.
- [ ] Each of the three 409 codes shows its readable message, and the screen reloads the real state.
- [ ] Contract tests drive the proposal store, including the 409 recovery path.
- [ ] Stub unit tests cover the decision and application state machine.
