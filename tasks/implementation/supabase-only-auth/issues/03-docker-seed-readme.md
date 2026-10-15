# 03: Docker, seed and README for Supabase-only accounts

**What to build:** A developer follows the README with Docker running and the Supabase values in one env file, and both services start: the `api` service can verify tokens, the `web` service signs users in. The README says which accounts exist and where their credentials come from, without any credential in the repo, and the old demo logins are gone from it.

**Blocked by:** 02

**Status:** done, live sign-in exercise pending

- [x] One gitignored env file supplies the Supabase URL and anon key to both the `api` service and the client. No value is committed or baked into an image.
- [x] The compose stack starts from a fresh volume, seeds without accounts, and the `api` service answers 401 without a token and rejects a token Supabase does not recognise.
- [ ] (GAP: `client/.env.local` is absent in this checkout, so the stack has no Supabase URL and anon key; without them the api answers 401 for no token and 503 for any token. Needs the user to create the file and sign in.) A signed-in Technical User and a signed-in Practitioner are exercised against the running stack if their credentials are available in the local AI_NeSy env; if not, the gap is stated in the ticket rather than faked.
- [x] The README "Run it in Docker" section lists the two AI_NeSy accounts, names the AI_NeSy variables that hold their credentials (names only), says the Practitioner uses the QA Scheduler and the Technical User the admin console, and no longer mentions `juan` or `admin`.
- [x] The older non-Docker "Run it" section is marked as describing the retired Express shell so nobody follows it by mistake.
- [x] Known limits are written down, including that knowledge maintenance is not integrated with AI_NeSy and the farmer Users screen remains.
