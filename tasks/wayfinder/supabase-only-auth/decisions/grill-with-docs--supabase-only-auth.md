# Decision record: grill-with-docs, Supabase-only accounts

Developer audit only. Nothing else may link here.

## Preface

Slice 5 removes the web app's own accounts. After slice 4 the demo needed two sign-ins: the Express cookie login (`juan`, `admin`, SQLite) for the shell, then the Supabase Practitioner login for the QA screens. The user's goal is to have only the accounts AI_NeSy already provides (Practitioner and Technical User in Supabase), and to leave Express with only knowledge maintenance, since that is not integrated yet. The user ruled out dropping Express entirely and asked to drop all QA and auth endpoints from it. Rules in force: minor and standard questions follow the recommendation; only destructive or breaking decisions halt for the user. Two questions were put to the user earlier in this slice's discussion.

Facts checked: the QA screens call the scheduler through the Vite proxy and no Express route touches QA; the Express routers are auth, dashboard, bulks, me, schedules, notifications and admin; admin routes use `req.user.id` for uploaded-by, reviewer and audit-actor foreign keys to `users`, and one query joins `users` for the reviewer name; the admin console loads its use-case list and active use case from `/api/me`; AI_NeSy verifies tokens with a Supabase `get_user` round trip and reads `app_metadata["roles"]`; the Technical User roles are Administrator, Domain Expert and Plant Pathologist.

## Decisions

| # | Question | Rank | Decision |
|---|---|---|---|
| 1 | Branch base for this slice? | breaking (asked) | New local branch `auth/supabase-only` off `docker/web-frontend`. Not merged, not pushed. |
| 2 | Delete the non-QA screens and server code, or unroute them? | destructive (asked) | Unroute and keep the code. Screens, `server/` files, `legacy/` and the mobile app stay in the repo. |
| 3 | What does "drop QA and auth endpoints" cover in Express? | standard | Unmount the auth, dashboard, bulks, me, schedules and notifications routers and the `/legacy` static route. Their files stay. Only the admin API remains. |
| 4 | How is the admin API protected once the Express login is gone? | standard | Never open. The server verifies the Supabase bearer token by asking Supabase who it belongs to and reads `app_metadata.roles`, the same way AI_NeSy does. Technical User roles only; no token is 401, a Practitioner is 403. |
| 5 | How does Express reach Supabase? | minor | A plain HTTPS call to the project's user endpoint with the anon key; no SDK. The URL and anon key come from `SUPABASE_URL` and `SUPABASE_ANON_KEY`, falling back to the `VITE_` names so one env file serves both services. |
| 6 | Who is the actor in audit and reviewer columns? | standard | On first request, the Technical User gets a row in the `users` table (email, name, no usable password) and `req.user` carries that row. Foreign keys and the reviewer join stay unchanged. Rows are keyed by email. |
| 7 | Role mapping to the old 'admin' check? | standard | Any of the three Technical User roles passes the admin check. The `users.role` column is not used for access any more. |
| 8 | Where does the admin console get its use-case list and active use case? | standard | The list moves to the admin API. The active choice is kept in the browser (local storage), since there is no per-user server preference. |
| 9 | Seed? | standard | No `juan` or `admin`. Sample farmers stay as data rows. Demo documents seed with no reviewer. |
| 10 | The admin Users screen (farmer master list)? | standard | Kept for now: it is admin data, not a login, and rows have no usable password. Flagged as a follow-up since farmers are not AI_NeSy accounts. |
| 11 | One sign-in for the browser? | standard | Yes: the Supabase screen is the only login. The roles shown in the token pick which links appear; servers enforce. |
| 12 | Where does the browser keep the token for the admin API? | minor | In the same session storage entry the QA screens already use; the admin API client adds it as a bearer header. |
| 13 | New glossary terms or an ADR? | minor | None. It follows ADR-0028 in AI_NeSy and the glossary's Practitioner and Technical User. |
| 14 | Wayfinder map? | standard | None. Go to to-tickets. |

## Halts

Decisions 1 and 2 were put to the user, who chose the new branch and unroute-and-keep. No other halt.
