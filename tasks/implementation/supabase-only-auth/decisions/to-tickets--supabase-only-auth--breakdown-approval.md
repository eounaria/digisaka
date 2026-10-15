# Decision record: to-tickets breakdown approval, Supabase-only accounts

Developer audit only. Nothing else may link here.

## Preface

Source: the rough plan and grill-with-docs decisions for slice 5 (branch `auth/supabase-only`). No wayfinder map exists because the grilling found no fog. Rules in force: minor and standard questions follow the recommendation; only destructive or breaking decisions halt for the user. The user was not asked anything this round.

## Decisions

| # | Question | Rank | Decision |
|---|---|---|---|
| 1 | Is the granularity right? | standard | Three tickets: server first (verifier, removed endpoints, seed), then the client sign-in and shell, then Docker and README. Each is verifiable on its own and fits one context window. |
| 2 | Blocking edges? | standard | Linear: 01, 02, 03. The client switch needs the server to accept the token; Docker and README describe the finished behavior. |
| 3 | Split the endpoint removal from the new auth? | minor | No. Removing the cookie login and adding token auth must land together or the admin API is left open or unreachable. |
| 4 | Separate ticket for the seed? | minor | No. Folded into 01 because the seed stops creating accounts at the same time the login goes. |
| 5 | Prefactoring? | minor | The token check goes behind a replaceable verifier as part of 01. Nothing else. |
| 6 | Paths and code in tickets? | minor | Kept out, per the to-tickets guidance. |

## Halts

None.
