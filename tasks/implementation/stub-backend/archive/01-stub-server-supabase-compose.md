# 01: Stub server, Supabase sign-in and compose override

**What to build:** A stub server in `digisaka/stub/` that answers the Supabase calls and nothing else yet, started by a compose override. Signing in with a sample user works in the browser, and the admin console's Express API accepts the stub's tokens. Sample users: a practitioner, a Technical User (administrator) and one with both roles; any password for a sample user is accepted, an unknown email or the password `wrong` gives the same invalid-credentials answer as Supabase. `POST /auth/v1/token?grant_type=password` returns an access token whose payload carries `sub`, `email` and `app_metadata.roles` (the client only decodes it). `GET /auth/v1/user` returns the user for a known token and 401 otherwise, in the shape `server/supabaseAuth.js` reads. `GET /__stub/health` and `POST /__stub/reset` exist. `docker-compose.stub.yml` adds the `stub` service and sets the URLs described in the README. Unmatched paths return 404 in the scheduler's flat error shape.

**Blocked by:** none

**Status:** done

- [ ] `docker compose -f docker-compose.yml -f docker-compose.stub.yml up -d --build` starts `stub`, `api` and `web` with no host services running.
- [ ] Each sample user signs in through the real login page and lands where `routeGuard` sends them (practitioner shell, `/admin`, or the shell for the dual-role user).
- [ ] An admin screen that needs the Express API (Users or Audit) loads for the Technical User with a stub token and is refused for the practitioner.
- [ ] A wrong password or unknown email shows the wrong-credentials message; a missing or garbage token on `/auth/v1/user` gives 401.
- [ ] Plain `docker compose up` is unchanged and still points at the real services.
- [ ] A contract test signs in through the real auth store against the stub.
- [ ] Stub unit tests (`node --test "stub/*.test.js"`) cover token issue, `/auth/v1/user` and reset.
