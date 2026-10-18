# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

On `staging` the repo holds one Flutter app, in `mobile/` (package name `digisaka`, Dart SDK `^3.13.4`). The root `README.md` is the unedited Flutter template. `flutter_analyze_baseline.txt` at the root is a saved `flutter analyze` run (info-level lints only). Its paths predate the current `lib/` layout, so treat it as stale.

Other work lives on separate branches, not on `staging` (for example a web frontend under `digisaka/`). Check the branch before assuming a directory exists.

## Commands

Run everything from `mobile/`.

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
