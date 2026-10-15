/// Result collected by [TreatmentHistoryScreen].
class TreatmentHistory {
  final String answer;
  final String? treatmentType;
  final DateTime? treatmentDate;

  const TreatmentHistory({
    required this.answer,
    this.treatmentType,
    this.treatmentDate,
  });
}