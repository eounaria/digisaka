import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';

/// Mock leaves. (TODO: replace with the real backend response.)
List<LeafAssessment> generateMockLeaves(int count) {
  const List<List<Object?>> pattern = [
    [LeafStage.healthy, 95.0],
    [LeafStage.stage1, 94.7],
    [LeafStage.stage2, 91.2],
    [LeafStage.stage3, 88.5],
    [LeafStage.healthy, 95.0],
    [LeafStage.stage1, 94.7],
    [LeafStage.stage4, 96.3],
    [LeafStage.unvalidated, null],
  ];

  return List.generate(count, (i) {
    final row = pattern[i % pattern.length];
    return LeafAssessment(
      number: i + 1,
      stage: row[0] as LeafStage,
      confidence: row[1] as double?,
    );
  });
}

/// "BA-2026-0819-002"
String generateBulkId() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return 'BA-${now.year}-$month$day-002';
}

/// "August 19, 2026"
String getAssessmentDate() {
  final now = DateTime.now();
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${months[now.month - 1]} ${now.day}, ${now.year}';
}

/// Formats a list of leaf numbers as "Leaf 01, 05, 08" (zero-padded, sorted).
String formatLeafNumbers(List<LeafAssessment> leaves) {
  if (leaves.isEmpty) return '';
  final numbers = leaves.map((l) => l.number.toString().padLeft(2, '0')).toList()
    ..sort((a, b) => a.compareTo(b));
  return 'Leaf ${numbers.join(', ')}';
}