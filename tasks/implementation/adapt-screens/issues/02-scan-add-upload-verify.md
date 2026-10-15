# 02: Scan: add leaves, upload and verify

**What to build:** A Practitioner opens Disease Detection, picks a line and an ISO week (default the current week), and adds up to eight leaf images from camera or gallery. They start the assessment. Each image is uploaded to the line-week in turn with visible progress, and QA's answer for each leaf is shown: healthy, not a leaf, referral, or a stage with a symptom checklist. For a leaf that needs confirmation they answer Yes or No; a denial that asks for a re-scan lets them retake that one leaf against the same session. A leaf QA refers or caps out is shown as such. The screen follows the mobile app's leaf-scan, validation and assessment-result flow, built with the web app's own styles and components. Anything the backend does not support (the stage override, the treatment-history question) appears greyed out as not available yet.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] The line list loads from the scheduler and the line and week can be chosen; an invalid week shows a readable message.
- [ ] Up to eight images can be added, removed or cleared; a ninth is refused with a message.
- [ ] Assessing uploads each image once, in order, with per-leaf progress, and shows QA's outcome and stage label as given.
- [ ] The symptom checklist is shown when asked for; Yes and No are submitted and the leaf's result updates; a re-scan request offers a new image for that leaf and reuses its session.
- [ ] The greyed-out stage override and treatment-history items are visible and do nothing.
- [ ] Unit tests cover the scan store (upload sequence, confirmation, re-scan, referral and retry cap) with a fake `fetch`, plus the ISO week and image helpers.
- [ ] The user has seen the screen running and approved its layout before ticket 03 starts.
