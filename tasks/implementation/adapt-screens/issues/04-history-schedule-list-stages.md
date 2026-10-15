# 04: History, schedule list and stages on line statuses

**What to build:** The Diagnosis History screen lists the lines, each with its recent weeks, proposals and recorded applications, drawn from the scheduler's line status. The Treatment Schedule list shows the lines that have a proposal. Opening a line shows its proposals, one per week, with status and treatment window, in place of the old stage groups. All three keep the original screens' look. Delete is greyed out. The stage groups, bulk codes and fixed August 2026 dates are gone.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] History shows every line with its recent weeks, proposals and applications; a line with no history shows an empty state, not an error.
- [ ] The schedule list shows only lines with a proposal; opening one shows its proposals by week with status and window.
- [ ] Choosing a proposal opens its treatment detail route.
- [ ] The delete action is visible, greyed out and does nothing.
- [ ] Loading and error states use the existing skeleton and message patterns.
- [ ] Unit tests cover the line-status store logic with a fake `fetch`.
