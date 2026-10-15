# 01: Supabase sign-in and the original shell

**What to build:** A user opens the web app and sees the original login screen. They sign in with their Supabase email and password. A Practitioner lands in the original app shell on the scan screen; a Technical User lands in the admin console; someone with both roles can switch with the existing "Switch to Admin Web" link. The shell keeps its sidebar, bottom tab bar and topbar. The "QA Scheduler" entry is gone, the bell and use-case switcher are hidden, and sign-out sits in the sidebar with the signed-in email. Register is shown greyed out as not available yet. The admin console keeps working with the same token. The app can make scheduler calls with the token and understands the scheduler's error shape and a 401.

**Blocked by:** None (can start immediately)

**Status:** done, live browser check pending

- [x] The original login screen signs in against Supabase; a wrong password shows a readable message; there is no register form action.
- [x] After sign-in a Practitioner reaches the shell, a Technical User reaches the admin console, and a Practitioner who types the admin address is sent back to the shell.
- [x] The shell shows no QA Scheduler entry, no bell and no use-case switcher; sign-out works and shows the email.
- [x] A 401 from any call clears the session and returns to the login; scheduler error bodies show their detail text, never a raw payload.
- [x] The admin console loads its data with the same token as before. (Wired to the same token; not yet exercised in a browser.)
- [x] The root address redirects to the scan route (a placeholder until ticket 02).
- [x] Unit tests cover sign-in, role reading from the token, 401 handling and the error shape with a fake `fetch`.
- [x] The separate QA screens still exist in the tree but are not routed; nothing else imports their sign-in.
- [ ] Live check in a browser: sign in as a Practitioner and as a Technical User against the running stack.
