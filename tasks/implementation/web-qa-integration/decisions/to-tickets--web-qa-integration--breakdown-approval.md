# Decision record: to-tickets breakdown approval, web QA integration prototype

Developer audit only. Nothing else may link here.

## Preface

Source: the rough plan and grill-with-docs decisions for slice 3 (branch `integration/qa-web`). No wayfinder map exists because the grilling found no fog. Rules in force: minor and standard questions follow the recommendation; only destructive or breaking decisions halt for the user. The user was not asked anything this round.

## Decisions

| # | Question | Rank | Decision |
|---|---|---|---|
| 1 | Is the granularity right? | standard | Three tickets along the user journey: sign-in and client, upload and confirmation, close and proposal. Each is demoable alone and fits one context window. |
| 2 | Blocking edges? | standard | Linear: 01, then 02, then 03. Each screen needs the previous one's client, session and week state. |
| 3 | Separate ticket for the test runner and proxy? | minor | No. Folded into 01 so the first ticket is a working tracer through sign-in, proxy and one call. |
| 4 | Prefactoring? | minor | None beyond the test runner in 01. |
| 5 | Paths and code in tickets? | minor | Kept out, per the to-tickets guidance. |
| 6 | Location and numbering? | minor | `tasks/implementation/web-qa-integration/issues/NN-<slug>.md`, README with dependency table. |

## Halts

None.
