import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/shared/widgets/stage_dot.dart';

/// Opens a modal where the user can view (and pinch-zoom) [leaf]'s photo.
/// Read-only: it never mutates the leaf's confirmed or stage state.
Future<void> showLeafPhotoDialog(BuildContext context, LeafAssessment leaf) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _LeafPhotoDialog(leaf: leaf),
  );
}

class _LeafPhotoDialog extends StatelessWidget {
  final LeafAssessment leaf;

  const _LeafPhotoDialog({required this.leaf});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final number = leaf.number.toString().padLeft(2, '0');

    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(number: number, stage: leaf.stage),
          const SizedBox(height: 10),
          _PhotoBody(leaf: leaf, maxHeight: size.height * 0.6),
          const SizedBox(height: 10),
          _Footer(leaf: leaf),
        ],
      ),
    );
  }
}

/// Dialog header: "Leaf NN" + stage chip + close button.
class _Header extends StatelessWidget {
  final String number;
  final LeafStage stage;

  const _Header({required this.number, required this.stage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Leaf $number',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StageDot(stage: stage, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      stage.stageName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textGrey),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

/// Photo body: zoomable image (or empty tile) in a 4:3 frame.
class _PhotoBody extends StatelessWidget {
  final LeafAssessment leaf;
  final double maxHeight;

  const _PhotoBody({required this.leaf, required this.maxHeight});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        color: AppColors.emptyPhotoTileFill,
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: _buildImage(),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final image = leaf.imageFile;
    if (image == null) {
      return _emptyTile('Sample leaf — no photo');
    }
    return Image.file(
      image,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
          _emptyTile('No photo available'),
    );
  }

  Widget _emptyTile(String message) {
    return Container(
      color: AppColors.emptyPhotoTileFill,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco, color: AppColors.primaryGreen, size: 48),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog footer: confidence + current stage name.
class _Footer extends StatelessWidget {
  final LeafAssessment leaf;

  const _Footer({required this.leaf});

  @override
  Widget build(BuildContext context) {
    final confidence = leaf.confidence == null
        ? 'No confidence score'
        : 'AI confidence: ${leaf.confidence!.toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  confidence,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stage: ${leaf.stage.stageName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
