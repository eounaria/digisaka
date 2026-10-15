# Rough plan: Supabase-only accounts, Express reduced to knowledge maintenance

Branch: `auth/supabase-only`, based on `docker/web-frontend`. Local only; never merged or pushed.

## Goal

The only accounts anywhere in the web stack are the ones AI_NeSy already provides in Supabase: the Practitioner and the Technical User. One sign-in in the browser. The Practitioner uses the QA Scheduler; the Technical User uses the admin console, which is the demo's knowledge maintenance and is not integrated with AI_NeSy yet. The Express server keeps only that admin console. The `juan` and `admin` demo logins are gone.

## What changes

- **Express keeps:** the admin console API (documents, extractions, relationships, ontology, datasets and images, audit, tracing, knowledge graph, and the use-case list it needs).
- **Express drops (unmounted, code left in the repo):** login, register, logout and the session cookie; the dashboard, bulks, schedules, notifications and per-user preference endpoints; the legacy prototype's static route.
- **Express authenticates by Supabase token.** Each admin request carries the Supabase access token as a bearer. The server asks Supabase who the token belongs to (the same check AI_NeSy makes) and reads the roles from `app_metadata.roles`. Only a Technical User (Administrator, Domain Expert or Plant Pathologist) reaches the admin API; a Practitioner gets 403, no token gets 401.
- **Audit and reviewer identity.** On a Technical User's first request the server records them as a row in its `users` table (email, name), so uploaded-by, reviewer and audit-actor columns and the reviewer name join keep working. These rows have no usable password and are never used to sign in.
- **Seed** no longer creates `juan` or `admin`. The sample farmers stay as data rows for the admin Users screen.
- **Browser:** one Supabase sign-in screen. After it, a small shell offers the QA Scheduler to everyone and the admin console to Technical Users, based on the roles in the token (display only; the servers enforce). The admin console sends the same bearer token. The old shell, its screens and the Express auth store are unrouted and left in place.
- **Docker and README:** the `api` service needs the Supabase URL and anon key to check tokens; one env file feeds both services. The README logins section lists the AI_NeSy accounts and where their credentials live (variable names only).

## Out of scope

Deleting the old screens or server code, integrating knowledge maintenance with AI_NeSy, the farmer Users screen (kept as admin data for now), role administration, production builds, and the live `L04` `2026-W24` run.

## Exit gate

From a clean Docker start with the Supabase env in place: a Practitioner signs in once, opens the QA Scheduler, and is refused (403) by the admin API; a Technical User signs in once and loads the admin console data; no seeded demo login works; the removed endpoints answer 404. Server tests and the client Vitest suite pass.
