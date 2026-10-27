import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/bulk_assessment_agent_checklist.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/bulk_assessment_summary_card.dart';
import 'package:digisaka/features/smart_schedule/presentation/widgets/schedule_event_card.dart';
import 'package:digisaka/shared/navigation/shell_scope.dart';
import 'package:digisaka/features/smart_schedule/domain/models/smart_schedule_models.dart';
import 'package:digisaka/features/smart_schedule/data/smart_schedule_store.dart';
import 'package:digisaka/features/smart_schedule/presentation/pages/stage_schedule_screen.dart';
import 'package:digisaka/shared/models/treatment_history.dart';

/// Highest severity first. Healthy / unvalidated never get a schedule.
const List<LeafStage> _kScheduledStages = [
  LeafStage.stage4,
  LeafStage.stage3,
  LeafStage.stage2,
  LeafStage.stage1,
];

/// Screen showing the bulk treatment schedule for stage groups.
/// Opening it registers the bulk in the Smart Schedule.
class BulkTreatmentScheduleScreen extends StatefulWidget {
  final List<LeafAssessment> leaves;
  final String bulkId;
  final TreatmentHistory? treatmentHistory;

  const BulkTreatmentScheduleScreen({
    super.key,
    required this.leaves,
    required this.bulkId,
    this.treatmentHistory,
  });

  @override
  State<BulkTreatmentScheduleScreen> createState() =>
      _BulkTreatmentScheduleScreenState();
}

class _BulkTreatmentScheduleScreenState
    extends State<BulkTreatmentScheduleScreen> {
  late final ScheduledBulk _scheduled;

  @override
  void initState() {
    super.initState();
    // Idempotent: reopening this screen never creates a duplicate bulk.
    _scheduled = ScheduleStore.instance.registerBulk(
      bulkId: widget.bulkId,
      plantName: 'Banana Plant #002', // TODO: use the real plant name
      leaves: widget.leaves,
      history: widget.treatmentHistory,
    );
  }

  Map<LeafStage, List<LeafAssessment>> _getGroups() {
    final map = <LeafStage, List<LeafAssessment>>{
      for (final s in kStageOrder) s: <LeafAssessment>[],
    };
    for (final leaf in widget.leaves) {
      map[leaf.stage]!.add(leaf);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _getGroups();
    final stagesWithLeaves =
        _kScheduledStages.where((s) => groups[s]!.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bulk Treatment Schedule',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),

              // Confirmation banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F1E6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFB7DABF)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_box, color: Color(0xFF22A055), size: 30),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule Confirmed',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Eligible stage groups are scheduled automatically — calendar events have been created below.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              BulkAssessmentSummaryCard(
                plantName: 'Banana Plant #002',
                bulkId: widget.bulkId,
                status: 'Scheduled',
              ),
              const SizedBox(height: 16),

              // 9 steps (index 0-8). Index 9 = every step completed.
              BulkAssessmentAgentChecklist(
                currentStepIndex: 9,
              ),
              const SizedBox(height: 24),

              const Text(
                'BULK/STAGE-GROUP CALENDAR EVENTS',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 14),

              ...stagesWithLeaves.map(
                (stage) => ScheduleEventCard(
                  stage: stage,
                  leaves: groups[stage]!,
                  bulkId: widget.bulkId,
                  treatmentWindow:
                      _scheduled.stageOf(stage)?.treatmentWindow ?? 'N/A',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StageScheduleScreen(
                        bulkId: widget.bulkId,
                        stage: stage,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              _buildDoneButton(context),
              const SizedBox(height: 20),

              const Center(
                child: Text(
                  'This is an AI-assisted assessment and not a confirmed diagnosis. '
                  'Results should be verified by an agricultural specialist before treatment decisions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ShellScope.maybeOf(context)?.changeTab(0);
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
          'Done — Back to Home',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}