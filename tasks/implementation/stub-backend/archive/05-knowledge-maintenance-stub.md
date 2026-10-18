# 05: Knowledge Maintenance workflows and fact review

**What to build:** The admin Document Extractions flow works against the stub. `POST /workflows` accepts JSON `{document: {title, content}}` or multipart `file` + `title` and returns `{workflow_id, workflow_type, state, created_at}`; `GET /workflows/{id}` returns `state`, `failure`, `retrying`, `retry_available`, `created_at`, `updated_at`, `completed_at`, `named_graph_uri`, `ontology_version_pinned`; an unknown id is 404 in the nested `{error: {code, message, details}}` shape. State advances on a timer through the states in `admin/workflowState.js` and stops at `awaiting_extraction_review` and `awaiting_final_approval`. The document title decides the path: a title containing `fail` ends in `failed` with a cause; `commit-fail` reaches `commit_failed` with `retry_available`, which approve retries to success; `slow` takes much longer in each state; anything else is the happy path. `GET /workflows/{id}/facts` pages with `disposition`, `limit`, `offset` and returns `{facts, total, limit, offset}`; facts carry `id`, `disposition`, `requires_action`, `lock_version`, `claimed_by`, `claimed_at`, `claim_expires_at`, `extracted_triple`, `source_excerpt`, `gate3`, `mend`, `entity_resolution`, and the match and conflict warning lists, with a mix that shows every block (about 30 facts, some unresolved). `POST .../facts/{fid}/claim`, `.../release` and `.../review` (`{lock_version, review_stage, decision}`) follow the client's behaviour, including a stale `lock_version` as 409 and a colleague's claim being taken over (`previous_holder`). `POST /workflows/{id}/approve` moves from final approval to committing to `completed`, and is 409 elsewhere.

**Blocked by:** 01

**Status:** done

- [ ] Submitting text and a file both create a workflow that appears in the list and can be opened by id.
- [ ] A happy-path workflow reaches extraction review, takes fact decisions (claim, accept, reject, a stale-version conflict), moves on, reaches final approval, and completes with counts per disposition.
- [ ] The `fail` and `commit-fail` titles show the failure state, and approve retries the commit.
- [ ] Every fact block (ontology check, correction, resolution, warnings) renders for some fact.
- [ ] Contract tests drive the workflows, workflow-run and fact-review stores against the stub, with a fast `wait`.
- [ ] Stub unit tests cover the state timer and the review rules.
