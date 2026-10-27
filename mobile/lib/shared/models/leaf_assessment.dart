import 'dart:io';

import 'package:digisaka/shared/models/leaf_stage.dart';

class LeafAssessment {
  final int number;
  LeafStage stage; // not final: the user can move a leaf to another group
  final double? confidence; // percent, null for unvalidated
  final File? imageFile; // photo for this leaf, null for mock / sample leaves
  bool confirmed;

  LeafAssessment({
    required this.number,
    required this.stage,
    this.confidence,
    this.imageFile,
    this.confirmed = false,
  });
}