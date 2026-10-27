import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/features/leaf_scan/domain/bulk_helpers.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/bulk_assessment_summary_card.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/bulk_assessment_agent_checklist.dart';
import 'package:digisaka/features/leaf_scan/presentation/pages/bulk_result_screen.dart';

class BlackSigatokaValidationScreen extends StatefulWidget {
  final int leafCount;
  final List<File?>? leafPhotos;

  const BlackSigatokaValidationScreen({
    super.key,
    required this.leafCount,
    this.leafPhotos,
  });

  @override
  State<BlackSigatokaValidationScreen> createState() =>
      _BlackSigatokaValidationScreenState();
}

class _BlackSigatokaValidationScreenState
    extends State<BlackSigatokaValidationScreen>
    with SingleTickerProviderStateMixin {
  late final List<LeafAssessment> _leaves;
  late final AnimationController _spinController;
  final ScrollController _logController = ScrollController();
  final String _bulkId = generateBulkId();

  String _status = 'Validating...';
  int _currentStep = 2; // 2 = "Black Sigatoka Validation"
  final List<String> _logLines = [];

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
        _addLog('✓ $tag complete — routed to: Healthy / Stage 0');
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

    if (!await _wait(700)) return;
    setState(() => _status = 'Validated — Grouped by Stage');

    if (!await _wait(800)) return;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BulkAssessmentResultScreen(
          leaves: _leaves,
          bulkId: _bulkId,
        ),
      ),
    );
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
                BulkAssessmentSummaryCard(
                  plantName: 'Banana Plant #002',
                  bulkId: _bulkId,
                  status: _status,
                ),
                const SizedBox(height: 18),
                BulkAssessmentAgentChecklist(
                  currentStepIndex: _currentStep,
                ),
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
            ),
          ),
        ),
      ),
    );
  }

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
              painter: _ValidationArcPainter(_spinController),
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
}

/// Pale track + two arcs of fixed length that keep spinning
/// (outer one clockwise, inner one the other way).
class _ValidationArcPainter extends CustomPainter {
  final Animation<double> animation;

  // "repaint" makes the painter redraw on every animation tick.
  _ValidationArcPainter(this.animation) : super(repaint: animation);

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