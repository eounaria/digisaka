import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/shared/widgets/stage_dot.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/leaf_photo_dialog.dart';

/// Read-only group card shown once all leaves are confirmed (State C of BulkAssessScreen).
///
/// Displays the stage header, description, and leaf list without confirm/move controls.
class ValidatedGroupCard extends StatelessWidget {
  final LeafStage stage;
  final List<LeafAssessment> leaves;

  const ValidatedGroupCard({
    super.key,
    required this.stage,
    required this.leaves,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...leaves]..sort((a, b) => a.number.compareTo(b.number));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: stage.borderColor, width: 1.5),
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
          Row(
            children: [
              StageDot(stage: stage, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stage.stageName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                '${sorted.length} ${sorted.length == 1 ? 'leaf' : 'leaves'}',
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
          Text(
            stage.description,
            style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.35),
          ),
          const SizedBox(height: 12),
          for (final leaf in sorted) _LeafRow(leaf: leaf),
        ],
      ),
    );
  }
}

class _LeafRow extends StatelessWidget {
  final LeafAssessment leaf;

  const _LeafRow({required this.leaf});

  @override
  Widget build(BuildContext context) {
    final number = leaf.number.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.leafRowConfirmedFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.leafRowConfirmedBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => showLeafPhotoDialog(context, leaf),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.mockLeafTileBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.visibility_outlined,
                color: AppColors.primaryGreen,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Leaf $number',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (leaf.confidence != null)
            Text(
              'AI confidence: ${leaf.confidence!.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
        ],
      ),
    );
  }
}
