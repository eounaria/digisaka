# Decision record: grill-with-docs, adapting the original web screens

Developer audit only. Nothing else may link here.

## Preface

Slice 3 added separate QA screens beside the team's original web app instead of adapting it. The user wanted the original screens adapted and was never asked: slice 3's decision 2 ("replace the existing scan, history and schedule screens, or add new ones?") was ranked standard and self-decided, when it changed the shape of the whole frontend and should have been ranked breaking. Slice 5 then unrouted the original shell. This slice corrects that: the user asked to scrap the new UI and adapt the previous screens. Rules in force: minor and standard questions follow the recommendation; destructive or breaking ones halt for the user. After the slice 3 mistake, anything that changes what a screen does is ranked breaking.

Facts checked: slice 5 unmounted every Express endpoint the original screens call (auth, dashboard, bulks, me, schedules, notifications, `/legacy`); the original web scan screen was only ever the legacy iframe (`/scan` to `LegacyFrame`), and no Vue scan view exists on any local branch or on `origin/main` or `origin/staging`; the mobile app's `leaf_scan` feature has the same flow as the legacy stepper (leaf scan, validation, assessment result with per-leaf verify, recommendation grouped by stage, treatment history, schedule confirmed); the scheduler gives one proposal per cycle, no follow-up step, no re-assessment outcome, no notifications and no stage override (ADR-0028); a Technical User without the `practitioner` role gets 403 from every scheduler route; the use-case list is on the admin API, which refuses Practitioners.

## Decisions

| # | Question | Rank | Decision |
|---|---|---|---|
| 0 | Correction to slice 3 decision 2 | breaking (asked, this slice) | Wrongly ranked standard. The user wants the original screens adapted; the parallel QA screens are scrapped. |
| 1 | What "scrap the new UI" removes | destructive (asked) | The QA views, both sign-in views and `ShellLayout`, and also the `client/src/scheduler/` modules and tests. The logic is rewritten inside the original stores and `api.js`, with tests rewritten there. |
| 2 | Branch base | breaking (asked) | `qa-web/adapt-screens` off `auth/supabase-only`, keeping slice 4's Docker and slice 5's Supabase-only accounts. The uncommitted slice 3 confirm fix is stashed, not committed; the live `L04` run on the QA screens is stopped. |
| 3 | The scan flow | breaking (asked) | A Vue screen, not the legacy iframe; nothing in `legacy/` is used. |
| 3b | Source for the scan screen | standard | The mobile `leaf_scan` screens, which match the legacy stepper step for step, built with the original web app's styles and components. |
| 4 | Old features the backend does not support | breaking (asked) | Shown greyed out as not available yet. Anything the backend's data does support is shown, relabelled where needed. |
| 4b | Features gone by design (stage override, treatment-history question) | breaking (asked) | Also greyed out, against the recommendation to drop them. |
| 5 | Practitioner and Technical User in one app | breaking (asked) | Practitioners land in `AppLayout`, Technical Users in `/admin`, both roles get "Switch to Admin Web". The use-case switcher is hidden for Practitioners; Black Sigatoka is fixed. |
| 6 | Login | standard | `LoginView` becomes the Supabase sign-in; register greyed out. |
| 7 | Where the scheduler calls live | standard | In `api.js`, with the scheduler's `{error, detail}` error shape read as the message. |
| 8 | Store layout | standard | `auth` holds the Supabase session and roles (also used by the admin console); `farm` holds lines and line statuses; the `notifications` store is not touched; a new `scan` store holds the scan flow; ISO week and image helpers are small modules. |
| 9 | Dashboard, Notifications, Settings | breaking (asked) | Deferred to a later slice to cut cost (about 5 tickets instead of 6 to 8). They stay unrouted and untouched; the bell is hidden; `/` redirects to `/scan`; sign-out stays in the sidebar's Account group with the email. Supersedes the earlier derived-counts, derived-notifications and settings decisions (12, 13), which are void. |
| 10 | History, schedule list, stages per bulk | standard | History lists lines with weeks, proposals and applications; schedule list lists lines with a proposal; the stages screen lists one line's proposals by week. |
| 11 | Treatment detail | standard | Calendar shows the treatment window and the next-assessment week; approve or reject with a note; "Mark as done" records the application date; retry for a failed cycle; Human Review Required as the banner outcome; no hardcoded dates. |
| 12 | (void) | | Superseded by 9. |
| 13 | (void) | | Superseded by 9. |
| 14 | Bulk ID on the scan screen | standard | Replaced by a line picker and an ISO week (default current week). |
| 15 | Stage display | standard | QA's stage label is shown as given and used for grouping; no 1 to 4 mapping on the client. |
| 16 | Leaves per scan | minor | Up to 8, as in the mobile app; uploads one at a time because each waits for inference. |
| 17 | Tests | standard | Vitest unit tests for the stores and helpers with a fake `fetch`; no component tests. |
| 18 | Express and `legacy/` | standard | Unchanged; `legacy/` and `LegacyFrame` stay unrouted. |
| 19 | Wayfinder map | standard | None. The mapping settles every open question and fits one branch. Go to to-tickets. |
| 20 | Glossary or ADR | minor | None. The terms follow AI_NeSy's glossary; the choice is easy to reverse. |

## Halts

The deferral of the Dashboard, Notifications and Settings was put to the user after a cost estimate (9). Questions 1, 2, 3, 3b (as a follow-up), 4, 4b and 5 were put to the user. Question 1: the user chose the rewrite over keeping the modules. Question 4b: the user chose greying out over dropping. Question 3b: no Vue scan screen existed, and the mobile screens were confirmed as the same flow as the legacy one, so the source was settled as standard.
