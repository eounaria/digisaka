import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Three-step indicator reused by the Leaf Scan and Bulk Assessment Result
/// screens: "Select Leaves" → "Bulk Assess" → "Results".
///
/// Steps below [currentStepIndex] are completed (green + white check), the
/// step at [currentStepIndex] is active (green + number), and steps above it
/// are inactive (grey + number).
class AssessmentStepper extends StatelessWidget {
  /// 0-based index of the active step (0 = Select Leaves, 1 = Bulk Assess, 2 = Results).
  final int currentStepIndex;

  const AssessmentStepper({super.key, this.currentStepIndex = 0});

  static const List<String> _kNumbers = <String>['1', '2', '3'];
  static const List<String> _kLabels = <String>['Select Leaves', 'Bulk Assess', 'Results'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < _kNumbers.length; i++) ...[
          _buildStepCircle(
            number: _kNumbers[i],
            label: _kLabels[i],
            state: _stepState(i),
          ),
          if (i < _kNumbers.length - 1) _buildStepConnector(),
        ],
      ],
    );
  }

  _StepState _stepState(int i) {
    if (i < currentStepIndex) {
      return _StepState.completed;
    }
    if (i == currentStepIndex) {
      return _StepState.active;
    }
    return _StepState.inactive;
  }

  Widget _buildStepCircle({
    required String number,
    required String label,
    required _StepState state,
  }) {
    final bool done = state == _StepState.completed;
    final bool active = state == _StepState.active;

    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: active || done ? AppColors.primaryGreen : AppColors.borderGrey,
          child: done
              ? const Icon(Icons.check, color: AppColors.white, size: 18)
              : Text(
                  number,
                  style: TextStyle(
                    color: active ? AppColors.white : AppColors.textGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active || done ? FontWeight.bold : FontWeight.normal,
            color: active || done ? AppColors.primaryGreen : AppColors.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 2,
        color: AppColors.borderGrey,
      ),
    );
  }
}

enum _StepState { completed, active, inactive }
