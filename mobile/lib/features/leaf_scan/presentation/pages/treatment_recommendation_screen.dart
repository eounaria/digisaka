import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/bulk_assessment_agent_checklist.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/bulk_assessment_summary_card.dart';
import 'package:digisaka/shared/widgets/stage_dot.dart';
import 'bulk_treatment_schedule_screen.dart';
import 'package:digisaka/shared/navigation/shell_scope.dart';
import 'treatment_history_screen.dart';


/// Treatment Recommendation screen shown after all leaves are confirmed
/// on the Bulk Assessment Result page.
class TreatmentRecommendationScreen extends StatelessWidget {
  final List<LeafAssessment> leaves;
  final String bulkId;

  const TreatmentRecommendationScreen({
    super.key,
    required this.leaves,
    required this.bulkId,
  });

  @override
  Widget build(BuildContext context) {
    final groups = _getGroups();
    final List<LeafStage> visibleStages =
        kStageOrder.where((s) => groups[s]!.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Treatment Recommendation',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              const Text(
                'Each group below reflects only leaves validated — and reviewer-confirmed — at that stage. The bulk itself has no single stage — treatment is never applied because the bulk contains a severe case elsewhere.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Summary Card (no assessment date)
              BulkAssessmentSummaryCard(
                plantName: 'Banana Plant #002',
                bulkId: bulkId,
                status: 'Validated — Grouped by Stage',
              ),
              const SizedBox(height: 24),

              // Agent Checklist (step 6 current)
              BulkAssessmentAgentChecklist(
                bulkId: bulkId,
                currentStepIndex: 6, // Treatment Recommendation
              ),
              const SizedBox(height: 24),

              // Stage Group Cards
              ...visibleStages.map(
                (stage) => _RecommendationGroupCard(
                  stage: stage,
                  leaves: groups[stage]!,
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              _buildContinueButton(context),
              const SizedBox(height: 12),
              _buildBackToSummaryButton(context),
              const SizedBox(height: 12),
              _buildDoneButton(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Groups leaves by stage, ensuring all stages are present (even if empty).
  Map<LeafStage, List<LeafAssessment>> _getGroups() {
    final map = <LeafStage, List<LeafAssessment>>{
      for (final s in kStageOrder) s: <LeafAssessment>[],
    };
    for (final leaf in leaves) {
      map[leaf.stage]!.add(leaf);
    }
    return map;
  }

  /// Continue to Bulk Treatment Schedule button (placeholder)
  Widget _buildContinueButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Recommendation -> Treatment History -> Bulk Treatment Schedule
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TreatmentHistoryScreen(
              onContinue: (history) {
                // TODO: save `history` (answer, type, date) with the bulk.
                // Replace the history screen so Back from the schedule
                // returns to the recommendation screen.
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => BulkTreatmentScheduleScreen(
                      leaves: leaves,
                      bulkId: bulkId,
                      treatmentHistory: history,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF22A055), AppColors.darkGreen],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'Continue to Bulk Treatment Schedule →',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Back to Summary button (returns to Result page)
  Widget _buildBackToSummaryButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E8E1)),
        ),
        child: const Text(
          'Back to Summary',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Done — Back to Home button (clears Scan tab stack and goes to Home)
  Widget _buildDoneButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Clear the Scan tab's stack
        Navigator.of(context).popUntil((route) => route.isFirst);
        // Switch to Home tab (index 0)
        final shellScope = ShellScope.maybeOf(context);
        if (shellScope != null) {
          shellScope.changeTab(0);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E8E1)),
        ),
        child: const Text(
          'Done — Back to Home',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}


/// Read-only card for one stage group (header, description, its leaves).
/// Private to this screen so it doesn't depend on a shared StageGroupCard.
class _RecommendationGroupCard extends StatelessWidget {
  final LeafStage stage;
  final List<LeafAssessment> leaves;

  const _RecommendationGroupCard({
    required this.stage,
    required this.leaves,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...leaves]..sort((a, b) => a.number.compareTo(b.number));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: stage.isTreatment
            ? Border.all(color: const Color(0xFFF3B5B5))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StageDot(stage: stage),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stage.stageName,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                '${sorted.length} ${sorted.length == 1 ? 'leaf' : 'leaves'}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stage.description,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textGrey,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          for (final leaf in sorted)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F3E6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8FCFA0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Leaf ${leaf.number.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Text(
                    leaf.confidence == null
                        ? 'No confidence score'
                        : 'AI confidence: ${leaf.confidence!.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}