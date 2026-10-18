# Implementation tickets: Web QA integration prototype

Tracer-bullet tickets for the web side of the QA integration: a Practitioner runs one line-week against the real scheduler API from the demo web app. Local files under `issues/` (completed tickets move to `archive/`), numbered in dependency order, status in each ticket's own `**Status:**` line (same conventions as the AI_NeSy_Framework integration prototype tickets).

Branch: `integration/qa-web`, based on `staging` plus the two cherry-picked web commits. Local only; never merged or pushed.

Source: [rough plan](../../wayfinder/web-qa-integration/rough-plan.md).

## Dependency graph

| # | Ticket | Blocked by |
|---|---|---|
| 01 | Sign-in, scheduler client and proxy | none |
| 02 | Line list and line-week upload | 01 |
| 03 | Close week, cycle, proposal and application | 02 |

Linear. Each ticket is demoable against the local stack on its own.

## Not ticketed

The legacy scan iframe, the Express stub and its cookie login, existing bulk, schedule and history screens, notifications, admin console, mobile app, and response assessment after an application.

## Known gap

A scan waiting for its symptom confirmation lives only in the screen's memory (the sessions endpoint does not return the checklist). Reloading or changing week mid-confirmation leaves it listed as waiting; a new upload then starts a new session.
