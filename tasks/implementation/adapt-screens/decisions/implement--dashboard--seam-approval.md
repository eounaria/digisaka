# implement: dashboard restored on the scheduler, seam approval

Developer audit record. Context: the original Dashboard was deferred in adapt-screens (grilling question 9) and left unrouted, because its data came from the Express `/api/dashboard` and `/api/bulks`, which are unmounted. The user asked to bring it back as the landing page, with "bulks assessed" as a line-week total and a derivation for "leaves scanned". All questions minor or standard; recommendations followed. The deferral itself was the user's call and is now reversed by the user.

1. The dashboard is the landing page: `/` shows it, `/` is also where sign-in lands a Practitioner, and the menu has a Dashboard entry. The user chose replace. Asked, not self-decided.
2. Counters come from the scheduler line status, not Express. Two additive fields were added to `GET /lines/{id}` (AI_NeSy_Framework `1ccf0d1`): `weeks_assessed` (distinct weeks with a finished cycle) and `leaves_scanned` (uploaded leaf sessions in those weeks). A week counts once closed, so leaves in an unclosed week are not counted; the page says counts cover closed weeks. Standard.
3. The third counter is proposals awaiting a decision (was "Need Treatment"). Human-review lines appear as a note. Minor.
4. "Recent assessments" became the five newest proposals across lines, each opening its treatment screen. Minor.
5. The greeting uses the email's first name part; the clock and the admin use-case lookup (refused to Practitioners) are dropped; the workspace text is fixed to banana / Black Sigatoka. Minor.
6. Seam tested: the pure `dashboardSummary` (totals, awaiting count, human-review count, five newest, a failed line counted as zero) and the route guard landing. The view itself is not unit-tested. Standard.
