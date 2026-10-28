import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Five-step indicator for the Treatment decision flow:
/// "Disease" (= Results, done) → Weather → Spray log → Fungicides → Decision.
///
/// Steps below [currentStepIndex] are completed (dark-green circle + white
/// check, bold label), the step at [currentStepIndex] is active (dark-green
/// circle + number, bold label), and steps above it are upcoming
/// (white/grey circle + number, grey label).
class FlowStepper5 extends StatelessWidget {
  /// 0-based index of the active step (0 = Disease, 1 = Weather, ...).
  final int currentStepIndex;

  const FlowStepper5({super.key, this.currentStepIndex = 0});

  static const List<String> _kNumbers = <String>['1', '2', '3', '4', '5'];
  static const List<String> _kLabels = <String>[
    'Disease',
    'Weather',
    'Spray log',
    'Fungicides',
    'Decision',
  ];

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
      mainAxisSize: MainAxisSize.min,
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
