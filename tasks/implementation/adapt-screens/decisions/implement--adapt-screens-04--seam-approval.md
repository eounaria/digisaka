# implement: adapt-screens ticket 04 (history, schedule list, line proposals), seam approval

All questions minor or standard; recommendations followed.

1. Seam under test: the lines store (loading every line status, schedule-list filtering, an empty line, one failing line, a failing list) and the proposal-row helper, with a stubbed `fetch`. No component tests. Standard.
2. The old bulk-stages view file was renamed to `ScheduleLineView.vue` since it now lists a line's proposals. Minor.
3. A proposal shows its option id nowhere on the lists: the scheduler's line status does not carry the treatment name, so the lists show week, status and window; the name appears on the detail screen (ticket 05). Minor.
4. A line whose status fails to load shows its own error and does not hide the other lines. Standard.
5. Delete on the history cards is a disabled button with no action. Minor.
