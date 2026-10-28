import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';

/// The "BULK ASSESSMENT AGENT" checklist (7 steps) shown on the result screen.
///
/// Steps below [currentStepIndex] are completed (green check circle), the step
/// at [currentStepIndex] is current (yellow numbered circle), and the rest are
/// upcoming (grey numbered circle).
class AssessmentProgressChecklist extends StatelessWidget {
  /// 0-based index of the current step.
  final int currentStepIndex;

  const AssessmentProgressChecklist({
    super.key,
    required this.currentStepIndex,
  });

  static const List<String> _kSteps = <String>[
    'Leaf Images Collected',
    'Black Sigatoka Validation',
    'Individual Stage Assessment',
    'Stage Groups Organized',
    'Human Verification',
    'Treatment Recommendation',
    'Schedule Review',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BULK ASSESSMENT AGENT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < _kSteps.length; i++)
            _buildStep(_kSteps[i], i),
        ],
      ),
    );
  }

  Widget _buildStep(String text, int index) {
    final bool isDone = index < currentStepIndex;
    final bool isCurrent = index == currentStepIndex;

    final Color circleColor;
    final Color textColor;
    Widget symbol;

    if (isDone) {
      circleColor = AppColors.primaryGreen;
      textColor = AppColors.primaryGreen;
      symbol = const Icon(Icons.check, color: AppColors.white, size: 16);
    } else if (isCurrent) {
      circleColor = AppColors.accentYellow;
      textColor = AppColors.primaryGreen;
      symbol = Text(
        '${index + 1}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryGreen,
        ),
      );
    } else {
      circleColor = AppColors.borderGrey;
      textColor = AppColors.textGrey;
      symbol = Text(
        '${index + 1}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textGrey,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Center(child: symbol),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isDone || isCurrent ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
