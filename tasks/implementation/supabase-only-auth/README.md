# Implementation tickets: Supabase-only accounts

Tracer-bullet tickets for removing the web app's own accounts so the only logins are the AI_NeSy Supabase accounts, with Express reduced to the admin console (knowledge maintenance). Local files under `issues/` (completed tickets move to `archive/`), numbered in dependency order, status in each ticket's own `**Status:**` line (same conventions as [docker-web-frontend](../docker-web-frontend/README.md)).

Branch: `auth/supabase-only`, based on `docker/web-frontend`. Local only; never merged or pushed.

Source: [rough plan](../../wayfinder/supabase-only-auth/rough-plan.md).

## Dependency graph

| # | Ticket | Blocked by |
|---|---|---|
| 01 | Admin API trusts Supabase Technical Users; auth and QA-era endpoints removed | none |
| 02 | One Supabase sign-in, role-based shell, admin console on the bearer token | 01 |
| 03 | Docker, seed and README for Supabase-only accounts | 02 |

Linear. The client can only switch once the server accepts the token, and the Docker and README changes describe the finished behavior.

## Not ticketed

Deleting the old screens or server code, integrating knowledge maintenance with AI_NeSy, the farmer Users screen, role administration, and the live `L04` `2026-W24` run.
