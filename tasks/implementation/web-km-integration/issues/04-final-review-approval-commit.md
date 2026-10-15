# 04: Final review, approval and commit

**What to build:** After phase 2 the same fact screen becomes the final review: it shows the Gate 3 result, the MEND before and after, the new-versus-matched entity status with the dedup match snapshots, and any warnings, and highlights facts that need action or changed in a staleness re-run. The Technical User reviews those facts as in extraction review, then gives final approval. The status screen then follows the commit: committing, then completed with the counts of accepted, rejected and unresolved facts and the run graph's identity, or `commit_failed` with a way to retry the approval. A workflow sent back by a staleness re-run returns to final review and says why.

**Blocked by:** 03

**Status:** built (not run live)

- [ ] Gate 3 violations, MEND diffs, entity status and dedup matches show for the facts that have them.
- [ ] Final approval is offered only when the API allows it, and the API's message shows when it refuses.
- [ ] Completed shows the disposition counts and the run graph identity from the API.
- [ ] `commit_failed` offers retrying the approval.
- [ ] A staleness re-run that changes facts returns the workflow to final review with those facts marked.
- [ ] Unit tests cover approval, commit failure and the re-run path with a fake client.
