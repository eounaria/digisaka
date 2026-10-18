# 07: Sample leaves for the Scan screen on the stub

**Rank:** standard. Adds flag-gated code to a shared client view (`ScanView.vue`) but changes no store, API contract or real-backend behaviour; the flag is unset outside the stub compose file.

**What to build:** When the web app runs on the stub, the Scan screen fills its queue with sample leaf images itself, so nobody has to pick files by hand. The stub chooses its canned answer from the image file name, so the samples are named after its scenarios.

- A flag `VITE_STUB_SAMPLES: "1"` on the `web` service in `docker-compose.stub.yml`. The base compose file never sets it, so with the flag off the Scan screen renders and behaves as before (the sample helper is still bundled, but never runs).
- `client/src/helpers/stubSamples.js`: builds in-memory `File` objects from one tiny embedded base64 PNG (no files under `public/`, no fetch). Each is named `<scenario>-leaf-NN.png` for a stub scenario (`stage2`, `healthy`, `referral`, `not_leaf`, `rescan`, `unavailable`); the name carries the token the stub matches on. Exposes the default set (two stage 2 leaves and one healthy leaf) and a lookup by scenario.
- `ScanView.vue`, only when the flag is on: when the queue is empty for the selected line-week (including after Start over), add the default set once; show a "Sample leaves" row with one button per scenario that adds that sample (respecting `MAX_LEAVES`); in the rescan step, offer a "Use sample" action that passes a sample to `scan.rescan`.
- README "Run it on the stub" and CLAUDE.md say the flag exists, what it does, and that it only changes the client on the stub (the manual run against the real backend stays the acceptance gate). Update the stub-backend README's "Not ticketed" line, which currently rules out client view changes.

**Blocked by:** 03

**Status:** done

- [ ] On the stub stack, opening Scan for a line with no queue shows the default samples without any file being picked, and Assess runs them to the confirm and done states.
- [ ] Each scenario button adds a leaf that produces that scenario's outcome from the stub (`healthy`, `not_leaf`, `referral`, `rescan`, `unavailable`).
- [ ] Rescan can be completed with the sample action alone.
- [ ] Changing line or week refills the sample set; a non-empty queue is never overwritten.
- [ ] Without the flag (plain `docker compose up`, production build) the Scan screen is unchanged: no samples, no extra buttons.
- [ ] Unit test for `stubSamples.js` (names map to the scenarios the stub recognises, payload non-empty); a scan store or view test for auto-fill on and off; a stub contract test that posts each sample name and checks the outcome.
- [ ] `npm --prefix client test`, `npm test` and the stub unit tests pass.
