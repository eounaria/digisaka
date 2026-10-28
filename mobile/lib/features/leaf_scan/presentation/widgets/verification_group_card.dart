import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/shared/widgets/stage_dot.dart';
import 'package:digisaka/shared/widgets/dashed_rrect_painter.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/leaf_photo_dialog.dart';

/// Group card shown while leaves await human confirmation (State B of BulkAssessScreen).
///
/// Renders the stage header, description, and leaf rows. Unvalidated stage gets
/// a grey fill with a dashed border; all other stages get a white card with a
/// stage.borderColor border.
class VerificationGroupCard extends StatelessWidget {
  final LeafStage stage;
  final List<LeafAssessment> leaves;
  final ValueChanged<LeafAssessment> onConfirm;
  final void Function(LeafAssessment leaf, LeafStage stage) onMove;

  const VerificationGroupCard({
    super.key,
    required this.stage,
    required this.leaves,
    required this.onConfirm,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final isUnvalidated = stage == LeafStage.unvalidated;
    final sorted = [...leaves]..sort((a, b) => a.number.compareTo(b.number));

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnvalidated ? AppColors.unvalidatedCardFill : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: isUnvalidated
            ? null
            : Border.all(color: stage.borderColor, width: 1.5),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isUnvalidated ? AppColors.textGrey : AppColors.textDark,
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
          for (final leaf in sorted)
            _LeafRow(
              leaf: leaf,
              onConfirm: onConfirm,
              onMove: onMove,
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: isUnvalidated
          ? CustomPaint(foregroundPainter: const DashedRRectPainter(), child: card)
          : card,
    );
  }
}

/// One leaf row within a verification group card.
class _LeafRow extends StatelessWidget {
  final LeafAssessment leaf;
  final ValueChanged<LeafAssessment> onConfirm;
  final void Function(LeafAssessment leaf, LeafStage stage) onMove;

  const _LeafRow({
    required this.leaf,
    required this.onConfirm,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final done = leaf.confirmed;
    final number = leaf.number.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: done ? AppColors.leafRowConfirmedFill : AppColors.leafRowFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? AppColors.leafRowConfirmedBorder : AppColors.leafRowBorder,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildEyeButton(context, leaf),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Leaf $number',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  leaf.confidence == null
                      ? 'No confidence score'
                      : 'AI confidence: ${leaf.confidence!.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _buildConfirmButton(leaf, done),
          const SizedBox(width: 6),
          _buildMoveMenu(leaf),
        ],
      ),
    );
  }

  Widget _buildEyeButton(BuildContext context, LeafAssessment leaf) {
    final number = leaf.number.toString().padLeft(2, '0');
    return Semantics(
      label: 'View photo of Leaf $number',
      button: true,
      child: GestureDetector(
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
    );
  }

  Widget _buildConfirmButton(LeafAssessment leaf, bool done) {
    return GestureDetector(
      onTap: () => onConfirm(leaf),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: done ? AppColors.primaryGreen : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: done ? AppColors.primaryGreen : AppColors.leafRowBorder,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          done ? '✓ Confirmed' : 'Confirm',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: done ? AppColors.white : AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildMoveMenu(LeafAssessment leaf) {
    return PopupMenuButton<LeafStage>(
      tooltip: '',
      padding: EdgeInsets.zero,
      color: AppColors.white,
      onSelected: (stage) => onMove(leaf, stage),
      itemBuilder: (context) => [
        for (final stage in <LeafStage>[
          LeafStage.stage1,
          LeafStage.stage2,
          LeafStage.stage3,
          LeafStage.stage4,
          LeafStage.unvalidated,
          LeafStage.healthy,
        ])
          if (stage != leaf.stage)
            PopupMenuItem<LeafStage>(
              value: stage,
              child: Text(
                stage.stageName,
                style: const TextStyle(fontSize: 13, color: AppColors.textDark),
              ),
            ),
      ],
      child: Container(
        width: 88,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.leafRowBorder, width: 1),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Text(
                'Move to…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textDark),
          ],
        ),
      ),
    );
  }
}
