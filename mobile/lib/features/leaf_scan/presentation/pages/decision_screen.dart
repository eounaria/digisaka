import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/components/app_bar_widget.dart';
import 'package:digisaka/shared/models/fungicide_product.dart';
import 'package:digisaka/shared/models/history_cycle.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/shared/models/treatment_proposal.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/flow_stepper5.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/sample_data_banner.dart';
import 'package:digisaka/features/leaf_scan/presentation/pages/treatment_proposal_screen.dart';
import 'package:digisaka/features/notification/presentation/pages/notifications_screen.dart';
import 'package:digisaka/features/history/data/history_store.dart';

/// Screen 5 of the Treatment decision flow: approve/reject the treatment.
///
/// Step index 4. Steps 1-4 (Disease → Fungicides) are done, Decision is active.
/// On Approve the cycle is saved as applied and the bulk is registered with
/// ScheduleStore; on Reject it is saved as rejected. Both land on
/// [TreatmentProposalScreen] showing the approved/rejected state.
class DecisionScreen extends StatefulWidget {
  final String line;
  final String isoWeek;
  final List<LeafAssessment> leaves;
  final String bulkId;
  final DateTime selectedDate;
  final FungicideProduct selectedProduct;

  const DecisionScreen({
    super.key,
    required this.line,
    required this.isoWeek,
    required this.leaves,
    required this.bulkId,
    required this.selectedDate,
    required this.selectedProduct,
  });

  @override
  State<DecisionScreen> createState() => _DecisionScreenState();
}

class _DecisionScreenState extends State<DecisionScreen> {
  late final TreatmentDecisionData _data;

  /// 'apply' or 'reassess'.
  String _action = 'apply';

  final TextEditingController _noteController = TextEditingController();

  FungicideProduct get _product => widget.selectedProduct;

  @override
  void initState() {
    super.initState();
    _data = TreatmentDecisionData.mockDecisionFor(widget.line, widget.isoWeek, widget.leaves);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// Approve: open the schedule in the PROPOSED state so the user can review
  /// the note and decide. Nothing is persisted yet — the bulk is registered
  /// and the cycle is marked approved only when the user taps Approve on the
  /// schedule itself. Use push (not pushAndRemoveUntil) so Back returns here.
  /// Reject: mark the cycle rejected in HistoryStore and return to Results.
  void _decide(TreatmentProposalStatus status) {
    if (status == TreatmentProposalStatus.approved && _action == 'reassess') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select Apply to approve.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    if (status == TreatmentProposalStatus.approved) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TreatmentProposalScreen(
            leaves: widget.leaves,
            bulkId: widget.bulkId,
            line: widget.line,
            isoWeek: widget.isoWeek,
            selectedProduct: _product,
            selectedDate: widget.selectedDate,
            note: _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : null,
          ),
        ),
      );
    } else {
      HistoryStore.instance.upsertCycle(
        HistoryCycle(
          line: widget.line,
          isoWeek: widget.isoWeek,
          bulkId: widget.bulkId,
          leaves: widget.leaves,
          status: HistoryStatus.rejected,
          windowStart: DateTime(2026, 6, 15),
          windowEnd: DateTime(2026, 6, 17),
        ),
      );
      Navigator.of(context).popUntil(
        (route) => route.isFirst || route.settings.name == 'results',
      );
    }
  }

  Widget _chip(String label, {required bool selected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.selectedChipBackground : AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? AppColors.primaryGreen : AppColors.borderGrey,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: selected ? AppColors.primaryGreen : AppColors.textDark,
        ),
      ),
    );
  }

  Widget _actionRow(String label, String value, {bool selected = false}) {
    return GestureDetector(
      onTap: () => setState(() => _action = value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.infectionLowBackground : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : AppColors.borderGrey,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primaryGreen : AppColors.borderGrey,
                  width: 2,
                ),
              ),
              child: selected
                  ? const DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGreen,
                      ),
                      child: SizedBox(width: 10, height: 10),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? AppColors.textDark : AppColors.textGrey,
                ),
              ),
            ),
          ],
        ),
      ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Decision',
        onNotificationsPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        ),
      ),
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FlowStepper5(currentStepIndex: 4),
              const SizedBox(height: 12),
              const SampleDataBanner(),
              const SizedBox(height: 20),

              // Recommended action.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderGrey, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECOMMENDED ACTION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip('Preventive', selected: true),
                        _chip('Mechanical', selected: true),
                        _chip('Provisional', selected: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _actionRow('Apply', 'apply', selected: _action == 'apply'),
                    const SizedBox(height: 8),
                    _actionRow('Reassess', 'reassess', selected: _action == 'reassess'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Selected product.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderGrey, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'SELECTED PRODUCT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _product.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _product.formulation,
                      style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 12),
                    _specRow('FRAC · mode', '${_product.fracCode} · ${_product.mode}'),
                    _specRow('Rate', _product.rate),
                    _specRow('Rainfast · interval', '${_product.rainfast} · ${_product.interval}'),
                    _specRow('Price', '₱${_product.price.toStringAsFixed(0)} ${_product.priceUnit}'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.badgeAmberBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _data.recommended.caution ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.badgeAmberText,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Why this product.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderGrey, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WHY THIS PRODUCT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _data.recommended.reason,
                      style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Note.
              const Text(
                'Note (optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGrey, width: 1),
                ),
                child: TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Add a note about this decision…',
                    hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textGrey),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                ),
              ),
              const SizedBox(height: 20),

              // Reject + Approve side by side.
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _decide(TreatmentProposalStatus.rejected),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFB3261E),
                            width: 1.5,
                          ),
                        ),
                        child: const Text(
                          'Reject',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB3261E),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _decide(TreatmentProposalStatus.approved),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFF22A055), AppColors.darkGreen],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Approve',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'AI-assisted scheduling should be verified by an agricultural '
                'specialist before treatment decisions.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _specRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      );
}
