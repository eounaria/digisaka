# 03: Close week, cycle, proposal and application

**What to build:** The Practitioner closes a line-week, watches the cycle run, reads the proposal (treatment, window, reason, constraints, next assessment), approves or rejects it, and records the application date. A cycle that ends in Human Review Required shows that state with no proposal.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Closing the week asks for confirmation, then starts the cycle; a closed week can no longer take uploads.
- [ ] The cycle screen polls while the status is running, stops on a terminal status or when leaving the screen, and shows a clear timeout or failure state.
- [ ] A proposal shows treatment, window, reason, constraints and next assessment; approve and reject are submitted and reflected on the screen.
- [ ] After approval, the application date can be recorded and is shown afterwards.
- [ ] Human Review Required is shown as its own state with no proposal and no decision controls.
- [ ] Scheduler error codes show readable messages.
- [ ] Unit tests cover polling (including stop conditions), decision and application logic with a fake client and fake timers.
- [ ] The Vitest suite passes and the app builds. The exit gate in the rough plan is checked against the local stack, and any step that writes to the dev Supabase is left for the user.
