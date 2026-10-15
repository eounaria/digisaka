# implement: adapt-screens ticket 02 (scan), seam approval

Context: scan screen for a line-week: add up to eight leaves, upload each in turn, confirm symptoms, re-scan. Questions ranked per the project rules; none were destructive or breaking, so recommendations were followed.

1. Seams under test: the scan store (upload sequence, confirm, re-scan, referral, failure and retry) with a stubbed `fetch` through the real `api.js`; the ISO week helper; the image helper. The farm store's line list is a one-line pass-through and is exercised by the browser check instead. Standard; followed recommendation.
2. No component tests for the view. Minor.
3. The retry cap of two is enforced by the backend: the client shows whatever outcome QA returns (a referral once capped) and keeps no local counter. Standard.
4. A leaf whose upload fails is marked failed and the rest continue; the next assess retries only failed or queued leaves. Minor.
5. Changing line or week clears the leaf list, because sessions belong to one line-week. Standard.
6. Helpers moved to `src/helpers/` (week, image, messages); the old `src/scheduler/` copies stay until ticket 06. Minor.
