# 07: Sign out on a narrow window

**Rank:** minor. One shell component, client only; no store, API or route change.

**What to build:** On a window 900px wide or less the sidebar becomes a bottom tab bar and its Account block (email and Sign out) is hidden, so a narrow window or phone has no way to sign out (found in the live run; ticket 01 only placed sign-out in the sidebar). The topbar avatar becomes a button that opens a small account menu with the signed-in email and a Sign out action. The sidebar block is unchanged on wide windows, where the menu never shows.

**Blocked by:** 01

**Status:** done

- [x] At 900px or less, pressing the avatar opens a menu with the email and "Sign out"; Sign out clears the session and returns to the login.
- [x] The menu closes on Escape, on a click outside it, on choosing Sign out and on navigating to another screen.
- [x] The avatar is a labelled button (`aria-label`, `aria-expanded`); the menu stays inside the window at phone width.
- [x] Above 900px the sidebar Sign out works as before and no menu appears.
- [x] `npm --prefix client test` and the client build pass. The client has no component-test setup, so the menu itself is checked live.
