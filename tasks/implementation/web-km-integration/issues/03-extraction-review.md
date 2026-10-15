# 03: Extraction review: claim, approve and reject facts

**What to build:** When a workflow reaches extraction review, the KG Processing screen is replaced by a fact review screen for it. Facts are listed in document order, paged, with filters for disposition and for facts that still need action. Each fact shows its extracted triple, its source excerpt, the GraphJudge result and any restoration status. A Technical User claims a fact, approves or rejects it (the API takes no note), and releases it; a claim held by someone else is shown and does not block the call. A conflict from another reviewer's change shows the API's message and refreshes the fact. After the last fact is reviewed the workflow moves on by itself and the status screen follows it. Edit, rework and reinstate are visible but greyed out as not available yet.

**Blocked by:** 02

**Status:** in progress (stores done, screen not started)

- [ ] The list pages and filters correctly on a workflow with about a hundred facts.
- [ ] Approve and reject send the fact's current version; a stale version shows the API's message and reloads the fact.
- [ ] Claim and release work; another reviewer's claim and its expiry are shown.
- [ ] Reviewing the last required fact resumes the workflow without a further click.
- [ ] The greyed-out powers are visible and do nothing.
- [ ] Unit tests cover paging, filters, claim, review and conflict with a fake client.
