# 01: Sign-in, scheduler client and proxy

**What to build:** A Practitioner opens the web app, signs in with their Supabase email and password, and the app can make an authenticated call to the scheduler API through the dev proxy. A minimal screen shows the signed-in state and the result of a call that proves the bearer token is accepted. This also sets up the project's unit test runner and the helpers the later screens need (ISO week handling, error mapping from the scheduler's error codes).

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The client project has a working unit test runner, and a single test command runs the suite.
- [x] Sign-in uses the Supabase password grant only; a wrong password shows a clear message, and the token is kept for the session and sent as a bearer token on every scheduler call. No Supabase writes occur.
- [x] Requests to the scheduler path are proxied in development to the scheduler on port 8001, ahead of the existing API proxy rule, which keeps working.
- [x] A scheduler client module wraps the calls used by the later tickets, maps error responses to the documented error codes, and is unit-tested with a fake fetch (no network).
- [x] An ISO week helper produces and validates `YYYY-Www` values (current week, previous and next week), with unit tests including year boundaries.
- [x] Signing out clears the token. An expired or rejected token returns the user to sign-in.
- [x] The existing screens are unaffected.
