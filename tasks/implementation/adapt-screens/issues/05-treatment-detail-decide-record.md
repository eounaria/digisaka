# 05: Treatment detail: decide and record the application

**What to build:** The treatment detail screen shows one proposal on the original calendar: the treatment window and the next-assessment week as events, with the proposal's treatment, reason and constraints. The Practitioner approves or rejects it with an optional note. After approval, "Mark as done" on the treatment asks for the date applied and records the application. Status and outcome banners follow the decision. A rejected proposal ends as Human Review Required with its reason. Dates come from the data, not fixed values. Follow-up steps, the proof-of-treatment photo and the re-assessment outcome are visible but greyed out as not available yet.

**Blocked by:** 03, 04

**Status:** ready-for-agent

- [ ] The calendar shows the window and next-assessment week from the proposal; no date is hardcoded.
- [ ] Approve and reject post the decision with the note; a repeat decision shows the scheduler's message.
- [ ] Mark as done is offered only after approval and records the chosen date; recording twice shows the scheduler's message.
- [ ] The banner reflects proposed, approved, rejected, applied and Human Review Required.
- [ ] The greyed-out items are visible and do nothing.
- [ ] Unit tests cover decision and application with a fake client.
