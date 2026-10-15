import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// White summary card: Plant, (Assessment Date), Bulk ID, Status.
class BulkAssessmentSummaryCard extends StatelessWidget {
  final String plantName;
  final String bulkId;
  final String status;
  final String? assessmentDate; // only shown on the result screen

  const BulkAssessmentSummaryCard({
    super.key,
    required this.plantName,
    required this.bulkId,
    required this.status,
    this.assessmentDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _row('Plant', _value(plantName)),
          const _DottedDivider(),
          if (assessmentDate != null) ...[
            _row('Assessment Date', _value(assessmentDate!)),
            const _DottedDivider(),
          ],
          _row(
            'Bulk ID',
            Text(
              bulkId,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const _DottedDivider(),
          _row(
            'Status',
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE5D3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _value(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _row(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
          ),
          const SizedBox(width: 12),
          Flexible(child: value),
        ],
      ),
    );
  }
}

/// Thin dotted line between summary rows.
class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int dots = (constraints.maxWidth / 5).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dots,
            (_) => Container(width: 2, height: 1, color: const Color(0xFFD5DAD3)),
          ),
        );
      },
    );
  }
}