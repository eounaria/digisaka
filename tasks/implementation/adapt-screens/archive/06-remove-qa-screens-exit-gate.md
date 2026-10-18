# 06: Remove the separate QA screens and run the exit gate

**What to build:** The separate QA screens, their sign-in views and shell, and the old scheduler modules are deleted, leaving the adapted original screens as the only scheduler UI. The Practitioner then runs line `L04` in week `2026-W24` from scan to a recorded application through the adapted screens, and a Technical User reaches the admin console.

**Blocked by:** 05

**Status:** done, checked live

- [ ] The QA views, both sign-in views, the QA shell and the old scheduler folder with its tests are removed; the build and the full Vitest suite pass; nothing imports the removed files.
- [ ] The server tests pass in the container.
- [ ] Against the local stack, a Practitioner completes scan, close, decision and application for `L04` in `2026-W24` using only the adapted screens.
- [ ] A Technical User reaches the admin console; a Practitioner sent to the admin address returns to the shell.
- [ ] The README logins and run instructions match the new screens.
