import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/shared/models/treatment_history.dart';
import 'package:digisaka/shared/models/fungicide_product.dart';

// ---------- date helpers (no intl dependency needed) ----------

const List<String> _kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "August 15, 2026"
String formatLongDate(DateTime d) => '${_kMonths[d.month - 1]} ${d.day}, ${d.year}';

/// "August 15"
String formatMonthDay(DateTime d) => '${_kMonths[d.month - 1]} ${d.day}';

/// "Aug 15"
String formatShortDate(DateTime d) =>
    '${_kMonths[d.month - 1].substring(0, 3)} ${d.day}';

/// "Aug 15, 2026"
String formatShortDateYear(DateTime d) => '${formatShortDate(d)}, ${d.year}';

/// "August 2026"
String formatMonthYear(DateTime d) => '${_kMonths[d.month - 1]} ${d.year}';

/// "August 20–22, 2026"
String formatWindow(DateTime start, DateTime end) {
  if (start.month == end.month && start.year == end.year) {
    return '${_kMonths[start.month - 1]} ${start.day}–${end.day}, ${start.year}';
  }
  return '${formatMonthDay(start)} – ${formatMonthDay(end)}, ${end.year}';
}

/// Date with no time-of-day, in UTC so day differences ignore DST.
DateTime dayOf(DateTime d) => DateTime.utc(d.year, d.month, d.day);

// ---------- enums ----------

enum StepType { diseaseLogged, oil, fungicide, monitoring }

enum StepStatus { done, missed, upcoming }

// ---------- models ----------

/// One step in a stage's treatment timeline.
class TimelineStep {
  final String id;
  final StepType type;
  final String title;
  final DateTime date;
  final String? subtitle;
  final bool requiresPhotoProof;
  final bool done;
  final String? proofImagePath;

  const TimelineStep({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    this.subtitle,
    this.requiresPhotoProof = false,
    this.done = false,
    this.proofImagePath,
  });

  TimelineStep copyWith({bool? done, String? proofImagePath}) {
    return TimelineStep(
      id: id,
      type: type,
      title: title,
      date: date,
      subtitle: subtitle,
      requiresPhotoProof: requiresPhotoProof,
      done: done ?? this.done,
      proofImagePath: proofImagePath ?? this.proofImagePath,
    );
  }

  /// Days past the scheduled date (0 if done or not yet due).
  int get overdueDays {
    if (done) return 0;
    final diff = dayOf(DateTime.now()).difference(dayOf(date)).inDays;
    return diff > 0 ? diff : 0;
  }

  StepStatus get status {
    if (done) return StepStatus.done;
    return overdueDays > 0 ? StepStatus.missed : StepStatus.upcoming;
  }

  /// "0 / 3 done". The "Suspected Disease Logged" entry is not counted.
  static String doneCount(List<TimelineStep> steps) {
    final actionable =
        steps.where((s) => s.type != StepType.diseaseLogged).toList();
    final done = actionable.where((s) => s.done).length;
    return '$done / ${actionable.length} done';
  }
}

/// A row in the "Treatment History" list.
class TreatmentRecord {
  final String title;
  final DateTime date;
  final StepType kind; // oil or fungicide
  final StepStatus status;

  const TreatmentRecord({
    required this.title,
    required this.date,
    required this.kind,
    required this.status,
  });
}

/// A treatment stage (1-4) inside a scheduled bulk.
class ScheduledStage {
  final LeafStage stage;
  final List<int> leafNumbers;
  final String treatmentWindow;
  final DateTime windowStart;
  final DateTime windowEnd;
  final List<TimelineStep> steps;

  ScheduledStage({
    required this.stage,
    required this.leafNumbers,
    required this.treatmentWindow,
    required this.windowStart,
    required this.windowEnd,
    required this.steps,
  });

  /// Earliest step that still needs doing.
  TimelineStep? get nextStep {
    for (final s in steps) {
      if (!s.done && s.type != StepType.diseaseLogged) return s;
    }
    return null;
  }
}

/// A bulk that has a confirmed treatment schedule.
class ScheduledBulk {
  final String id;
  final String label;
  final String plantName;
  final DateTime createdAt;
  final List<ScheduledStage> stages;
  final TreatmentHistory? priorTreatment;
  final FungicideProduct? selectedProduct;
  final DateTime? selectedDate;
  final String? note;

  ScheduledBulk({
    required this.id,
    required this.label,
    required this.plantName,
    required this.createdAt,
    required this.stages,
    this.priorTreatment,
    this.selectedProduct,
    this.selectedDate,
    this.note,
  });

  ScheduledStage? stageOf(LeafStage stage) {
    for (final s in stages) {
      if (s.stage == stage) return s;
    }
    return null;
  }

  /// "Plant #002" (taken from "Banana Plant #002").
  String get plantTag {
    final i = plantName.indexOf('#');
    return i == -1 ? plantName : 'Plant ${plantName.substring(i)}';
  }

  /// Prior treatment (from the history form) + this stage's applications.
  List<TreatmentRecord> historyFor(ScheduledStage stage) {
    final list = <TreatmentRecord>[];

    final p = priorTreatment;
    if (p != null &&
        p.answer == 'Yes, I have treated it' &&
        p.treatmentDate != null) {
      final type = (p.treatmentType ?? '').trim();
      final lower = type.toLowerCase();
      list.add(TreatmentRecord(
        title: type.isEmpty
            ? 'Previous treatment'
            : (lower.contains('application') ? type : '$type Application'),
        date: p.treatmentDate!,
        kind: lower.contains('oil') ? StepType.oil : StepType.fungicide,
        status: StepStatus.done,
      ));
    }

    for (final s in stage.steps) {
      if (s.type == StepType.oil || s.type == StepType.fungicide) {
        list.add(TreatmentRecord(
          title: s.type == StepType.oil
              ? 'Oil Application'
              : 'Fungicide Application',
          date: s.date,
          kind: s.type,
          status: s.status,
        ));
      }
    }

    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }
}