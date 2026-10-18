# Implementation tickets: Docker for the web frontend

Tracer-bullet tickets for running the digisaka web app in containers so the demo starts from a short series of commands. Local files under `issues/` (completed tickets move to `archive/`), numbered in dependency order, status in each ticket's own `**Status:**` line (same conventions as [web-qa-integration](../web-qa-integration/README.md)).

Branch: `docker/web-frontend`, based on `integration/qa-web`. Local only; never merged or pushed.

Source: [rough plan](../../wayfinder/docker-web-frontend/rough-plan.md).

## Dependency graph

| # | Ticket | Blocked by |
|---|---|---|
| 01 | Web app and API up in containers | none |
| 02 | Reach the host scheduler and document the command series | 01 |

Linear. The scheduler proxy and the documented series both build on the running containers.

## Not ticketed

Containerizing any AI_NeSy service, production images or a static front, CI, the Flutter app, and the live `L04` `2026-W24` run.
