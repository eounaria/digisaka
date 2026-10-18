# 03: Scan and close a week

**What to build:** Scanning and closing a week work end to end against the stub. `POST /lines/{line}/weeks/{week}/diagnoses` takes `{img_name, img, qa_output_id?}` and returns a canned answer chosen by the image name (`healthy`, `not_leaf`, `referral`, `stage2`, `rescan`, `unavailable`; anything else is `stage2`): either a final `outcome`, or a `symptom_checklist` awaiting confirmation, or `next_action: re_scan`; `unavailable` answers 503 `qa_unavailable`. `POST /diagnoses/{id}/confirm-symptoms` takes `{confirmed}` and finishes or asks for a re-scan. `POST /lines/{line}/weeks/{week}/close` returns 202 with a running cycle, or 409 `week_not_verified` until one scan on that line-week is verified. The cycle advances on a timer (running for a few seconds, then done with outcome `proposal`, `continue_monitoring` or `human_review_required`, or `failed`), decided by the line: L04 proposal, L01 monitoring, L05 human review, L06 fails and then succeeds on `POST /cycles/{id}/retry` (409 `cycle_not_failed` otherwise). `GET /cycles/{id}` reports status; only one running cycle per line (409 `cycle_slot_taken`). A finished proposal appears in the line's status.

**Blocked by:** 02

**Status:** done

- [ ] Uploading several images with different names reaches every outcome the Scan screen renders, including confirm, re-scan and the 503 with its retry.
- [ ] Closing L04 after a verified scan polls, then shows the proposal; L01 shows monitoring; L05 shows human review; L06 shows the failure, and Retry then succeeds.
- [ ] Closing before any verified scan shows the `week_not_verified` message.
- [ ] The week and line state survive until `POST /__stub/reset` and come back to the seed after it.
- [ ] Contract tests drive the scan and cycle stores (with a fast `wait`) against the stub.
- [ ] Stub unit tests cover the cycle timer with a fake clock.
