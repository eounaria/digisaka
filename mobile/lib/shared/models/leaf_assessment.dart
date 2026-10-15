import 'package:digisaka/shared/models/leaf_stage.dart';

class LeafAssessment {
  final int number;
  LeafStage stage; // not final: the user can move a leaf to another group
  final double? confidence; // percent, null for unvalidated
  bool confirmed;

  LeafAssessment({
    required this.number,
    required this.stage,
    this.confidence,
    this.confirmed = false,
  });
}