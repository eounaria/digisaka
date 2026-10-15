import 'package:flutter/foundation.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';
import '../domain/models/smart_schedule_models.dart';
import 'package:digisaka/shared/models/treatment_history.dart';

/// In-memory store for scheduled bulks.
/// TODO: persist to local storage / backend so bulks survive an app restart.
class ScheduleStore extends ChangeNotifier {
  ScheduleStore._();

  static final ScheduleStore instance = ScheduleStore._();

  final List<ScheduledBulk> _bulks = [];
  int _bulkCounter = 0;

  List<ScheduledBulk> get bulks => List.unmodifiable(_bulks);

  ScheduledBulk? bulkById(String id) {
    for (final b in _bulks) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Registers a bulk. Safe to call twice: the same bulkId is never duplicated.
  ScheduledBulk registerBulk({
    required String bulkId,
    required String plantName,
    required List<LeafAssessment> leaves,
    TreatmentHistory? history,
  }) {
    final existing = bulkById(bulkId);
    if (existing != null) return existing;

    // Group leaves by treatment stage (1-4). Healthy / unvalidated are skipped.
    final groups = <LeafStage, List<int>>{};
    for (final leaf in leaves) {
      if (leaf.stage.isTreatment) {
        groups.putIfAbsent(leaf.stage, () => <int>[]).add(leaf.number);
      }
    }

    final today = DateTime.now();
    final stages = <ScheduledStage>[];

    groups.forEach((stage, numbers) {
      numbers.sort();
      final offsets = _windowDays(stage);
      final start = today.add(Duration(days: offsets[0]));
      final end = today.add(Duration(days: offsets[1]));

      stages.add(ScheduledStage(
        stage: stage,
        leafNumbers: numbers,
        treatmentWindow: formatWindow(start, end),
        steps: _buildSteps(bulkId, stage, start, today),
      ));
    });

    // Highest severity first.
    stages.sort((a, b) => b.stage.index.compareTo(a.stage.index));

    final bulk = ScheduledBulk(
      id: bulkId,
      label: 'Bulk ${++_bulkCounter}',
      plantName: plantName,
      createdAt: today,
      stages: stages,
      priorTreatment: history,
    );

    _bulks.add(bulk);
    // Notify after the current frame so a screen that is still building
    // doesn't get rebuilt mid-build.
    Future.microtask(notifyListeners);
    return bulk;
  }

  /// Marks one timeline step as done (optionally storing its proof photo).
  void markStepDone(
    String bulkId,
    LeafStage stage,
    String stepId, {
    String? proofImagePath,
  }) {
    final scheduled = bulkById(bulkId)?.stageOf(stage);
    if (scheduled == null) return;

    final i = scheduled.steps.indexWhere((s) => s.id == stepId);
    if (i == -1) return;

    scheduled.steps[i] = scheduled.steps[i].copyWith(
      done: true,
      proofImagePath: proofImagePath,
    );
    notifyListeners();
  }

  /// Start / end offset (in days from today) of each stage's treatment window.
  static List<int> _windowDays(LeafStage stage) {
    switch (stage) {
      case LeafStage.stage4:
        return [0, 2];
      case LeafStage.stage3:
        return [1, 3];
      case LeafStage.stage2:
        return [1, 4];
      case LeafStage.stage1:
        return [0, 2];
      default:
        return [0, 0];
    }
  }

  /// Mock timeline. Swap for real data later.
  List<TimelineStep> _buildSteps(
    String bulkId,
    LeafStage stage,
    DateTime base,
    DateTime today,
  ) {
    final prefix = '$bulkId-${stage.index}';

    return [
      TimelineStep(
        id: '$prefix-logged',
        type: StepType.diseaseLogged,
        title: 'Suspected Disease Logged',
        subtitle: 'Suspected Black Sigatoka — Stage ${stage.index}',
        date: today,
        done: true,
      ),
      TimelineStep(
        id: '$prefix-oil',
        type: StepType.oil,
        title: 'Oil Application',
        date: base.add(const Duration(days: 5)),
        requiresPhotoProof: true,
      ),
      TimelineStep(
        id: '$prefix-fungicide',
        type: StepType.fungicide,
        title: 'Fungicide / Chemical',
        date: base.add(const Duration(days: 19)),
        requiresPhotoProof: true,
      ),
      TimelineStep(
        id: '$prefix-monitoring',
        type: StepType.monitoring,
        title: 'Monitoring / Reassessment',
        subtitle: 'Follow-up leaf check',
        date: base.add(const Duration(days: 33)),
      ),
    ];
  }
}