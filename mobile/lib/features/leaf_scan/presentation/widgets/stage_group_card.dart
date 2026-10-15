import 'package:flutter/material.dart';
import '../../../../shared/models/leaf_stage.dart';
import '../../../../shared/models/leaf_assessment.dart';
import '../../domain/bulk_helpers.dart';
import '../../../../shared/widgets/stage_dot.dart';
import '../../../../core/theme/app_colors.dart';

/// A read-only card showing one stage group (used in Treatment Recommendation).
class StageGroupCard extends StatelessWidget {
  final LeafStage stage;
  final List<LeafAssessment> leaves;

  const StageGroupCard({
    super.key,
    required this.stage,
    required this.leaves,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnvalidated = stage == LeafStage.unvalidated;
    final bool isTreatment = stage.isTreatment;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnvalidated ? const Color(0xFFEDEFEB) : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: isTreatment
            ? Border.all(color: const Color(0xFFF3B5B5))
            : null,
        boxShadow: isUnvalidated
            ? null
            : [
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
          // Header row
          Row(
            children: [
              StageDot(stage: stage),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stage.stageName,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: isUnvalidated ? AppColors.textGrey : AppColors.textDark,
                  ),
                ),
              ),
              Text(
                '${leaves.length} ${leaves.length == 1 ? 'leaf' : 'leaves'}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            stage.description,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey, height: 1.35),
          ),
          const SizedBox(height: 10),
          // Leaf list
          Text(
            formatLeafNumbers(leaves),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}