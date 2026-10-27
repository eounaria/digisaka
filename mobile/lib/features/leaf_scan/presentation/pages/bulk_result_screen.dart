import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/bulk_assessment_agent_checklist.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/bulk_assessment_summary_card.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/leaf_photo_dialog.dart';
import 'package:digisaka/shared/components/app_bar_widget.dart';
import 'package:digisaka/shared/widgets/assessment_stepper.dart';
import 'package:digisaka/shared/widgets/dashed_rrect_painter.dart';
import 'package:digisaka/shared/widgets/stage_dot.dart';
import 'package:digisaka/features/notification/presentation/pages/notifications_screen.dart';
import 'treatment_recommendation_screen.dart';

class BulkAssessmentResultScreen extends StatefulWidget {
  final List<LeafAssessment> leaves;
  final String bulkId;

  const BulkAssessmentResultScreen({
    super.key,
    required this.leaves,
    required this.bulkId,
  });

  @override
  State<BulkAssessmentResultScreen> createState() =>
      _BulkAssessmentResultScreenState();
}

class _BulkAssessmentResultScreenState extends State<BulkAssessmentResultScreen> {
  late final List<LeafAssessment> _leaves;

  @override
  void initState() {
    super.initState();
    _leaves = List.of(widget.leaves);
  }

  // ---------- data helpers ----------

  Map<LeafStage, List<LeafAssessment>> get _groups {
    final map = <LeafStage, List<LeafAssessment>>{
      for (final s in kStageOrder) s: <LeafAssessment>[],
    };
    for (final leaf in _leaves) {
      map[leaf.stage]!.add(leaf);
    }
    return map;
  }

  int get _confirmedCount => _leaves.where((l) => l.confirmed).length;

  bool get _allConfirmed => _confirmedCount == _leaves.length;

  String get _status => _allConfirmed ? 'All leaves confirmed' : 'Waiting for your confirmation';

  void _toggleConfirm(LeafAssessment leaf) {
    setState(() => leaf.confirmed = !leaf.confirmed);
  }

  /// Moving a leaf = a human decision, so it also counts as confirmed.
  void _moveLeaf(LeafAssessment leaf, LeafStage newStage) {
    setState(() {
      leaf.stage = newStage;
      leaf.confirmed = true;
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _goToNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _handleReview() {
    if (!_allConfirmed) {
      _showMessage('Confirm all leaves first ($_confirmedCount/${_leaves.length})');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TreatmentRecommendationScreen(
          leaves: _leaves,
          bulkId: widget.bulkId,
        ),
      ),
    );
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    final List<LeafStage> visibleStages =
        kStageOrder.where((s) => groups[s]!.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Leaf Scan',
        onNotificationsPressed: _goToNotifications,
      ),
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 6),
              const Text(
                'Confirm — or reassign — each leaf\'s AI-suggested stage below before continuing.',
                style: TextStyle(fontSize: 13.5, color: AppColors.textGrey, height: 1.4),
              ),
              const SizedBox(height: 16),
              AssessmentStepper(currentStepIndex: 1),
              const SizedBox(height: 16),
              BulkAssessmentSummaryCard(
                line: 'L04',
                isoWeek: '2026-W24',
                bulkId: widget.bulkId,
                status: _status,
                // TODO: wire real line/week from the user's selection; demo values for now.
              ),
              const SizedBox(height: 18),
              BulkAssessmentAgentChecklist(currentStepIndex: 5),
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
              _buildVerificationCard(),
              const SizedBox(height: 14),
              for (final stage in visibleStages)
                _buildGroupCard(stage, groups[stage]!),
              const SizedBox(height: 20),
              _buildLogBox(),
              const SizedBox(height: 16),
              _buildBottomButtons(),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'This is an AI-assisted assessment and not a confirmed diagnosis. '
                  'Results should be verified by an agricultural specialist before treatment decisions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Yellow "Human Verification Required" card with the live counter.
  Widget _buildVerificationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.verificationCardFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.verificationCardBorder),
      ),
      child: Row(
        children: [
          const Text('🧑‍🌾', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Human Verification Required',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Check each leaf below. Confirm the AI\'s stage, or use "Move to..." if it belongs in a different group.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textGrey, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$_confirmedCount/${_leaves.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  /// One white card per group: header, description, then its leaf rows.
  Widget _buildGroupCard(LeafStage stage, List<LeafAssessment> leaves) {
    final isUnvalidated = stage == LeafStage.unvalidated;
    final sorted = [...leaves]..sort((a, b) => a.number.compareTo(b.number));

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnvalidated ? AppColors.unvalidatedCardFill : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: isUnvalidated
            ? null
            : Border.all(color: stage.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StageDot(stage: stage, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stage.stageName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isUnvalidated ? AppColors.textGrey : AppColors.textDark,
                  ),
                ),
              ),
              Text(
                '${sorted.length} ${sorted.length == 1 ? 'leaf' : 'leaves'}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stage.description,
            style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.35),
          ),
          const SizedBox(height: 12),
          for (final leaf in sorted) _buildLeafRow(leaf),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: isUnvalidated
          ? CustomPaint(foregroundPainter: const DashedRRectPainter(), child: card)
          : card,
    );
  }

  /// One leaf row: eye icon + info on the left, Confirm + Move to… on the right.
  /// Single-line when wide enough; stacked otherwise.
  Widget _buildLeafRow(LeafAssessment leaf) {
    final done = leaf.confirmed;
    final number = leaf.number.toString().padLeft(2, '0');

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 300;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: done ? AppColors.leafRowConfirmedFill : AppColors.leafRowFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: done ? AppColors.leafRowConfirmedBorder : AppColors.leafRowBorder,
              width: 1,
            ),
          ),
          child: wide
              ? _buildLeafRowInline(leaf, done, number)
              : _buildLeafRowStacked(leaf, done, number),
        );
      },
    );
  }

  Widget _buildLeafRowInline(LeafAssessment leaf, bool done, String number) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildEyeButton(leaf),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Leaf $number',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                leaf.confidence == null
                    ? 'No confidence score (unvalidated)'
                    : 'AI confidence: ${leaf.confidence!.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _buildConfirmButton(leaf, done),
        const SizedBox(width: 6),
        _buildMoveMenu(leaf),
      ],
    );
  }

  Widget _buildLeafRowStacked(LeafAssessment leaf, bool done, String number) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildEyeButton(leaf),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Leaf $number',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    leaf.confidence == null
                        ? 'No confidence score (unvalidated)'
                        : 'AI confidence: ${leaf.confidence!.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildConfirmButton(leaf, done)),
            const SizedBox(width: 6),
            Expanded(child: _buildMoveMenu(leaf)),
          ],
        ),
      ],
    );
  }

  /// Eye icon: opens the zoomable photo dialog for this leaf.
  Widget _buildEyeButton(LeafAssessment leaf) {
    final number = leaf.number.toString().padLeft(2, '0');
    return Semantics(
      label: 'View photo of Leaf $number',
      button: true,
      child: GestureDetector(
        onTap: () => showLeafPhotoDialog(context, leaf),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.leafRowConfirmedFill,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.visibility_outlined,
            color: AppColors.primaryGreen,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// "Confirm" / "✓ Confirmed" pill.
  Widget _buildConfirmButton(LeafAssessment leaf, bool done) {
    return GestureDetector(
      onTap: () => _toggleConfirm(leaf),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: done ? AppColors.primaryGreen : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: done ? AppColors.primaryGreen : AppColors.leafRowBorder,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          done ? '✓ Confirmed' : 'Confirm',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: done ? AppColors.white : AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }

  /// "Move to…" dropdown. The leaf's own group is excluded.
  Widget _buildMoveMenu(LeafAssessment leaf) {
    return PopupMenuButton<LeafStage>(
      tooltip: '',
      padding: EdgeInsets.zero,
      color: AppColors.white,
      onSelected: (stage) => _moveLeaf(leaf, stage),
      itemBuilder: (context) => [
        for (final stage in kMoveOptions)
          if (stage != leaf.stage)
            PopupMenuItem<LeafStage>(
              value: stage,
              child: Text(
                stage.stageName,
                style: const TextStyle(fontSize: 13, color: AppColors.textDark),
              ),
            ),
      ],
      child: Container(
        width: 110,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.leafRowBorder, width: 1),
        ),
        alignment: Alignment.center,
        child: const Row(
          children: [
            Expanded(
              child: Text(
                'Move to…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textDark),
          ],
        ),
      ),
    );
  }

  /// Agent log: one monospace line per leaf, sorted by number, rebuilt live on confirm.
  Widget _buildLogBox() {
    final sorted = [..._leaves]..sort((a, b) => a.number.compareTo(b.number));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.placeholderFieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...sorted.map((leaf) => _buildLogLine(leaf)),
        ],
      ),
    );
  }

  Widget _buildLogLine(LeafAssessment leaf) {
    final number = leaf.number.toString().padLeft(2, '0');
    final confirmed = leaf.confirmed;
    final prefix = confirmed ? '✓ ' : '';
    final text = switch (leaf.stage) {
      LeafStage.healthy => 'Leaf $number — Healthy',
      LeafStage.unvalidated => 'Leaf $number — Unvalidated, review required',
      _ => 'Leaf $number — ${leaf.stage.stageName}${confirmed ? '' : ', waiting for your confirmation'}',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$prefix$text',
        style: const TextStyle(
          fontSize: 11.5,
          fontFamily: 'monospace',
          height: 1.3,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  /// Bottom row: Back (outlined, ~1/3) + View results (filled, ~2/3, faded until all confirmed).
  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(flex: 1, child: _buildBackButton()),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _buildViewResultsButton()),
      ],
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGrey, width: 1),
        ),
        child: const Text(
          'Back',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildViewResultsButton() {
    return GestureDetector(
      onTap: _handleReview,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _allConfirmed
              ? AppColors.primaryGreen
              : AppColors.primaryGreen.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'View results',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
