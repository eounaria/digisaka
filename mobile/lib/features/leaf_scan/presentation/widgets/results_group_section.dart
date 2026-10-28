import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/verification_group_card.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/validated_group_card.dart';

/// Section that renders one group card per visible stage, switching between
/// verification cards (confirmation pending) and validated cards (all confirmed).
class ResultsGroupSection extends StatelessWidget {
  final Map<LeafStage, List<LeafAssessment>> groups;
  final List<LeafStage> visibleStages;
  final bool allConfirmed;
  final ValueChanged<LeafAssessment> onConfirmLeaf;
  final void Function(LeafAssessment leaf, LeafStage stage) onMoveLeaf;

  const ResultsGroupSection({
    super.key,
    required this.groups,
    required this.visibleStages,
    required this.allConfirmed,
    required this.onConfirmLeaf,
    required this.onMoveLeaf,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final stage in visibleStages)
          if (allConfirmed)
            ValidatedGroupCard(stage: stage, leaves: groups[stage]!)
          else
            VerificationGroupCard(
              stage: stage,
              leaves: groups[stage]!,
              onConfirm: onConfirmLeaf,
              onMove: onMoveLeaf,
            ),
      ],
    );
  }
}

/// Reusable leaf tile for the Results screen: thumbnail + "Leaf n" + eye icon.
class ResultLeafTile extends StatelessWidget {
  final LeafAssessment leaf;
  final VoidCallback onView; // opens showLeafPhotoDialog(context, leaf)

  const ResultLeafTile({super.key, required this.leaf, required this.onView});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E8E1)),
      ),
      child: Row(
        children: [
          // Thumbnail: real photo if leaf.imageFile exists, else bright green rounded square.
          GestureDetector(
            onTap: onView,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 36,
                height: 36,
                child: leaf.imageFile != null
                    ? Image.file(
                        leaf.imageFile!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Container(color: const Color(0xFF8CF08C)),
                      )
                    : Container(color: const Color(0xFF8CF08C)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Leaf ${leaf.number}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          InkWell(
            onTap: onView,
            borderRadius: BorderRadius.circular(18),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                Icons.visibility_outlined,
                size: 20,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
