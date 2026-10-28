import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/components/app_bar_widget.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/flow_stepper5.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/sample_data_banner.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/status_pill.dart';
import 'package:digisaka/features/leaf_scan/presentation/pages/product_details_screen.dart';
import 'package:digisaka/features/leaf_scan/presentation/pages/decision_screen.dart';
import 'package:digisaka/shared/models/fungicide_product.dart';
import 'package:digisaka/features/notification/presentation/pages/notifications_screen.dart';

/// Screen 4 of the Treatment decision flow: fungicide options.
///
/// Step index 3. "Details ›" on a product opens [ProductDetailsScreen];
/// Continue uses the recommended top pick and pushes [DecisionScreen].
class FungicideOptionsScreen extends StatefulWidget {
  final String line;
  final String isoWeek;
  final List<LeafAssessment> leaves;
  final String bulkId;
  final DateTime selectedDate;

  const FungicideOptionsScreen({
    super.key,
    required this.line,
    required this.isoWeek,
    required this.leaves,
    required this.bulkId,
    required this.selectedDate,
  });

  @override
  State<FungicideOptionsScreen> createState() => _FungicideOptionsScreenState();
}

class _FungicideOptionsScreenState extends State<FungicideOptionsScreen> {
  late final TreatmentDecisionData _data;

  @override
  void initState() {
    super.initState();
    _data = TreatmentDecisionData.mockDecisionFor(widget.line, widget.isoWeek, widget.leaves);
  }

  FungicideProduct get _topPick => _data.recommended.products.first;

  void _goBack() => Navigator.of(context).pop();

  void _openDetails(FungicideProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          line: widget.line,
          isoWeek: widget.isoWeek,
          leaves: widget.leaves,
          bulkId: widget.bulkId,
          selectedDate: widget.selectedDate,
          product: product,
        ),
      ),
    );
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DecisionScreen(
          line: widget.line,
          isoWeek: widget.isoWeek,
          leaves: widget.leaves,
          bulkId: widget.bulkId,
          selectedDate: widget.selectedDate,
          selectedProduct: _topPick,
        ),
      ),
    );
  }

  Widget _chip(String label, {required bool selected, IconData? icon}) {
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.primaryGreen),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: selected ? AppColors.primaryGreen : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Leaf Scan',
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
              FlowStepper5(currentStepIndex: 3),
              const SizedBox(height: 12),
              const SampleDataBanner(),
              const SizedBox(height: 20),

              // Recommended action card.
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
                          'RECOMMENDED ACTION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip('Preventive', selected: true, icon: Icons.check),
                        _chip('Mechanical', selected: true, icon: Icons.check),
                        _chip('Treatment', selected: false),
                        _chip('Monitor', selected: false),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _data.recommended.reason,
                      style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 10),
                    StatusPill(
                      label: 'Provisional threshold',
                      background: AppColors.badgeAmberBackground,
                      text: AppColors.badgeAmberText,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Options header row.
              Row(
                children: [
                  const Text(
                    'Fungicide options',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '2 eligible · 3 excluded',
                    style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Recommended card (green outline).
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primaryGreen, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: const Text(
                            'Recommended combination',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        StatusPill(
                          label: 'Recommended',
                          background: AppColors.infectionLowBackground,
                          text: AppColors.infectionLowText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final product in _data.recommended.products)
                      _productRow(product),
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

              // Eligible card (grey outline).
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
                        Expanded(
                          child: const Text(
                            'Chlorothalonil 720 SC',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        StatusPill(
                          label: 'Eligible',
                          background: AppColors.infectionLowBackground,
                          text: AppColors.infectionLowText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'FRAC M05 · Contact · Multi-site',
                      style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          '₱1,780 per L',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _openDetails(
                            _data.eligible.first.products.isNotEmpty
                                ? _data.eligible.first.products.first
                                : _topPick,
                          ),
                          child: const Text(
                            'Details ›',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Color(0xFFB3261E),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _data.eligible.first.priceConcern ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Excluded card.
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
                          '3 excluded',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _showExcludedBottomSheet,
                          child: const Text(
                            'Show why ›',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _data.excluded.first.reason,
                      style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _goBack,
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderGrey, width: 1),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _continue,
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
                          'Continue',
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productRow(FungicideProduct product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.formulation,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.price.toStringAsFixed(0)} ${product.priceUnit}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _openDetails(product),
              child: const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Details ›',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExcludedBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why excluded',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _data.excluded.first.reason,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB3261E),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
