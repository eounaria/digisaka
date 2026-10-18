# 02: One Supabase sign-in, role-based shell, admin console on the bearer token

**What to build:** A user opens the web app and sees one sign-in screen, the Supabase one. After signing in, a Practitioner lands in the QA Scheduler and a Technical User can also open the admin console. The admin console sends the same token to the admin API and keeps working. The old shell screens and the Express-cookie login are no longer reachable. A Practitioner who types an admin address is turned away.

**Blocked by:** 01

**Status:** done

- [x] The only sign-in screen is the Supabase one. Visiting any route while signed out goes to it and returns to the requested page afterwards.
- [x] A small shell shows the QA Scheduler link to every signed-in user and the admin console link only when the token's roles include a Technical User role, plus a single sign-out. Reading roles from the token is display logic and is unit-tested; the servers remain the enforcement.
- [x] A Practitioner opening an admin address is redirected away; a Technical User reaches the admin console.
- [x] The admin console's API calls carry the Supabase bearer token, and a 401 from the server sends the user back to the sign-in. The use-case list comes from the admin API and the active use case persists in the browser.
- [x] The old dashboard, scan, history, schedule, notifications and settings routes, the Express login screen and its auth store are unrouted; their files remain.
- [x] The existing QA screens and their tests still work unchanged in behavior.
- [x] The client unit suite passes, including new tests for role reading and the bearer header on the admin client; the production build succeeds.
