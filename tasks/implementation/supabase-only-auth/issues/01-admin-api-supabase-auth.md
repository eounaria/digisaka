# 01: Admin API trusts Supabase Technical Users

**What to build:** The Express server's admin API accepts a Supabase access token as a bearer and lets in only a Technical User (Administrator, Domain Expert or Plant Pathologist). Every other endpoint of the old shell is gone: no login, register or logout, no dashboard, bulks, schedules, notifications or per-user preferences, and no legacy prototype route. The demo `juan` and `admin` accounts are no longer created. An admin action still records who did it.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] A request with no token gets 401; a token for a user with only the Practitioner role gets 403; a token with a Technical User role reaches the admin API. The token check goes through a replaceable verifier so tests use a fake one and never call Supabase.
- [ ] The real verifier asks the Supabase project who the token belongs to, reads the roles from the user's `app_metadata.roles` list, and treats an unreachable Supabase or a missing role as a refusal, never as access.
- [ ] A Technical User's first request records them in the users table (email, name from the Supabase profile, no usable password). Uploaded-by, reviewer and audit-actor fields and the reviewer name shown in the relationship lists keep working for them.
- [ ] The auth, dashboard, bulks, schedules, notifications and per-user preference endpoints and the legacy static route answer 404. Their source files remain in the repo.
- [ ] The admin API serves the list of use cases that the console used to read from the per-user endpoint.
- [ ] The seed creates no demo logins, still creates the sample farmers and the demo knowledge, and runs without a reviewer.
- [ ] The existing admin tests are updated to authenticate with the fake verifier and still pass; new tests cover the 401, 403, 200, first-request recording and removed endpoints.
- [ ] Server tests pass in the `api` container (Docker CLI at `/Applications/Docker.app/Contents/Resources/bin`).
