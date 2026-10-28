import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';

/// Amber demo banner reused across the treatment decision screens.
class SampleDataBanner extends StatelessWidget {
  const SampleDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sampleDataBannerBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Sample data for demo. Not validated guidance or label information.',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.sampleDataBannerText,
        ),
      ),
    );
  }
}
