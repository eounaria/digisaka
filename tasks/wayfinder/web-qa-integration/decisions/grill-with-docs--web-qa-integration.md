# Decision record: grill-with-docs, web QA integration

Developer audit only. Nothing else may link here.

## Preface

Slice 3 connects the digisaka web app's QA side to the scheduler API built in slices 1 and 2. The web app (`digisaka/`: Vue 3 with Vite, an Express and SQLite stub, a legacy prototype in an iframe) was only on `origin/main`, while `integration/qa-web` was cut from `origin/staging`, which holds only the Flutter app. The user chose to keep the staging base and cherry-pick the two web commits (`f9fb1cd`, `ae9d37b`); the two sides touch disjoint paths and the cherry-pick was clean. This round maps the demo's screens to line-weeks, cycles and proposals. Rules in force: minor and standard questions follow the recommendation; only destructive or breaking decisions halt for the user. The branch-base question was put to the user (ranked breaking, since it departed from the "based on staging" rule); nothing else was asked.

Facts checked: the scan flow is simulated (`legacy/js/core.js`: `addMockLeaf` ignores the file, results come from `MOCK_LEAF_SEQUENCE`, fixed dates); a bulk is one plant with a code, a date and leaves graded 0 to 4 (`server/schema.sql`, `server/routes/bulks.js`); the schedule has three steps per stage group, all fixed to August 2026 (`TreatmentDetailView.vue`, `core.js`); there is no line or week anywhere in the app; auth is an Express JWT cookie with SQLite users (`client/src/stores/auth.js`); the client has no test runner; Vite proxies `/api` to the Express server on 3000. On the backend, QA's upload answer carries `outcome` (null while waiting), `stage`, `disease` and `symptom_checklist`, and a denied confirmation can answer `next_action: "re_scan"`. ADR-0028 already settles that clients adapt to the backend, use Supabase bearer tokens, call only the scheduler API for scheduled work, and drop the stage override.

## Decisions

| # | Question | Rank | Decision |
|---|---|---|---|
| 1 | Branch base for the web work? | breaking (asked) | Staging plus the two web commits from `main`, cherry-picked. No merge, nothing pushed. |
| 2 | Replace the existing scan, history and schedule screens, or add new ones? | standard | Add new screens and nav entries. The existing screens, the legacy iframe and the Express stub stay untouched, so nothing of the team's demo is removed. |
| 3 | What is a bulk in scheduler terms? | standard | A line-week. The demo's plant and bulk code have no scheduler counterpart; the user picks a line and a week instead. |
| 4 | What is a leaf? | standard | One upload, which is one QA session bound to the line-week. |
| 5 | Per-leaf verification and moving a leaf to another stage? | standard | Replaced by QA's symptom confirmation and re-scan. No stage override, per ADR-0028. |
| 6 | The "was treatment applied" question before scheduling? | minor | Dropped. The scheduler reads history from the weekly records. |
| 7 | "Confirm & Schedule"? | standard | Closing the week. The cycle's status replaces the processing animation. |
| 8 | Stage groups with Treatment, Follow-up and Re-assessment steps? | standard | One proposal per cycle, shown with its treatment, window, reason, constraints and next assessment. Human Review Required is shown when the cycle ends without a proposal. Follow-up steps are not invented on the client. |
| 9 | Step statuses (Suggested, Confirmed, Applied)? | standard | The proposal's decision (approve or reject, with a note) and then the application date. |
| 10 | Diagnosis History? | minor | A line list from the lines route, with each line's status. |
| 11 | Dashboard and notifications? | minor | Out of scope for the prototype. |
| 12 | Screens and routes? | standard | `/lines` (line list), `/lines/:lineId/weeks/:week` (upload, confirmation, sessions so far, close, cycle status), `/cycles/:cycleId` (proposal, decision, application). One nav entry, "Line-week scheduling". |
| 13 | How does the browser get a token? | standard | A Supabase email and password sign-in shown by the new screens when no token is held, using the password grant with raw `fetch` (no new SDK). The Supabase URL and anon key come from `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in a gitignored `client/.env.local`; the anon key is public by design. The token lives in `sessionStorage`; a 401 clears it and shows the sign-in again. The Express login for the shell is unchanged. |
| 14 | Reach the scheduler without CORS? | standard | Vite proxy entry `/api/v1/scheduler` to `http://127.0.0.1:8001`, listed before the existing `/api` entry so it wins. |
| 15 | Image capture? | minor | One file input per upload (`accept="image/*"`, `capture="environment"` for phones), read as base64; `img_name` is the file name. |
| 16 | Re-scan? | standard | When QA answers `next_action: "re_scan"`, the screen asks for another image and uploads it with the same `qa_output_id`. A referral or the retry cap ends the session as QA reports it. |
| 17 | Week choice? | minor | Defaults to the current ISO week, editable; the screen hints that the stub data has history for `L03` and `L04` in `2026-W24`. |
| 18 | Polling? | minor | Every 2 seconds while `running`; stops on leaving the screen. Both 202 and 200 from closing lead to the cycle screen. |
| 19 | Errors? | minor | Show the `detail` of the `{error, detail}` body; 401 goes to sign-in; 409 `week_not_verified` explains that no session has finished. |
| 20 | Tests in a client with no runner? | standard | Add Vitest as a dev dependency and unit-test the plain modules (scheduler API client with a fake `fetch`, ISO week helper, QA answer interpretation, the poller). No component tests. |
| 21 | ADR-0028 says clients generate types from the spec. The client is plain JavaScript. | minor | No types to generate; the API module follows the guide's routes, and its tests pin paths and bodies. |
| 22 | Where do planning docs and tickets live? | standard | `tasks/` at the digisaka repo root on `integration/qa-web`, so this slice stays on its own branch. |
| 23 | Wayfinder map? | standard | None. The mapping above settles every open question, and the work fits one branch. Go to to-tickets. |
| 24 | New glossary terms or an ADR? | minor | None. "Bulk" is already an avoided word for Line-week, and adding screens beside the demo is easy to reverse. |

## Halts

Decision 1 was put to the user, who chose the cherry-pick. No other halt.
