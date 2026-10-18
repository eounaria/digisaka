# 03: Scan: group, confirm and schedule

**What to build:** After the leaves are verified, the Practitioner sees the treatment recommendation view: leaves grouped by the stage label QA gave, healthy and unvalidated ones listed separately, as in the mobile app. "Confirm & Schedule" closes the week and starts the cycle. The screen shows the cycle running (polling in place of the processing animation) and ends in one of three ways: a proposal is ready, with a button to open it; Human Review Required, with its reason shown as the outcome; or a failed cycle, with a retry. Closing a week where nothing is verified shows a clear explanation.

**Blocked by:** 02

**Status:** done, checked live

- [x] Verified leaves are grouped by QA's stage label; healthy and unvalidated leaves are listed apart.
- [x] Confirm & Schedule closes the week; a week already closed leads to the existing cycle; a week with no finished session explains why it cannot close.
- [x] The cycle is polled while running and stops when the screen is left.
- [x] A finished cycle with a proposal links to the treatment detail screen for that line and week; Human Review Required shows its reason; a failed cycle offers a retry.
- [x] Unit tests cover close, polling, the three endings and retry with a fake client.
