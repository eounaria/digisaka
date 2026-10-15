# implement: adapt-screens ticket 03 (group, confirm, schedule), seam approval

Context: after the scan results, Confirm & Schedule closes the week and follows the cycle. All questions were minor or standard; recommendations followed.

1. Seams under test: the cycle store (close, polling, the endings, retry, stop, timeout, poll-failure tolerance) with a stubbed `fetch` and an injected wait; the stage grouping helper. No component tests. Standard.
2. The grouping lives in the scan results step (step 3 of the flow), since the mobile app shows the groups before scheduling. Minor.
3. "Unvalidated" means QA returned not-a-leaf or referral. Minor.
4. The proposal link points to `/treatment/{line}/{week}`, which ticket 05 creates; until then it redirects home. Minor.
5. Closing an already-closed week returns the existing cycle (backend behaviour), so the same path serves it. Minor.
