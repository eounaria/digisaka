// Reproduction test for the TreatmentProposalScreen layout crash.
// Pumps the screen in isolation, scrolls to the bottom, then taps
// Approve and Mark as done to capture the first layout exception.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digisaka/features/leaf_scan/presentation/pages/treatment_proposal_screen.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';

void main() {
  testWidgets('renders, scrolls, approves and marks done without layout crash',
      (WidgetTester tester) async {
    final leaves = [
      LeafAssessment(number: 1, stage: LeafStage.stage2),
      LeafAssessment(number: 3, stage: LeafStage.stage2),
      LeafAssessment(number: 5, stage: LeafStage.stage1),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: TreatmentProposalScreen(
          leaves: leaves,
          bulkId: 'bulk-1',
          line: 'L04',
          isoWeek: '2026-W24',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll to the bottom so the footer and all sections lay out.
    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0, -800),
      5000,
    );
    await tester.pumpAndSettle();

    // Approve the proposal.
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    // Mark the treatment as done (updates the done counter).
    await tester.tap(find.text('Mark as done'));
    await tester.pumpAndSettle();
  });
}
