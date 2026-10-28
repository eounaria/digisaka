# Final Report — Leaf Scan Screen Redesign (Tasks A–D)

## Scope
Rebuilt 4 leaf-scan screens in the Flutter mobile app to match the Figma spec (source of truth: pasted_content id="a402"), order A → B → C → D. Work is isolated to the `leaf_scan` feature; Home, History, Profile, Notifications, and the bottom-nav shell were NOT touched. No business logic was changed unless the spec required it. `withValues(alpha:)` used throughout (no `withOpacity`).

## Files changed (this session)
- `lib/features/leaf_scan/presentation/pages/treatment_proposal_screen.dart` — Task D reworked per the a402 spec.
- `lib/features/leaf_scan/presentation/widgets/proposal_calendar.dart` — Rewritten per Figma (June 2026 calendar card).
- `lib/features/leaf_scan/presentation/widgets/up_next_card.dart` — Rewritten per Figma (Up Next card).
- `lib/features/leaf_scan/presentation/widgets/proposal_timeline.dart` — Rewritten per Figma (Detailed Timeline).

## Task D — TreatmentProposalScreen (DONE per a402 spec)

Screen now supports the PROPOSED / APPROVED / REJECTED proposal lifecycle:

- **State**: local `_ProposalStatus` enum (proposed/approved/rejected) + `_treatmentDone` bool.
- **initState**: builds the pending proposal locally from leaf data (worst treatment stage) with mock June 2026 dates (scan Jun 8, window Jun 15–17, re-assessment Jun 15). The bulk is NOT registered with `ScheduleStore` until the user approves.
- **`_handleApprove()`**: sets status to `approved` and calls `ScheduleStore.instance.registerBulk(...)` only on approve.
- **`_handleReject()`**: sets status to `rejected`. Status banner becomes "Rejected — no treatment scheduled". Reject/Approve buttons are hidden in the proposal card. Calendar UPCOMING highlights and icons are hidden. Up Next card is hidden. Timeline action buttons are removed (cards stay read-only/greyed).
- **`_toggleDone()`**: toggles `_treatmentDone`, updates the "X / 2 done" counter in the timeline.
- **Build order** (all inside one `SingleChildScrollView`):
  1. Title "Bulk Treatment Schedule" + line/isoWeek subtitle (from constructor)
  2. Status banner (awaiting decision / approved / rejected)
  3. Proposal card (title, reason, Note box, Reject/Approve buttons when proposed)
  4. ProposalCalendar (June 2026 grid, Jun 8 green-bordered scan date, Jun 15–17 teal cells with orange UPCOMING tags + magnifier/flame icons)
  5. UpNextCard ("UP NEXT" label above card, "Treatment" ~20px, "Window 15 Jun to 17 Jun", "IN 7 DAYS" chip, description)
  6. ProposalTimeline ("June 2026 — Detailed Timeline" + "0 / 2 done" chip, orange/purple/blue dots, Treatment/Re-assessment/Follow-up items, "Coming later" label)
  7. Footer: AI disclaimer centered, ~24px bottom padding

## Tasks A–C (previously complete, verified still clean)
- **A** `bulk_assess_screen.dart` — validated state: read-only `ValidatedGroupCard`s per stage with per-stage border colors, `_buildLogBox()`, Back / "View results" row.
- **B** `assessment_results_screen.dart` — `_buildStageSection` helper (stage label + count badge + 2-col grid + divider), proposal card "Open proposal →" → `TreatmentHistoryScreen`.
- **C** `treatment_history_screen.dart` — header card, 3 radio cards, both follow-up fields always visible (enabled only when Yes), Continue button always visible.

## Verification
```
flutter analyze lib/features/leaf_scan/presentation/pages/treatment_proposal_screen.dart \
  lib/features/leaf_scan/presentation/widgets/proposal_calendar.dart \
  lib/features/leaf_scan/presentation/widgets/up_next_card.dart \
  lib/features/leaf_scan/presentation/widgets/proposal_timeline.dart
→ No issues found!

flutter analyze (whole project)
→ 0 errors. 15 pre-existing non-error items (14 infos + 1 pubspec asset warning) in
  unrelated files; none in the 4 target files.
```

## Acceptance Checklist (7 items from a402 spec)

| # | Item | Status |
|---|------|--------|
| 1 | Below proposal card: calendar, UP NEXT, Detailed Timeline, "Coming later", footer | Done |
| 2 | Calendar June 2026 grid: Jun 8 green-bordered, Jun 15–17 teal with orange UPCOMING tags | Done |
| 3 | UP NEXT shows "Treatment", "Window Jun 15 to Jun 17", "IN 7 DAYS" chip | Done |
| 4 | Timeline: "0 / 2 done" chip, orange/purple/blue dots, PROPOSED vs APPROVED text | Done |
| 5 | APPROVED shows green "Mark as done"; counter updates (0→1 done) | Done |
| 6 | No overflow, scrolls fully, footer visible above bottom nav | Done |
| 7 | flutter analyze = 0 errors on all 4 target files; withValues not withOpacity | Done |

## Assumptions (Reject behavior)
- When rejected: status banner reads "Rejected — no treatment scheduled"; proposal card keeps its title/reason/Note but hides Reject/Approve buttons; calendar shows plain month grid with only the scan date highlighted (no UPCOMING tags or icons); Up Next card is hidden entirely; timeline cards remain visible but read-only/greyed with no action buttons.
- `registerBulk` is called exactly once, at the moment the user taps Approve (not on init).
- Dates are mock (June 2026) — scan Jun 8, treatment window Jun 15–17, re-assessment Jun 15. Real backend values should replace these.
- "IN 7 DAYS" chip computed as `windowStart.difference(scanDate).inDays` (singular "IN 1 DAY" when 1).

## Remaining TODOs
- Wire real plant name instead of hard-coded 'Banana Plant #002' in `registerBulk` call.
- Replace mock June 2026 dates with real backend-supplied values.
- Line and ISO week are taken from the constructor (already done per spec).
- Commit completed work on `staging` only after human developer go signal; no push without explicit go.

## Status
All implementation work is complete and verified. The working tree sits on branch `staging` with uncommitted changes.

**Next step (requires your go signal):** Commit the completed work on `staging` (one commit, no squash, per repo workflow). Do **not** push — push only on your explicit go signal.

Please reply with your go signal (or any requested changes) before I commit.
