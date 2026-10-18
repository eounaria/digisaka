# 08: Sign out and the way back to the app, on a narrow admin window

**Rank:** minor. Two shell components, client only; no store, API or route change.

**What to build:** On a window 900px wide or less the admin topbar hides its "Digisaka app" and "Sign out" buttons, so a narrow window has no way to sign out or return to the app (found in the live run, the same gap ticket 07 fixed in the farmer shell). The admin avatar becomes a button that opens a small menu with the signed-in email, "Digisaka app" (for someone who is also a Practitioner) and "Sign out". Both shells now share the menu's behaviour through one small composable, `components/useAccountMenu.js`, instead of two copies.

**Blocked by:** 07

**Status:** done

- [x] At 900px or less, pressing the admin avatar opens a menu with the email, "Digisaka app" (only for a Practitioner) and "Sign out"; Sign out clears the session and returns to the login; "Digisaka app" goes to the scan screen.
- [x] The menu closes on Escape (focus returns to the avatar), on a click outside it, on choosing an item, on navigating and when the window is resized across 900px.
- [x] Above 900px the topbar buttons work as before and the avatar is inert.
- [x] The farmer shell behaves as in ticket 07 after the composable extraction.
- [x] `npm --prefix client test` and the client build pass. The client has no component-test setup, so the menus are checked live.
