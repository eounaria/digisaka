/// A treatment proposal for a stage group, ready for reviewer approve/reject.
class TreatmentProposal {
  /// Short title, e.g. "Suspected Stage 2 — Treatment Window".
  final String title;

  /// Start of the treatment window (inclusive).
  final DateTime windowStart;

  /// End of the treatment window (inclusive).
  final DateTime windowEnd;

  /// Reason for the proposal (stage, severity, leaf count).
  final String reason;

  /// Proposal lifecycle status.
  final TreatmentProposalStatus status;

  /// Reviewer's note when approving or rejecting.
  final String? note;

  /// Whether the treatment has been marked done.
  final bool treatmentDone;

  const TreatmentProposal({
    required this.title,
    required this.windowStart,
    required this.windowEnd,
    required this.reason,
    this.status = TreatmentProposalStatus.proposed,
    this.note,
    this.treatmentDone = false,
  });

  /// Copy with optional overrides.
  TreatmentProposal copyWith({
    String? title,
    DateTime? windowStart,
    DateTime? windowEnd,
    String? reason,
    TreatmentProposalStatus? status,
    String? note,
    bool? treatmentDone,
  }) {
    return TreatmentProposal(
      title: title ?? this.title,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      note: note ?? this.note,
      treatmentDone: treatmentDone ?? this.treatmentDone,
    );
  }
}

/// Lifecycle of a treatment proposal.
enum TreatmentProposalStatus { proposed, approved, rejected }
