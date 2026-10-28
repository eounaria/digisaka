import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';

/// A row with a grey/dark label on the left and a bold value on the right.
class SpecRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueBold;

  const SpecRow({
    super.key,
    required this.label,
    required this.value,
    this.valueBold = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
