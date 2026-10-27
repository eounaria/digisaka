import 'package:flutter/material.dart';

/// The group a leaf can belong to.
enum LeafStage { healthy, stage1, stage2, stage3, stage4, unvalidated }

/// Order the group cards are shown in.
const List<LeafStage> kStageOrder = [
  LeafStage.healthy,
  LeafStage.stage1,
  LeafStage.stage2,
  LeafStage.stage3,
  LeafStage.stage4,
  LeafStage.unvalidated,
];

/// Order of the "Move to..." options.
const List<LeafStage> kMoveOptions = [
  LeafStage.stage1,
  LeafStage.stage2,
  LeafStage.stage3,
  LeafStage.stage4,
  LeafStage.unvalidated,
  LeafStage.healthy,
];

extension LeafStageInfo on LeafStage {
  /// Name shown on group cards, dropdown and treatment list.
  String get stageName {
    switch (this) {
      case LeafStage.healthy:
        return 'Healthy';
      case LeafStage.stage1:
        return 'Suspected Stage 1';
      case LeafStage.stage2:
        return 'Suspected Stage 2';
      case LeafStage.stage3:
        return 'Suspected Stage 3';
      case LeafStage.stage4:
        return 'Suspected Stage 4 (Advanced)';
      case LeafStage.unvalidated:
        return 'Unvalidated / Review Required';
    }
  }

  /// Small text under the group name.
  String get description {
    switch (this) {
      case LeafStage.healthy:
        return 'No treatment — Continue routine monitoring';
      case LeafStage.stage1:
        return 'Early-stage treatment schedule available — requires user review';
      case LeafStage.stage2:
        return 'Developing-stage treatment schedule available — requires user review';
      case LeafStage.stage3:
        return 'Treatment window may be considered — requires user review';
      case LeafStage.stage4:
        return 'Priority treatment window consideration — requires user review';
      case LeafStage.unvalidated:
        return 'Do not proceed to treatment. Capture another image or perform human inspection.';
    }
  }

  /// Colors of the glossy sphere dot (light -> dark).
  List<Color> get gradient {
    switch (this) {
      case LeafStage.healthy:
        return const [Color(0xFF4CD08A), Color(0xFF1E9E5A)];
      case LeafStage.stage1:
        return const [Color(0xFFF7D358), Color(0xFFD9A21B)];
      case LeafStage.stage2:
        return const [Color(0xFFFFA05E), Color(0xFFE8642A)];
      case LeafStage.stage3:
        return const [Color(0xFFFF8A4D), Color(0xFFE5532B)];
      case LeafStage.stage4:
        return const [Color(0xFFE5405E), Color(0xFFB81D3B)];
      case LeafStage.unvalidated:
        return const [Color(0xFFF1E9FF), Color(0xFFB9A5D8)];
    }
  }

  /// True for Stage 1-4 (these need a treatment-window review).
  bool get isTreatment =>
      this == LeafStage.stage1 ||
      this == LeafStage.stage2 ||
      this == LeafStage.stage3 ||
      this == LeafStage.stage4;

  /// Border color for the stage's group card (same hue as the stage dot).
  /// One source of truth so group cards never duplicate stage colors.
  Color get borderColor {
    switch (this) {
      case LeafStage.healthy:
        return const Color(0xFF1A7A3C); // green
      case LeafStage.stage1:
        return const Color(0xFFF7D358); // yellow
      case LeafStage.stage2:
        return const Color(0xFFFFA05E); // orange
      case LeafStage.stage3:
        return const Color(0xFFFF8A4D); // deep orange
      case LeafStage.stage4:
        return const Color(0xFFE5405E); // red
      case LeafStage.unvalidated:
        return const Color(0xFFB5BDB3); // grey
    }
  }
}