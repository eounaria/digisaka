# 02: Workflow status: follow, retry and cancel

**What to build:** Opening a workflow shows its state in plain words, in order along the path from submitted to completed, and keeps itself up to date while the workflow is working (extraction, restoring, canonicalizing, validating, correcting, committing). It shows an automatic retry in progress and a failed workflow's cause when the API sends them. Retry and Cancel are shown greyed out as not available yet, because the service has no retry or cancel endpoint (commit retry goes through final approval, ticket 04). Polling pauses when the tab is hidden, stops at a review gate or a terminal state, and does not sign in again per call, so a run of tens of minutes does not hit the sign-in rate limit.

**Blocked by:** 01

**Status:** built (live check pending)

- [ ] The state shown matches the API's state at every poll, including `failed` with its cause and `commit_failed`.
- [ ] A retry in progress and a failure's cause are shown when the API sends them.
- [ ] Retry and Cancel are visible, greyed out and do nothing.
- [ ] Polling stops at the review gates and terminal states and resumes when the user returns.
- [ ] A long wait makes no extra sign-in calls.
- [ ] Unit tests cover polling, retry and cancel with a fake client and fake timers.
