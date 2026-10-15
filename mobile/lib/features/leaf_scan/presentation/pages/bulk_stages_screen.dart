import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/widgets/stage_dot.dart';
import 'package:digisaka/features/smart_schedule/presentation/widgets/schedule_widgets.dart';
import 'package:digisaka/features/smart_schedule/domain/models/smart_schedule_models.dart';
import 'package:digisaka/features/smart_schedule/data/smart_schedule_store.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/features/smart_schedule/presentation/pages/stage_schedule_screen.dart';

/// Lists the scheduled stages (1-4) of one bulk.
/// Tapping a stage opens its detailed schedule.
class BulkStagesScreen extends StatelessWidget {
  final String bulkId;

  const BulkStagesScreen({super.key, required this.bulkId});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ScheduleStore.instance,
      builder: (context, _) {
        final bulk = ScheduleStore.instance.bulkById(bulkId);

        if (bulk == null) {
          return const Scaffold(
            backgroundColor: kScheduleBg,
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScheduleHeader(),
                    SizedBox(height: 24),
                    Text(
                      'This bulk could not be found.',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: kScheduleBg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScheduleHeader(),
                  const SizedBox(height: 22),
                  Text(
                    bulk.label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${bulk.plantName} · ${bulk.id}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap a stage to see its treatment schedule',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (bulk.stages.isEmpty)
                    _emptyState()
                  else
                    for (final scheduled in bulk.stages)
                      _stageCard(context, bulk, scheduled),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy, size: 44, color: AppColors.textGrey),
          SizedBox(height: 14),
          Text(
            'No stages need treatment in this bulk',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stageCard(
    BuildContext context,
    ScheduledBulk bulk,
    ScheduledStage scheduled,
  ) {
    final next = scheduled.nextStep;
    final leaves = scheduled.leafNumbers
        .map((n) => n.toString().padLeft(2, '0'))
        .join(', ');

    final String nextText;
    Color nextColor = AppColors.textGrey;
    if (next == null) {
      nextText = 'All steps completed';
      nextColor = const Color(0xFF22A055);
    } else if (next.overdueDays > 0) {
      nextText = '${next.title} — ${next.overdueDays} day'
          '${next.overdueDays == 1 ? '' : 's'} overdue';
      nextColor = const Color(0xFFD32F2F);
    } else {
      nextText = 'Next: ${next.title} · ${formatShortDate(next.date)}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: kCardShadow,
        ),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StageScheduleScreen(
                  bulkId: bulk.id,
                  stage: scheduled.stage,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StageDot(stage: scheduled.stage),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          scheduled.stage.stageName,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textGrey, size: 22),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: kScheduleBorder),
                  const SizedBox(height: 12),
                  _infoRow('Affected Leaves', 'Leaf $leaves'),
                  _infoRow('Treatment Window', scheduled.treatmentWindow),
                  _infoRow('Progress', TimelineStep.doneCount(scheduled.steps)),
                  const SizedBox(height: 4),
                  Text(
                    nextText,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: nextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}