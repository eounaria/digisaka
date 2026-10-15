# 02: Line list and line-week upload

**What to build:** A signed-in Practitioner sees the list of lines (`L01` to `L14`) with each line's status, opens a line and a week, uploads a leaf image, and sees the QA result. When QA asks for the symptom confirmation, they answer yes or no; a denial that asks for a re-scan lets them upload again against the same session. The sessions so far for that line-week are listed.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] The line list shows all lines with status; choosing a line and an ISO week opens the line-week screen.
- [ ] Uploading an image creates a QA session bound to the line-week and shows its outcome, which is empty while waiting, then one of the documented outcomes, with its stage label.
- [ ] The symptom checklist is shown when the answer asks for it; the yes/no answer is submitted and the result updates. A `re_scan` next action offers a new upload that reuses the session.
- [ ] The sessions so far for the line-week are listed and refresh after each upload.
- [ ] Scheduler error codes show readable messages (for example an invalid week or a closed week) and never a raw payload.
- [ ] Unit tests cover the upload, confirmation, re-scan and session list logic with a fake client.
- [ ] Demoable against the local stack for `L04` in `2026-W24`.
