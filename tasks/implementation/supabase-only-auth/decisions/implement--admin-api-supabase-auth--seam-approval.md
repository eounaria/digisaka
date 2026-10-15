# Decision record: implement seam approval, Supabase-only accounts

Developer audit only. Nothing else may link here.

## Preface

Ticket 01 of slice 5 (branch `auth/supabase-only`). Rules in force: minor and standard questions follow the recommendation; only destructive or breaking decisions halt for the user. The user was not asked anything this round.

## Decisions

| # | Question | Rank | Decision |
|---|---|---|---|
| 1 | Which seams get tests? | standard | Two. (a) The token verifier, with a fake `fetch`: valid token, name fallback, legacy single role ignored, Supabase 401 or 403 mapped to 401, outage and missing settings mapped to 503. (b) The HTTP API through `createApp` with an injected fake verifier: 401 without a token, 403 for a Practitioner, access for a Technical User, first-request recording of the user, removed endpoints answering 404. |
| 2 | Role ids and the Technical User set? | standard | Copied from AI_NeSy's auth module: `administrator`, `domain_expert`, `plant_pathologist` (Technical User) and `practitioner`. Unknown role strings are dropped; the legacy single `role` string is not honoured, as in AI_NeSy. |
| 3 | Outage or missing Supabase settings? | standard | Fail closed with 503, never access. |
| 4 | Verifier written without a Supabase SDK? | minor | Yes: one GET to the project's user endpoint with the bearer token and the anon key. |
