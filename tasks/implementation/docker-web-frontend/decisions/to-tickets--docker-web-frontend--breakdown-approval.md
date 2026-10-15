# Decision record: to-tickets breakdown approval, Docker for the web frontend

Developer audit only. Nothing else may link here.

## Preface

Source: the rough plan and grill-with-docs decisions for slice 4 (branch `docker/web-frontend`). No wayfinder map exists because the grilling found no fog. Rules in force: minor and standard questions follow the recommendation; only destructive or breaking decisions halt for the user. The user was not asked anything this round.

## Decisions

| # | Question | Rank | Decision |
|---|---|---|---|
| 1 | Is the granularity right? | standard | Two tickets: containers up with the shell working, then the scheduler reach plus the documented series. Each is verifiable alone and fits one context window. |
| 2 | Blocking edges? | standard | Linear: 01, then 02. The proxy check and the README both need the running containers. |
| 3 | Split env-driven proxy targets into their own ticket? | minor | No. Folded into 01 so the first ticket is a working tracer through both services. |
| 4 | Separate documentation ticket? | minor | No. The README series is the demo of ticket 02, so it ships with it. |
| 5 | Prefactoring? | minor | None. |
| 6 | Paths and code in tickets? | minor | Kept out, per the to-tickets guidance. |
| 7 | What if the host scheduler is unreachable from the container? | standard | Ticket 02 stops and reports; any backend bind change is breaking and goes to the user. |
| 8 | Location and numbering? | minor | `tasks/implementation/docker-web-frontend/issues/NN-<slug>.md`, README with dependency table. |

## Halts

None.
