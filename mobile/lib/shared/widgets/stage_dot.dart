import 'package:flutter/material.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';

/// Glossy round "sphere" dot used for each stage.
class StageDot extends StatelessWidget {
  final LeafStage stage;
  final double size;

  const StageDot({super.key, required this.stage, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.9,
          colors: stage.gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: stage.gradient.last.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}