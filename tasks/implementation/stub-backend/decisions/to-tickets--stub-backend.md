# Decision record: to-tickets, stub backend

Developer audit only. Nothing else may link here.

## Preface

Input is the rough plan for a standalone stub of Supabase, the scheduler and the Knowledge Maintenance API. Rules in force: minor and standard questions follow the recommendation; destructive or breaking ones halt for the user. Facts checked by reading this repo: every backend call goes through `client/src/api.js` from the Pinia stores (sign-in in `auth.js` aside); `server/supabaseAuth.js` calls only `GET /auth/v1/user` and reads `email`, `app_metadata.roles` and `user_metadata`; `server/config.js` prefers `SUPABASE_URL` over `VITE_SUPABASE_URL`; the store test fixtures show the scheduler and Knowledge Maintenance shapes. CLAUDE.md names a `client/src/scheduler/` folder that does not exist; the logic is in `client/src/helpers/` (fixed on `qa-web/adapt-screens`).

## Decisions

1. Fog: which Supabase endpoints the Express verifier calls. Only `GET /auth/v1/user`; the stub also serves the password grant for the browser. Ranked minor. Self-decided from the code.
2. Fog: how scenarios are selected. Fixed named data decides (line id, document title keyword, image file name), plus `POST /__stub/reset`; the sign-in email only picks roles. Replaces the earlier lean towards email-selected scenarios, which cannot cover per-resource cases such as one failing line. Ranked standard. Self-decided.
3. One stub process on one port serving all three surfaces, rather than three servers. Ranked minor. Self-decided.
4. A compose override file (`docker-compose.stub.yml`) rather than a compose profile, because the `web` and `api` environments must change, which a profile cannot do. Ranked standard. Self-decided.
5. Browser, `web` container and `api` container reach the stub by different URLs (`localhost:9000`, `stub:9000`); the override sets each. Ranked minor. Self-decided.
6. Contract tests sit in `client/src/stub-contract/` and run under vitest, because the stores are the thing under test and the client already owns the vitest setup. Ranked minor. Self-decided.
7. Ticket granularity: six tickets. Scheduler is split read, scan and close, then proposal, since each is demoable on its own screen; Knowledge Maintenance is one ticket because its screens only make sense together. Ranked standard. Self-decided.
8. The Express admin API is not stubbed; it runs for real and accepts stub tokens. Ranked standard. Self-decided following the user's choice that the stub covers Supabase.
