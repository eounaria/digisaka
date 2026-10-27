import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';

/// White summary card: Line / Week / Status — three columns, each a small grey
/// label above a bold value.
///
/// `line`/`isoWeek` are the preferred values (used by the result screen).
/// `plantName`/`assessmentDate` are kept as fallbacks for legacy callers
/// (`validation_screen.dart`, `treatment_recommendation_screen.dart`) so those
/// screens keep showing the plant name / date when `line`/`isoWeek` are absent.
class BulkAssessmentSummaryCard extends StatelessWidget {
  final String? plantName; // legacy fallback
  final String bulkId;
  final String status;
  final String? assessmentDate; // legacy fallback
  final String? line;
  final String? isoWeek;

  const BulkAssessmentSummaryCard({
    super.key,
    this.plantName,
    required this.bulkId,
    required this.status,
    this.assessmentDate,
    this.line,
    this.isoWeek,
  });

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
      child: Row(
        children: [
          _SummaryColumn(
            label: 'Line',
            value: Text(
              line ?? plantName ?? '—',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          _SummaryDivider(),
          _SummaryColumn(
            label: 'Week',
            value: Text(
              isoWeek ?? assessmentDate ?? '—',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          _SummaryDivider(),
          _SummaryColumn(
            label: 'Status',
            value: Text(
              status,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One column: grey label above a bold value.
class _SummaryColumn extends StatelessWidget {
  final String label;
  final Text value;

  const _SummaryColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 4),
          value,
        ],
      ),
    );
  }
}

/// Thin vertical divider between summary columns.
class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.borderGrey,
      margin: const EdgeInsets.symmetric(vertical: 6),
    );
  }
}
