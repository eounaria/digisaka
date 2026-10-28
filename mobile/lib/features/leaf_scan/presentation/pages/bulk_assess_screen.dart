import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/features/leaf_scan/domain/bulk_helpers.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/assessment_summary_card.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/assessment_progress_checklist.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/results_group_section.dart';
import 'package:digisaka/features/leaf_scan/presentation/pages/assessment_results_screen.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/validated_group_card.dart';
import 'package:digisaka/features/history/data/history_store.dart';
import 'package:digisaka/shared/models/history_cycle.dart';

class BulkAssessScreen extends StatefulWidget {
  final int leafCount;
  final List<File?>? leafPhotos;
  final String line;
  final String isoWeek;
  final DateTime selectedDate;

  const BulkAssessScreen({
    super.key,
    required this.leafCount,
    this.leafPhotos,
    required this.line,
    required this.isoWeek,
    required this.selectedDate,
  });

  @override
  State<BulkAssessScreen> createState() => _BulkAssessScreenState();
}

enum _ScreenState { validation, confirmation, validated }

class _BulkAssessScreenState extends State<BulkAssessScreen>
    with SingleTickerProviderStateMixin {
  late final List<LeafAssessment> _leaves;
  late final AnimationController _spinController;
  final ScrollController _logController = ScrollController();
  final String _bulkId = generateBulkId();

  _ScreenState _screenState = _ScreenState.validation;
  String _status = 'Validating...';
  int _currentStep = 2; // 2 = "Black Sigatoka Validation"
  final List<String> _logLines = [];

  bool get _allConfirmed => _leaves.every((l) => l.confirmed);

  int get _confirmedCount => _leaves.where((l) => l.confirmed).length;

  @override
  void initState() {
    super.initState();
    _leaves = generateMockLeaves(widget.leafCount, leafPhotos: widget.leafPhotos);

    // Keeps the arcs spinning.
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _runValidation();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _logController.dispose();
    super.dispose();
  }

  /// Waits, then tells us if the screen is still alive.
  Future<bool> _wait(int ms) async {
    await Future.delayed(Duration(milliseconds: ms));
    return mounted;
  }

  /// MOCK validation. (TODO: replace with the real backend call.)
  /// When finished, transitions to the confirmation state (State B) instead of
  /// pushing a separate results screen — validation + confirmation live on ONE
  /// screen per the redesign spec.
  Future<void> _runValidation() async {
    final rand = Random();
    final int total = _leaves.length;

    for (final leaf in _leaves) {
      if (!await _wait(250 + rand.nextInt(150))) return;

      final String num = leaf.number.toString().padLeft(2, '0');
      final String tag = 'Leaf $num/$total';

      _addLog('🤖 Agent → $tag — Black Sigatoka validation');
      if (!await _wait(120)) return;

      if (leaf.stage == LeafStage.unvalidated) {
        _addLog('checking image quality…');
        if (!await _wait(120)) return;
        _addLog('✗ $tag — image unclear, routed to: Unvalidated / Review Required');
        continue;
      }

      _addLog('checking treatment eligibility…');
      if (!await _wait(120)) return;

      if (leaf.stage == LeafStage.healthy) {
        _addLog('→ not eligible — healthy only');
        if (!await _wait(120)) return;
        _addLog('✓ $tag complete — routed to: ${leaf.stage.stageName}');
      } else {
        _addLog('→ eligible — suspected Stage ${leaf.stage.index}');
        if (!await _wait(120)) return;
        _addLog('✓ $tag complete — routed to: ${leaf.stage.stageName}');
      }
    }

    // Move the checklist forward.
    if (!await _wait(600)) return;
    setState(() => _currentStep = 3); // Individual Stage Assessment

    if (!await _wait(700)) return;
    setState(() => _currentStep = 4); // Stage Groups Organized

    if (!await _wait(800)) return;
    if (!mounted) return;
    setState(() {
      _status = 'Validated — Grouped by Stage';
      _screenState = _ScreenState.confirmation;
    });
  }

  void _addLog(String line) {
    if (!mounted) return;
    setState(() => _logLines.add(line));

    // Scroll to the newest line.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logController.hasClients) {
        _logController.animateTo(
          _logController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Confirm a leaf (toggle). Moving a leaf also counts as confirmed.
  void _toggleConfirm(LeafAssessment leaf) {
    setState(() => leaf.confirmed = !leaf.confirmed);
  }

  void _moveLeaf(LeafAssessment leaf, LeafStage newStage) {
    setState(() {
      leaf.stage = newStage;
      leaf.confirmed = true;
    });
  }

  void _handleProceed() {
    if (!_allConfirmed) {
      _showMessage('Confirm all leaves first ($_confirmedCount/${_leaves.length})');
      return;
    }
    setState(() {
      _screenState = _ScreenState.validated;
    });
  }

  void _handleViewResults() {
    // Save every finished scan into History under the selected line. Keyed by
    // (line, isoWeek), so re-scanning the same line and week replaces the
    // existing cycle instead of duplicating it.
    HistoryStore.instance.upsertCycle(
      HistoryCycle(
        line: widget.line,
        isoWeek: widget.isoWeek,
        bulkId: _bulkId,
        leaves: _leaves,
        status: HistoryCycle.initialStatus(_leaves),
        // Mock treatment window until the backend supplies real dates.
        windowStart: DateTime(2026, 6, 15),
        windowEnd: DateTime(2026, 6, 17),
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'results'),
        builder: (_) => AssessmentResultsScreen(
          leaves: _leaves,
          bulkId: _bulkId,
          line: widget.line,
          isoWeek: widget.isoWeek,
          selectedDate: widget.selectedDate,
        ),
      ),
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // =========================================================================
  // State A — Validation: spinning arcs + live log
  // =========================================================================

  Widget _buildValidationState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        _buildLoader(),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Validating & Assessing ${_leaves.length} Leaves...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildLogBox(),
      ],
    );
  }

  // =========================================================================
  // State B — Confirmation: group cards + leaf rows with confirm/move
  // =========================================================================

  Widget _buildConfirmationState() {
    final groups = <LeafStage, List<LeafAssessment>>{
      for (final s in kStageOrder) s: <LeafAssessment>[],
    };
    for (final leaf in _leaves) {
      groups[leaf.stage]!.add(leaf);
    }
    final visibleStages =
        kStageOrder.where((s) => groups[s]!.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Text(
            _status,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ResultsGroupSection(
          groups: groups,
          visibleStages: visibleStages,
          allConfirmed: _allConfirmed,
          onConfirmLeaf: (leaf) => _toggleConfirm(leaf),
          onMoveLeaf: (leaf, stage) => _moveLeaf(leaf, stage),
        ),
        const SizedBox(height: 20),
        _buildProceedButton(enabled: true, onPressed: _handleProceed),
      ],
    );
  }

  // =========================================================================
  // State C — Validated: all leaves confirmed, ready for treatment proposal
  // =========================================================================

  Widget _buildValidatedState() {
    final groups = <LeafStage, List<LeafAssessment>>{
      for (final s in kStageOrder) s: <LeafAssessment>[],
    };
    for (final leaf in _leaves) {
      groups[leaf.stage]!.add(leaf);
    }
    final visibleStages =
        kStageOrder.where((s) => groups[s]!.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Text(
            'All leaves validated',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final stage in visibleStages)
          ValidatedGroupCard(stage: stage, leaves: groups[stage]!),
        const SizedBox(height: 20),
        _buildLogBox(),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () => setState(() => _screenState = _ScreenState.confirmation),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderGrey, width: 1),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildProceedButton(
                enabled: true,
                onPressed: _handleViewResults,
                label: 'View results',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProceedButton({bool enabled = false, VoidCallback? onPressed, String? label}) {
    final btnLabel = label ?? 'View results';
    return GestureDetector(
      onTap: enabled ? onPressed : () => _showMessage('Confirm all leaves first ($_confirmedCount/${_leaves.length})'),
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primaryGreen
              : AppColors.primaryGreen.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          btnLabel,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // Shared UI: loader + log box
  // =========================================================================

  /// Spinning double ring with a leaf in the middle.
  Widget _buildLoader() {
    return Center(
      child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(150, 150),
              painter: _BulkAssessArcPainter(_spinController),
            ),
            const Icon(Icons.eco, size: 38, color: AppColors.primaryGreen),
          ],
        ),
      ),
    );
  }

  /// Terminal-style log that scrolls by itself.
  Widget _buildLogBox() {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE3DB)),
      ),
      child: Scrollbar(
        controller: _logController,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _logController,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          itemCount: _logLines.length,
          itemBuilder: (context, index) => _buildLogLine(_logLines[index]),
        ),
      ),
    );
  }

  Widget _buildLogLine(String line) {
    Color color = AppColors.textDark;
    FontWeight weight = FontWeight.normal;

    if (line.startsWith('→')) {
      color = const Color(0xFF1C9A8F); // teal
    } else if (line.startsWith('✓')) {
      weight = FontWeight.bold;
    } else if (line.startsWith('✗')) {
      color = const Color(0xFFD32F2F);
      weight = FontWeight.bold;
    } else if (line.startsWith('checking')) {
      color = AppColors.textGrey;
    } else if (line.startsWith('🤖')) {
      weight = FontWeight.bold;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        line,
        style: TextStyle(
          fontSize: 11.5,
          fontFamily: 'monospace',
          height: 1.3,
          color: color,
          fontWeight: weight,
        ),
      ),
    );
  }

  // =========================================================================
  // Build
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // can't go back while processing
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F5F2),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Black Sigatoka Validation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 16),
                AssessmentSummaryCard(
                  plantName: 'Banana Plant #002',
                  line: widget.line,
                  isoWeek: widget.isoWeek,
                  bulkId: _bulkId,
                  status: _status,
                ),
                const SizedBox(height: 18),
                AssessmentProgressChecklist(
                  currentStepIndex: _currentStep,
                ),
                const SizedBox(height: 28),
                switch (_screenState) {
                  _ScreenState.validation => _buildValidationState(),
                  _ScreenState.confirmation => _buildConfirmationState(),
                  _ScreenState.validated => _buildValidatedState(),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pale track + two arcs of fixed length that keep spinning
/// (outer one clockwise, inner one the other way).
class _BulkAssessArcPainter extends CustomPainter {
  final Animation<double> animation;

  // "repaint" makes the painter redraw on every animation tick.
  _BulkAssessArcPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double outerRadius = size.width / 2 - 8;
    final double innerRadius = outerRadius - 18;

    // Pale cream track.
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..color = const Color(0xFFEDE5D3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Outer green arc (clockwise).
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      animation.value * 2 * pi - pi / 2,
      pi * 1.3,
      false,
      Paint()
        ..color = const Color(0xFF22A055)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Inner teal arc (the other way, a bit faster).
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      -animation.value * 2 * pi * 1.5,
      pi * 0.9,
      false,
      Paint()
        ..color = const Color(0xFF1C9A8F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
