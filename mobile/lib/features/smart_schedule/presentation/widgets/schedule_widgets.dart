import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:digisaka/features/smart_schedule/domain/models/smart_schedule_models.dart';

const Color kScheduleBg = Color(0xFFF3F5F2);
const Color kScheduleBorder = Color(0xFFE3E8E1);
const Color kBeige = Color(0xFFEFE6D6);

const List<BoxShadow> kCardShadow = [
  BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
];

/// Color used for each step type (timeline node, title, calendar dot).
Color stepColor(StepType type) {
  switch (type) {
    case StepType.oil:
      return const Color(0xFFE6B422);
    case StepType.fungicide:
      return const Color(0xFF3B6FD4);
    case StepType.monitoring:
      return const Color(0xFF9E9AB8);
    case StepType.diseaseLogged:
      return const Color(0xFF22A055);
  }
}

/// White rounded header bar with a title and a close (X) button.
class ScheduleHeader extends StatelessWidget {
  final String title;

  const ScheduleHeader({super.key, this.title = 'Smart Schedule'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  color: AppColors.primaryGreen, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small monospace section label, e.g. "UP NEXT".
class ScheduleSectionLabel extends StatelessWidget {
  final String text;

  const ScheduleSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        color: AppColors.textGrey,
      ),
    );
  }
}

/// Full-width green gradient button. Faded and inactive when [enabled] is false.
class ScheduleGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const ScheduleGradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF22A055), AppColors.darkGreen],
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width white button with a light border.
class ScheduleOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const ScheduleOutlineButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kScheduleBorder),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }
}