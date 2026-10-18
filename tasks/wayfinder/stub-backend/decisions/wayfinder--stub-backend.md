# Decision record: wayfinder, stub backend

Developer audit only. Nothing else may link here.

## Preface

The user asked for a seeder or stubs for the newly connected backend APIs and for a recommendation on which environments may use them. No `wayfinder` command was available in this session, so the map was written by hand in the same layout as earlier maps. Facts checked: the proxy targets in `client/vite.proxy.js`, the direct Supabase call in `stores/auth.js`, the compose file, and that client tests already use a fake `fetch`.

## Decisions

1. Which environments use the stub? Recommendation accepted: dev opt-in (real backend stays the default), automated tests never touch the real backend or the stub, acceptance gate real-only. Ranked standard. Asked; user agreed by continuing.
2. Standalone stub server or in-process `fetch` stubs? Standalone server, so no client code changes. Ranked standard. Asked; user agreed by continuing.
3. Does the stub cover Supabase, including token verification for the Express admin routes? Yes. Ranked standard. Asked. Answer: yes.
4. Branch `qa-web/stub-backend` stacked on `qa-web/km-integration`. Ranked minor. Self-decided.
5. The stub must not reference or depend on the backend framework repo. Its contract comes from the client code and test fixtures in this repo; contract tests run the stub through the real client stores. Ranked standard. Asked. Answer: standalone, no reference to that repo. This replaces the earlier plan to read the backend's API docs.
