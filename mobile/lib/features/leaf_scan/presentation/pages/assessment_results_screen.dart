import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/shared/widgets/assessment_stepper.dart';
import 'package:digisaka/shared/components/app_bar_widget.dart';
import 'package:digisaka/features/notification/presentation/pages/notifications_screen.dart';
import 'package:digisaka/features/leaf_scan/presentation/pages/weather_screen.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/leaf_photo_dialog.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/results_group_section.dart';

/// Screen showing the bulk assessment result, ready for a treatment proposal.
///
/// Rebuilt per the Figma "Bulk Assessment Result" frame: title, stepper at
/// index 2, a bulk card grouping leaves by stage in 2-column grids, a proposal
/// card that opens [TreatmentHistoryScreen], and a disabled Back / New scan row.
class AssessmentResultsScreen extends StatefulWidget {
  final List<LeafAssessment> leaves;
  final String bulkId;
  final String line;
  final String isoWeek;
  final DateTime selectedDate;

  const AssessmentResultsScreen({
    super.key,
    required this.leaves,
    required this.bulkId,
    required this.line,
    required this.isoWeek,
    required this.selectedDate,
  });

  @override
  State<AssessmentResultsScreen> createState() => _AssessmentResultsScreenState();
}

class _AssessmentResultsScreenState extends State<AssessmentResultsScreen> {
  late final List<LeafAssessment> _leaves;
  late final Map<LeafStage, List<LeafAssessment>> _groups;
  late final List<LeafStage> _visibleStages;

  bool get _hasTreatmentLeaves => _leaves.any((l) => l.stage.isTreatment);

  @override
  void initState() {
    super.initState();
    _leaves = List.of(widget.leaves);
    _groups = {for (final s in kStageOrder) s: <LeafAssessment>[]};
    for (final leaf in _leaves) {
      _groups[leaf.stage]!.add(leaf);
    }
    _visibleStages = kStageOrder.where((s) => _groups[s]!.isNotEmpty).toList();
  }

  void _goToNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  /// Open proposal -> WeatherScreen (step 1 of the treatment decision flow).
  void _openProposal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeatherScreen(
          leaves: _leaves,
          bulkId: widget.bulkId,
          line: widget.line,
          isoWeek: widget.isoWeek,
          selectedDate: widget.selectedDate,
        ),
      ),
    );
  }

  void _newScan() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Card 1: "Leaves in this Bulk" — per-stage label + count badge, then a
  /// 2-column grid of leaf tiles, with a thin divider between stage groups.
  Widget _buildBulkCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mockLeafTileBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Leaves in this Bulk',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              const Spacer(),
              Text(
                '${_leaves.length} leaves',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < _visibleStages.length; i++)
            ..._buildStageSection(_visibleStages[i], i == 0),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.textGrey, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This is an AI-assisted assessment and not a confirmed diagnosis. '
                  'Results should be verified by an agricultural specialist before treatment decisions.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// One stage section inside the bulk card: label + count badge, then a
  /// 2-column grid of leaf tiles built from Rows (not GridView).
  /// [isFirst] is true when this is the first stage block, so no divider
  /// is rendered above it.
  List<Widget> _buildStageSection(LeafStage stage, bool isFirst) {
    final stageLeaves = _groups[stage]!;
    final tileRows = <Widget>[];

    // Split leaves into pairs, one Row per pair.
    for (var i = 0; i < stageLeaves.length; i += 2) {
      final a = stageLeaves[i];
      final b = i + 1 < stageLeaves.length ? stageLeaves[i + 1] : null;
      tileRows.add(
        Row(
          children: [
            Expanded(
              child: ResultLeafTile(
                leaf: a,
                onView: () => showLeafPhotoDialog(context, a),
              ),
            ),
            if (b != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: ResultLeafTile(
                  leaf: b,
                  onView: () => showLeafPhotoDialog(context, b),
                ),
              ),
            ],
          ],
        ),
      );
      if (i + 2 < stageLeaves.length) {
        tileRows.add(const SizedBox(height: 10));
      }
    }

    return <Widget>[
      if (!isFirst)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(height: 1, color: AppColors.borderGrey),
        ),
      Row(
        children: [
          Text(
            stage.stageName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.mockLeafTileBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: stage.borderColor, width: 1),
            ),
            child: Text(
              '${stageLeaves.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: stage.borderColor,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      ...tileRows,
    ];
  }

  /// Card 2: "A treatment proposal is ready" + "Open proposal →", or a
  /// "No treatment proposal needed" message when no leaf needs treatment.
  Widget _buildProposalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey, width: 1),
      ),
      child: Column(
        children: [
          const Text(
            'A treatment proposal is ready',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_hasTreatmentLeaves)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: GestureDetector(
                onTap: _openProposal,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF22A055), AppColors.darkGreen],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Open proposal →',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            )
          else
            const Text(
              'No treatment proposal needed',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  /// Bottom row: disabled "← Back" (light fill) + "+ New scan" (outlined).
  Widget _buildBottomRow() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.placeholderFieldFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderGrey, width: 1),
            ),
            child: const Text(
              '← Back',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textGrey,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: _newScan,
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderGrey, width: 1),
              ),
              child: const Text(
                '+ New scan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                'Bulk Assessment Result',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              const AssessmentStepper(currentStepIndex: 2),
              const SizedBox(height: 20),
              _buildBulkCard(),
              const SizedBox(height: 18),
              _buildProposalCard(),
              const SizedBox(height: 24),
              _buildBottomRow(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
