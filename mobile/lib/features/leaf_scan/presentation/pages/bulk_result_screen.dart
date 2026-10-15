import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/features/leaf_scan/domain/bulk_helpers.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/bulk_assessment_agent_checklist.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/bulk_assessment_summary_card.dart';
import 'package:digisaka/shared/widgets/stage_dot.dart';
import 'package:digisaka/shared/widgets/dashed_rrect_painter.dart';
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

class _BulkAssessmentResultScreenState
    extends State<BulkAssessmentResultScreen> {
  late final List<LeafAssessment> _leaves;
  final String _date = getAssessmentDate();

  @override
  void initState() {
    super.initState();
    _leaves = List.of(widget.leaves);
  }

  // ---------- data helpers ----------

  /// Leaves grouped by stage, always in the fixed display order.
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

  /// Leaves in Stage 1-4, sorted by leaf number.
  List<LeafAssessment> get _treatmentLeaves {
    final list = _leaves.where((l) => l.stage.isTreatment).toList();
    list.sort((a, b) => a.number.compareTo(b.number));
    return list;
  }

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

  void _handleReview() {
    if (!_allConfirmed) {
      _showMessage('Confirm all leaves first ($_confirmedCount/${_leaves.length})');
      return;
    }
    // Navigate to the Treatment Recommendation step.
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
      backgroundColor: const Color(0xFFF3F5F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bulk Assessment Result',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Confirm — or reassign — each leaf's AI-suggested stage below before continuing.",
                style: TextStyle(fontSize: 13.5, color: AppColors.textGrey, height: 1.4),
              ),
              const SizedBox(height: 16),

              BulkAssessmentSummaryCard(
                plantName: 'Banana Plant #002',
                bulkId: widget.bulkId,
                status: 'Validated — Grouped by Stage',
                assessmentDate: _date,
              ),
              const SizedBox(height: 18),

              BulkAssessmentAgentChecklist(
                bulkId: widget.bulkId,
                currentStepIndex: 5, // Human Verification
              ),
              const SizedBox(height: 26),

              // Big leaf count.
              Center(
                child: Column(
                  children: [
                    Text(
                      '${_leaves.length}',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const Text(
                      'Leaves in this Bulk',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (visibleStages.length >= 2) _buildInfoBanner(),
              if (visibleStages.length >= 2) const SizedBox(height: 14),

              _buildVerificationCard(),
              const SizedBox(height: 16),

              for (final stage in visibleStages)
                _buildGroupCard(stage, groups[stage]!),

              if (_treatmentLeaves.isNotEmpty) _buildTreatmentSection(),

              const SizedBox(height: 8),
              _buildReviewButton(),
              const SizedBox(height: 22),

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

  /// Green-grey banner: "Bulk contains multiple ... groups".
  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3EDE5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '📊 Bulk contains multiple Black Sigatoka assessment groups — see breakdown below.',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryGreen,
          height: 1.35,
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
        color: const Color(0xFFF8F0D6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0DFA0)),
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
    final bool isUnvalidated = stage == LeafStage.unvalidated;

    final Widget card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnvalidated ? const Color(0xFFEDEFEB) : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        // Healthy: no border. Stage 1-4: light red border.
        border: stage.isTreatment
            ? Border.all(color: const Color(0xFFF3B5B5))
            : null,
        boxShadow: isUnvalidated
            ? null
            : [
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
              StageDot(stage: stage),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stage.stageName,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: isUnvalidated ? AppColors.textGrey : AppColors.textDark,
                  ),
                ),
              ),
              Text(
                '${leaves.length} ${leaves.length == 1 ? 'leaf' : 'leaves'}',
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
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey, height: 1.35),
          ),
          const SizedBox(height: 12),
          for (final leaf in leaves) _buildLeafRow(leaf),
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

  /// One leaf: info on the left, Confirm + "Move to..." on the right.
  Widget _buildLeafRow(LeafAssessment leaf) {
    final bool done = leaf.confirmed;
    final String number = leaf.number.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFE3F3E6) : const Color(0xFFF1F3EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done ? const Color(0xFF8FCFA0) : const Color(0xFFDDE3DB),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📷 Leaf $number',
                  style: const TextStyle(
                    fontSize: 13.5,
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
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildConfirmButton(leaf),
          const SizedBox(width: 6),
          _buildMoveMenu(leaf),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(LeafAssessment leaf) {
    final bool done = leaf.confirmed;

    return GestureDetector(
      onTap: () => _toggleConfirm(leaf),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: done ? const Color(0xFF22A055) : AppColors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          done ? '✓ Confirmed' : 'Confirm',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: done ? AppColors.white : AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }

  /// Looks like a dropdown, but uses a popup menu so the long
  /// option names are never cut off. The leaf's own group is not listed.
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
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDE3DB)),
        ),
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

  /// Red heading + one card per leaf in Stage 1-4.
  Widget _buildTreatmentSection() {
    final leaves = _treatmentLeaves;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔶 Treatment Consideration — ${leaves.length} '
            '${leaves.length == 1 ? 'leaf requires' : 'leaves require'} treatment-window review',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD32F2F),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          for (final leaf in leaves) _buildTreatmentCard(leaf),
        ],
      ),
    );
  }

  /// White card with a red bar on the left.
  /// (A one-sided border can't have rounded corners in Flutter,
  /// so the red bar is its own piece inside a clipped card.)
  Widget _buildTreatmentCard(LeafAssessment leaf) {
    final String number = leaf.number.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: AppColors.white,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: const Color(0xFFD32F2F)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        StageDot(stage: leaf.stage, size: 18),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Leaf $number — ${leaf.stage.stageName}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Green gradient button. Faded until every leaf is confirmed,
  /// but always tappable (it tells you what's missing).
  Widget _buildReviewButton() {
    return Opacity(
      opacity: _allConfirmed ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: _handleReview,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF22A055), AppColors.darkGreen],
            ),
          ),
          child: const Text(
            'Review Black Sigatoka Groups →',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}