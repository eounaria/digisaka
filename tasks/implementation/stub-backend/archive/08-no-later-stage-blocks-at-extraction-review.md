# 08: Extraction review shows only what extraction produced

**Rank:** standard. Changes what the stub serves for facts at one workflow state; no client, store or real-service change.

**What to build:** Found in the live run: the first fact review ("waiting for extraction review") already showed ontology checks. In the pipeline those blocks come from stages after the review (canonicalizing, validating, correcting), so the stub must not serve them earlier. At `awaiting_extraction_review` a fact carries only the extracted triple, source excerpt, GraphJudge result and restoration status; its `gate3`, `mend`, `entity_resolution` and match and conflict warnings are empty. From `awaiting_final_approval` on they are served as before.

**Blocked by:** 05

**Status:** done

- [x] At extraction review no fact has an ontology check, correction, entity resolution or warning; the extraction fields are still there.
- [x] At final approval every one of those blocks still appears on some fact.
- [x] The stub unit tests and the client contract test assert both stages; the README's scenario text and the fact fixture's comment say when each block appears.
- [x] `node --test "stub/*.test.js"` and `npm --prefix client test` pass.
