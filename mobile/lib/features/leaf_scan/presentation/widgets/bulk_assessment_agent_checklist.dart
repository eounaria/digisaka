import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// The "BULK ASSESSMENT AGENT" checklist (9 steps).
class BulkAssessmentAgentChecklist extends StatelessWidget {
  final String bulkId;
  final int currentStepIndex; // 0-based: 2 = Black Sigatoka Validation

  const BulkAssessmentAgentChecklist({
    super.key,
    required this.bulkId,
    required this.currentStepIndex,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> steps = [
      'Bulk Created — $bulkId',
      'Leaf Images Collected',
      'Black Sigatoka Validation',
      'Individual Stage Assessment',
      'Stage Groups Organized',
      'Human Verification',
      'Treatment Recommendation',
      'Schedule Review',
      'Confirm & Schedule',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE3DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BULK ASSESSMENT AGENT',
            style: TextStyle(
              fontSize: 11.5,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < steps.length; i++)
            _buildStep(steps[i], i),
        ],
      ),
    );
  }

  Widget _buildStep(String text, int index) {
    final bool isDone = index < currentStepIndex;
    final bool isCurrent = index == currentStepIndex;

    final String symbol = isDone ? '✓' : (isCurrent ? '→' : '○');
    final Color color = isDone
        ? AppColors.textDark
        : (isCurrent ? AppColors.primaryGreen : const Color(0xFF9AA39A));

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Text(
              symbol,
              style: TextStyle(
                fontSize: 12.5,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: (isDone || isCurrent)
                    ? AppColors.primaryGreen
                    : const Color(0xFF9AA39A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontFamily: 'monospace',
                fontWeight: (isDone || isCurrent) ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}