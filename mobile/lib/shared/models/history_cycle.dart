import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';

/// Status of a saved scan cycle, shown in the History screen.
enum HistoryStatus {
  humanReview,
  awaitingDecision,
  applied,
  rejected,
  noTreatment,
}

/// Human-readable status text shown in the History screen.
extension HistoryStatusText on HistoryStatus {
  String get label {
    switch (this) {
      case HistoryStatus.applied:
        return 'Applied';
      case HistoryStatus.awaitingDecision:
        return 'awaiting decision';
      case HistoryStatus.humanReview:
        return 'Human review required';
      case HistoryStatus.rejected:
        return 'Rejected';
      case HistoryStatus.noTreatment:
        return 'No treatment needed';
    }
  }
}

/// One saved scan cycle, keyed by (line, isoWeek). Re-scanning the same line
//  and week replaces the existing cycle instead of duplicating it.
class HistoryCycle {
  final String line;
  final String isoWeek;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final HistoryStatus status;
  final DateTime? appliedDate;
  final String? bulkId;
  final List<LeafAssessment> leaves;
  final DateTime createdAt;

  HistoryCycle({
    required this.line,
    required this.isoWeek,
    this.windowStart,
    this.windowEnd,
    required this.status,
    this.appliedDate,
    this.bulkId,
    required this.leaves,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Default status for a fresh scan of [leaves]:
  //  - noTreatment if no leaf needs treatment
  //  - humanReview if any leaf is Unvalidated and none are Stage 1-4
  //  - awaitingDecision otherwise
  static HistoryStatus initialStatus(List<LeafAssessment> leaves) {
    final hasTreatment = leaves.any((l) => l.stage.isTreatment);
    final hasUnvalidated = leaves.any((l) => l.stage == LeafStage.unvalidated);
    if (!hasTreatment) return HistoryStatus.noTreatment;
    if (hasUnvalidated) return HistoryStatus.humanReview;
    return HistoryStatus.awaitingDecision;
  }

  HistoryCycle copyWith({
    String? line,
    String? isoWeek,
    DateTime? windowStart,
    DateTime? windowEnd,
    HistoryStatus? status,
    DateTime? appliedDate,
    String? bulkId,
    List<LeafAssessment>? leaves,
    DateTime? createdAt,
  }) {
    return HistoryCycle(
      line: line ?? this.line,
      isoWeek: isoWeek ?? this.isoWeek,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      status: status ?? this.status,
      appliedDate: appliedDate ?? this.appliedDate,
      bulkId: bulkId ?? this.bulkId,
      leaves: leaves ?? this.leaves,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
