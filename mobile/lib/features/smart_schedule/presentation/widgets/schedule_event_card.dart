import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import '../pages/stage_schedule_screen.dart';

/// A reusable card representing a calendar event for a stage group.
class ScheduleEventCard extends StatelessWidget {
  final LeafStage stage;
  final List<LeafAssessment> leaves;
  final String bulkId;
  final String plantName;
  final String treatmentWindow;
  final bool isScheduled;
  final VoidCallback? onTap;

  const ScheduleEventCard({
    super.key,
    required this.stage,
    required this.leaves,
    required this.bulkId,
    required this.treatmentWindow,
    this.plantName = 'Banana Plant #002',
    this.isScheduled = true,
    this.onTap,
  });

  Color get _dotColor {
    switch (stage) {
      case LeafStage.stage4:
        return const Color(0xFFD32F2F); // red
      case LeafStage.stage3:
        return const Color(0xFFF4623A); // orange-red
      case LeafStage.stage2:
        return const Color(0xFFF59E3B); // orange
      case LeafStage.stage1:
        return const Color(0xFFE8B931); // yellow
      default:
        return AppColors.primaryGreen;
    }
  }

  String get _title => stage == LeafStage.stage4
      ? 'PRIORITY — Black Sigatoka Treatment'
      : 'Black Sigatoka Treatment';

  String get _groupLabel =>
      'Suspected Stage ${stage.index}${stage == LeafStage.stage4 ? ' (Advanced)' : ''}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // ClipRRect + left-only border avoids the Flutter error that happens
        // when borderRadius is combined with a non-uniform Border.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: AppColors.white,
            child: InkWell(
              onTap: onTap ??
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StageScheduleScreen(
                          bulkId: bulkId,
                          stage: stage,
                        ),
                      ),
                    );
                  },
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Color(0xFFD32F2F), width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _dotColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textGrey,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _infoRow('Plant', _valueText(plantName)),
                    _infoRow('Bulk ID', _valueText(bulkId)),
                    _infoRow('Group', _valueText(_groupLabel)),
                    _infoRow('Affected Leaves', _valueText(_formatLeafNumbers())),
                    _infoRow('Treatment Window', _valueText(treatmentWindow)),
                    _infoRow('Status', _statusValue()),

                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Tap to view treatment schedule →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C9A8F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _valueText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _statusValue() {
    if (!isScheduled) {
      return const Text(
        'Not Scheduled',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: AppColors.textGrey,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.check_box, size: 16, color: Color(0xFF22A055)),
        SizedBox(width: 4),
        Text(
          'Scheduled',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF22A055),
          ),
        ),
      ],
    );
  }

  /// Label (grey, left) + value widget (right-aligned).
  Widget _infoRow(String label, Widget value) {
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
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
  }

  /// "Leaf 07" or "Leaf 02, 06" (zero-padded, sorted by leaf number).
  String _formatLeafNumbers() {
    if (leaves.isEmpty) return '';
    final nums = leaves.map((l) => l.number).toList()..sort();
    return 'Leaf ${nums.map((n) => n.toString().padLeft(2, '0')).join(', ')}';
  }
}