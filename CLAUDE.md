# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

Two apps live here:

- `mobile/`: the Flutter app (package `digisaka`, Dart SDK `^3.13.4`).
- `digisaka/`: the web app, a Vue 3 client plus an Express/SQLite server. Its own `README.md`, `FLOW.md` and `API.md` are accurate for the farmer and admin sides; read them instead of re-deriving.

The root `README.md` is the unedited Flutter template. `flutter_analyze_baseline.txt` is a saved `flutter analyze` run whose paths predate the current `lib/` layout, so treat it as stale. `tasks/` holds the planning and ticket documents for the web QA integration.

## Branching and workflow

Feature branches are stacked: each is built on the branch below it, ending at the one it was created from.

- **Rebase in stack order.** After changing a branch, rebase each branch above it, lowest first, with `git rebase --onto <new base> <old base> <branch tip>`. Never rebase an upper branch straight onto the stack's base: that gives it its own copies of the lower branches' commits and breaks the stack.
- **No merge or push without a go signal.** Keep all changes local. Merge or push only when the human developer explicitly says to, for that specific action.
- **One slice per branch.** Don't mix slices. A change goes on the lowest branch that introduces it, then the branches above are rebased.
- **One commit per ticket.** Each ticket's implementation is its own commit.
- **Merge without squashing.** When branches are merged, use a merge or rebase that keeps the individual commits; never squash, so the history is preserved.
- **CLAUDE.md follows the code.** Update it in the same branch as the change it describes, so each branch's CLAUDE.md matches its own tree.

### Scope

Work only inside this repository (`mobile/`, `digisaka/`, `tasks/`). Do not read, search or edit sibling folders under `my-projects/` unless the human developer asks. The scheduler and Knowledge Maintenance services are reached over HTTP, not by reading their source.

### Decisions

When a decision comes up while planning or implementing, rank it as minor, standard, or potentially destructive or breaking. For minor and standard ones, follow the recommended option without asking. For destructive or breaking ones (for example, removing screens or endpoints, or changing what a screen does), stop and let the human developer decide.

Compose every question exactly as the round would normally ask it: the full question text and the full option list with descriptions, recommended option marked. Do this even for questions answered by following the recommendation, so the decision record can hold them verbatim.

### Context handoff

There is no exact context gauge, so estimate from tool output and file reads. Near the context limit, stop at the next clean checkpoint (a ticket boundary or a commit, never mid-edit). The `handoff` skill cannot be invoked by the model, so write the handoff by hand:

- Save it outside the session scratchpad, in a durable location the next session can read, and give the human developer its full path.
- Include the current branch, the ticket in progress, what is done and next, open decisions, and anything uncommitted.
- Include a suggested-skills section.
- Reference repo artifacts by path rather than pasting them.
- Redact secrets.
- Tell the human developer to continue in a new conversation.

### Task lifecycle

Planning lives under `tasks/`, which has two subfolders: `wayfinder/` (maps) and `implementation/` (tickets). Each task has a name, used as its folder name in both.

1. **Chart the map.** Start from a rough plan and run the `wayfinder` command. It charts a map in a new `tasks/wayfinder/<task-name>/` folder.
2. **Clear the fog.** If the map has fog, wayfinder defines tickets for it. Run `wayfinder` on those tickets one at a time, in order, until the fog has cleared or is at an acceptable level.
3. **Write the tickets.** Run the `to-tickets` command. It writes the implementation tickets into `tasks/implementation/<task-name>/`. Only write ticket files when asked.
4. **Implement each ticket.** Run the `implement` command on each ticket in turn. Each ticket is its own commit.
5. **Review before committing.** Before committing a ticket's implementation, make sure `code-review` has run on it: if the `implement` command already ran it, do not run it again; otherwise run the `code-review` command yourself. Commit only after the human developer decides the spec and standards issues are resolved to an acceptable state. Do not decide this yourself.
6. **Archive.** Move each completed ticket into `tasks/implementation/<task-name>/archive/`.

### Planning documents (`tasks/`)

```
tasks/wayfinder/<plan>/rough-plan.md
tasks/wayfinder/<plan>/decisions/grill-with-docs--<plan>.md
tasks/implementation/<plan>/README.md
tasks/implementation/<plan>/issues/NN-<ticket>.md
tasks/implementation/<plan>/archive/        (completed tickets)
tasks/implementation/<plan>/decisions/<command>--<plan>[--<ticket>]--<stage>.md
```

- Record every answered question, whether asked or self-decided, in a decision record: one file per stage. The filename names the command and the plan, and the file opens with a short preface giving the context.
- Each entry holds the exact question text, every option with its description, the rank, the recommended option, and the answer given or taken, marked "asked" or "self-decided". The reader should see what the grilling round would have shown.
- Decision records and `rough-plan.md` files are local and gitignored. They are for developer audit only. Tickets, READMEs and all other documents must never reference them; rewrite the decision into the relevant ticket instead.

## Commands: mobile

Run from `mobile/`.

```bash
flutter pub get
flutter run
flutter analyze                                   # lints: flutter_lints via analysis_options.yaml
flutter test                                      # all tests
flutter test test/widget_test.dart                # one file
flutter test --plain-name "<test name>"           # one test by name
```

`test/widget_test.dart` is the untouched Flutter counter template. It asserts a `+` button and a counter that this app doesn't have, so it fails until it is replaced.

The only dependencies are `image_picker` and `cupertino_icons`. There is no state-management package, no HTTP client and no router.

## Architecture

The app is currently a mock demo with no backend. `lib/core/data/seed_user.dart` holds a hard-coded `UserModel` with a plain-text password, and login checks against it.

Code is organised feature-first under `lib/features/<feature>/{data,domain,presentation}`. Shared code sits in `lib/shared/` (models, widgets, navigation). Theme and constants sit in `lib/core/`. Imports use `package:digisaka/...`.

### Navigation

`main.dart` starts at `LoginScreen`. After login, `MainShell` (`features/shell`) owns the single bottom nav bar and the four tab bodies: home, history, scan, profile. The bodies slide-animate when you switch tabs.

- The Scan tab runs its own nested `Navigator`, held in `_scanNavKey` inside `main_shell.dart`. Leaf scan, validation, result, treatment and schedule screens push onto that navigator, so the bottom nav stays visible. Tapping Scan while already on Scan pops back to the first route.
- `ShellScope` (`shared/navigation/shell_scope.dart`) is an `InheritedWidget` exposing `changeTab(int)`. Screens inside the nested Scan navigator use it to switch tabs, because their `Navigator.of(context)` can't reach the shell.

### State

State is in-memory only and is lost on restart.

- `ScheduleStore` (`features/smart_schedule/data/smart_schedule_store.dart`) is a singleton `ChangeNotifier` and the only shared store. It turns a bulk of `LeafAssessment`s into a `ScheduledBulk`: leaves are grouped by `LeafStage` (only stages where `isTreatment` is true), and each stage gets a treatment window and timeline steps. `registerBulk` is idempotent per `bulkId`. It calls `notifyListeners` in a microtask so a screen still building isn't rebuilt mid-build.
- The domain flow runs from `shared/models/leaf_assessment.dart` and `leaf_stage.dart`, through `leaf_scan/domain/bulk_helpers.dart`, to `smart_schedule/domain/models/smart_schedule_models.dart`. Read these together before changing stage or treatment logic.
- A `TODO` in the store notes that persistence to local storage or a backend is not yet built.

## Commands: web (`digisaka/`)

Needs Node >= 22. The README's "Run it in Docker" section is the supported way to run the stack; the `api` service is Express on :3000 and the `web` service is Vite on :5173.

```bash
docker compose up -d --build                     # api + web
docker compose run --rm api npm run seed         # first run only
docker compose restart api                       # after a server edit (client edits hot reload)
docker compose down -v                           # wipes db and dependency volumes; then `up --build` after a package.json change
npm test                                         # server tests (node --test "server/*.test.js")
node --test server/api.test.js                   # one server test file
npm --prefix client test                         # client tests (vitest)
npm --prefix client exec vitest run src/helpers/week.test.js   # one client test file
```

Without Docker: `npm install && npm run build`, `npm run seed`, `npm start` (:3000), plus `npm run dev` and `npm run dev:client` for hot reload.

## Architecture: web

### One sign-in, two backends

Sign-in is a single Supabase password grant, held by the Pinia store `client/src/stores/auth.js` (token in `sessionStorage`, roles decoded from the token for display and routing only). There are no Digisaka-only accounts and no Express cookie session: `npm run seed` creates sample farmers and demo knowledge only. It needs `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in `client/.env.local`, which compose also feeds to the `api` service.

- **Scheduler API** (`/api/v1/scheduler/*`): a separate service from the `AI_NeSy_Framework` repo, called with the bearer token. It runs on the host; the `web` container reaches it at `host.docker.internal:8001`. The Scan, History, Schedule and Treatment screens are built on it.
- **Express API** (`server/`): only `/api/health` and `/api/admin` are mounted. `server/adminAuth.js` verifies the bearer token with Supabase (`server/supabaseAuth.js`) and admits only Technical User roles (administrator, domain_expert, plant_pathologist), creating a local `users` row on first use. Everything else under `/api` returns 404.

- **Knowledge Maintenance API** (`/api/v1/knowledge-maintenance/*`): the AI_NeSy main API on port 8000. The admin Document Extractions screen submits documents to its workflows, follows them, and drives fact review and the final approve/commit (`stores/workflows.js`, `workflowRun.js`, `factReview.js`; `admin/WorkflowView.vue`). Tracing and Knowledge Graph are placeholders (`NotAvailableView`) until the service can list workflows and facts. The `api` Express role is now only datasets, ontology, audit, users and overview.

Dev proxy targets come from `client/vite.proxy.js` (`SCHEDULER_URL`, `KM_URL`, `API_URL`); changing one needs `docker compose restart web`, and a compose env change needs `up -d --build`. In `client/vite.config.js` the scheduler and knowledge-maintenance rules must stay ahead of the `/api` rule or they are swallowed by it.

### Client structure

- `client/src/router.js` has `/login`, the practitioner shell (`AppLayout`: dashboard, scan, history, schedule, treatment) and `/admin`. All redirects live in `client/src/routeGuard.js` (`redirectFor`), which is unit tested. A Technical User who is not also a practitioner lands on `/admin`.
- Screens are driven by Pinia stores that call the scheduler (`scan`, `cycle`, `lines`, `lineHistory`, `evidence`, `proposal`). `client/src/helpers/` holds the framework-free logic (`week.js`, `groups.js`, `evidence.js`, `messages.js`); the stores make their calls through the shared `client/src/api.js`. Tests sit next to the modules.
- The app treats 2026-W24 as "today" for the scan and calendar screens, per the commit history.
- `legacy/` and the Express routes for the old farmer app (`dashboard`, `bulks`, `schedules`, `notifications`, `me`) are unmounted dead code. Treat the README's "Run it (retired Express shell)" and farmer-side API tables as historical.
- Admin screens are under `client/src/admin/` and are scoped by a use case; every `/api/admin` call needs `?useCase=`. Extraction is no longer done in Express (`server/extract.js` and the triples/documents routes were removed); it happens in the Knowledge Maintenance service.

## Things that bite

- `mobile/test/widget_test.dart` is the Flutter counter template and fails until replaced. `flutter_analyze_baseline.txt` is stale.
- In `client/vite.config.js` the scheduler and knowledge-maintenance proxy rules must stay ahead of the `/api` rule. A proxy target change needs `docker compose restart web`; a compose env change needs `up -d --build`.
- Sign-in needs `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in `client/.env.local`. Without them nothing works.
- The scheduler runs on the host (`host.docker.internal:8001`), so the web container can't reach it if it isn't up.
- The app treats 2026-W24 as "today", so date-dependent screens look stale on the real calendar.
- `legacy/` and the old Express farmer routes are unmounted dead code. The README's farmer-side sections are historical.
- Every `/api/admin` call needs `?useCase=`.
- `ScheduleStore` state is in-memory only and lost on restart.
