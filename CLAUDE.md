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

### Decisions

When a decision comes up while planning or implementing, rank it as minor, standard, or potentially destructive or breaking. For minor and standard ones, follow the recommended option without asking. For destructive or breaking ones (for example, removing screens or endpoints, or changing what a screen does), stop and let the human developer decide.

### Task lifecycle

Planning lives under `tasks/`, which has two subfolders: `wayfinder/` (maps) and `implementation/` (tickets). Each task has a name, used as its folder name in both.

1. **Chart the map.** Start from a rough plan and run the `wayfinder` command. It charts a map in a new `tasks/wayfinder/<task-name>/` folder.
2. **Clear the fog.** If the map has fog, wayfinder defines tickets for it. Run `wayfinder` on those tickets one at a time, in order, until the fog has cleared or is at an acceptable level.
3. **Write the tickets.** Run the `to-tickets` command. It writes the implementation tickets into `tasks/implementation/<task-name>/`.
4. **Implement each ticket.** Run the `implement` command on each ticket in turn. Each ticket is its own commit.
5. **Review before committing.** Before committing a ticket's implementation, run the `code-review` command. Commit only after the human developer decides the spec and standards issues are resolved to an acceptable state. Do not decide this yourself.
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
- Decision records are for developer audit only. Tickets, READMEs and all other documents must never reference them; rewrite the decision into the relevant ticket instead.

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
npm --prefix client exec vitest run src/scheduler/week.test.js   # one client test file
```

Without Docker: `npm install && npm run build`, `npm run seed`, `npm start` (:3000), plus `npm run dev` and `npm run dev:client` for hot reload.

## Architecture: web

### Two separate backends and auth systems

- **Express API** (`server/`, `/api/*`): the farmer app and admin console. Auth is a JWT cookie session. Routes are in `server/routes/`.
- **Scheduler API** (`/api/v1/scheduler/*`): the QA screens (`/qa/*` routes, `Qa*View.vue`) talk to a separate scheduler service from the `AI_NeSy_Framework` repo, not to Express. Auth is a Supabase password-grant bearer token, held in `sessionStorage` (`client/src/scheduler/supabaseAuth.js`). It needs `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in `client/.env.local` (see `client/.env.example`).

The scheduler runs on the host, not in Docker. The `web` container reaches it at `host.docker.internal:8001`.

Dev proxy targets come from `client/vite.proxy.js` (`SCHEDULER_URL`, `API_URL`; the defaults suit a run outside Docker and compose overrides them). In `client/vite.config.js` the scheduler rule must stay ahead of the `/api` rule or it is swallowed by it.

### Client structure

- `client/src/router.js` holds the guards. Routes with `meta.qa` redirect to `/qa/sign-in` unless `sessionState.signedIn` (the Supabase session), independently of the Express session guard on `meta.auth`.
- `client/src/scheduler/` is plain JS with no Vue dependency in the logic modules (`client.js`, `scanFlow.js`, `cycleFlow.js`, `week.js`). `client.js` maps scheduler error codes to user messages. `session.js` wires the singletons and clears the session on 401. Tests sit next to the modules.
- Screens not yet ported still run from `digisaka/legacy/` (the original prototype), embedded in the Vue shell by `LegacyFrame.vue` and talking to it over `postMessage` (see the embed block in `legacy/js/boot.js`). Port a screen by pointing its route at a Vue view in place of `LegacyFrame`.
- Admin screens are under `client/src/admin/` and are scoped by a use case; every `/api/admin` call needs `?useCase=`. Extraction is rule-based (`server/extract.js`), not an LLM.
