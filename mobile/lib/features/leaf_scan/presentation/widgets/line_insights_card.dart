import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/features/leaf_scan/data/line_insights_data.dart';

/// Line Insights card: 2x2 metric tiles, a last-treatment row, and an inline
/// progression tile. All values are read from [LineInsightsData] — no
/// hard-coded numbers live inside this widget.
class LineInsightsCard extends StatelessWidget {
  final LineInsightsData data;

  const LineInsightsCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
            'LINE INSIGHTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 14),
          _metricGrid(),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderGrey),
          const SizedBox(height: 14),
          _lastTreatmentRow(),
          const SizedBox(height: 14),
          _progressionTile(),
        ],
      ),
    );
  }

  Widget _metricGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metricTile('YLS', data.yls?.toString() ?? '–', AppColors.primaryGreen)),
            const SizedBox(width: 10),
            Expanded(child: _metricTile('YLI', data.yli?.toString() ?? '–', AppColors.primaryGreen)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metricTile(
                'Functional leaves',
                data.functionalLeaves.toString(),
                AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricTile(
                'Infection risk',
                _riskLabel,
                _riskColor,
                backgroundColor: _riskBackground,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String get _riskLabel {
    switch (data.infectionRisk) {
      case InfectionRisk.low:
        return 'Low';
      case InfectionRisk.medium:
        return 'Medium';
      case InfectionRisk.high:
        return 'High';
    }
  }

  Color get _riskColor {
    switch (data.infectionRisk) {
      case InfectionRisk.low:
        return AppColors.infectionLowText;
      case InfectionRisk.medium:
        return AppColors.infectionMediumText;
      case InfectionRisk.high:
        return AppColors.infectionHighText;
    }
  }

  Color get _riskBackground {
    switch (data.infectionRisk) {
      case InfectionRisk.low:
        return AppColors.infectionLowBackground;
      case InfectionRisk.medium:
        return AppColors.infectionMediumBackground;
      case InfectionRisk.high:
        return AppColors.infectionHighBackground;
    }
  }

  Widget _metricTile(String label, String value, Color valueColor, {Color? backgroundColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: AppColors.borderGrey, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _lastTreatmentRow() {
    return Row(
      children: [
        Text(
          'Last treatment',
          style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          data.lastTreatment ?? '–',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ],
    );
  }

  Widget _progressionTile() {
    if (data.progression == ProgressionStatus.none) {
      return const SizedBox.shrink();
    }

    late Color bg;
    late Color border;
    late Color text;
    late String label;
    switch (data.progression) {
      case ProgressionStatus.worsening:
        bg = AppColors.progressionWorseningBackground;
        border = AppColors.progressionWorseningBorder;
        text = AppColors.progressionWorseningBorder;
        label = 'Worsening';
      case ProgressionStatus.improving:
        bg = AppColors.progressionImprovingBackground;
        border = AppColors.progressionImprovingBorder;
        text = AppColors.progressionImprovingBorder;
        label = 'Improving';
      case ProgressionStatus.stable:
        bg = AppColors.progressionStableBackground;
        border = AppColors.progressionStableBorder;
        text = AppColors.progressionStableBorder;
        label = 'Stable';
      case ProgressionStatus.none:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text(
            'Progression',
            style: TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
            ),
          ),
        ],
      ),
    );
  }
}
