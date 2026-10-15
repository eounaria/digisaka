# 03: Docker, seed and README for Supabase-only accounts

**What to build:** A developer follows the README with Docker running and the Supabase values in one env file, and both services start: the `api` service can verify tokens, the `web` service signs users in. The README says which accounts exist and where their credentials come from, without any credential in the repo, and the old demo logins are gone from it.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] One gitignored env file supplies the Supabase URL and anon key to both the `api` service and the client. No value is committed or baked into an image.
- [ ] The compose stack starts from a fresh volume, seeds without accounts, and the `api` service answers 401 without a token and rejects a token Supabase does not recognise.
- [ ] A signed-in Technical User and a signed-in Practitioner are exercised against the running stack if their credentials are available in the local AI_NeSy env; if not, the gap is stated in the ticket rather than faked.
- [ ] The README "Run it in Docker" section lists the two AI_NeSy accounts, names the AI_NeSy variables that hold their credentials (names only), says the Practitioner uses the QA Scheduler and the Technical User the admin console, and no longer mentions `juan` or `admin`.
- [ ] The older non-Docker "Run it" section is marked as describing the retired Express shell so nobody follows it by mistake.
- [ ] Known limits are written down, including that knowledge maintenance is not integrated with AI_NeSy and the farmer Users screen remains.
