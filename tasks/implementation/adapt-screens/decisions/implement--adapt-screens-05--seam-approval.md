# implement: adapt-screens ticket 05 (treatment detail: decide and record), seam approval

All questions minor or standard; recommendations followed.

1. Seam under test: a proposal store (load a line-week, approve, reject with and without a note, repeat decision, record the application, repeat record, malformed date, not-approved) with a stubbed `fetch`, plus the ISO-week-to-Monday helper. No component tests. Standard.
2. The proposal is found through the line status (the week's proposal and its cycle), then the full proposal and the cycle are read. A week with no proposal shows "couldn't be found". Standard.
3. Every day of the treatment window is a calendar event; the next-assessment week shows on its Monday. A rejected proposal greys the events and the banner reads Human Review Required with the cycle's reason. Minor.
4. After a repeat decision or repeat record, the screen reloads the real state and shows the scheduler's message. Standard.
5. Follow-up, proof photo and re-assessment outcome are visible, greyed and inert; the old proof and outcome sheets are removed. Minor.
6. "Today" is the real date (the old fixed demo day is gone). Minor.
