import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/components/app_bar_widget.dart';
import 'package:digisaka/shared/models/fungicide_product.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/flow_stepper5.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/sample_data_banner.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/status_pill.dart';
import 'package:digisaka/features/leaf_scan/presentation/pages/decision_screen.dart';
import 'package:digisaka/features/notification/presentation/pages/notifications_screen.dart';

/// Product detail page for a fungicide option, shown at step index 3 (Fungicides).
///
/// Displays product identity, classification, resistance/eligibility and
/// evidence across four tabs. "Use this product" pushes [DecisionScreen] with
/// this product as the selected pick.
class ProductDetailsScreen extends StatefulWidget {
  final String line;
  final String isoWeek;
  final List<LeafAssessment> leaves;
  final String bulkId;
  final DateTime selectedDate;
  final FungicideProduct product;

  const ProductDetailsScreen({
    super.key,
    required this.line,
    required this.isoWeek,
    required this.leaves,
    required this.bulkId,
    required this.selectedDate,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  static const List<String> _kTabs = <String>[
    'Product',
    'Efficacy & use',
    'Resistance',
    'Evidence',
  ];

  int _tabIndex = 0;

  FungicideProduct get _p => widget.product;

  /// True when this product's FRAC group is restricted for this line/week.
  bool get _isRestricted =>
      _p.fracCode == '3' || _p.fracCode == '11';

  void _goBack() => Navigator.of(context).pop();

  void _useProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DecisionScreen(
          line: widget.line,
          isoWeek: widget.isoWeek,
          leaves: widget.leaves,
          bulkId: widget.bulkId,
          selectedDate: widget.selectedDate,
          selectedProduct: widget.product,
        ),
      ),
    );
  }

  Widget _tab(String label, int index) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primaryGreen : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? AppColors.primaryGreen : AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderGrey, width: 1),
        ),
        child: child,
      );

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

  Widget _eligibilityRow(String label, Widget pill) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
            const Spacer(),
            pill,
          ],
        ),
      );

  StatusPill _pill(String label, Color background, Color text) =>
      StatusPill(label: label, background: background, text: text);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Treatment Product',
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

              // Product header card.
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _p.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _p.formulation,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₱${_p.price.toStringAsFixed(0)} ${_p.priceUnit}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_p.manufacturer != null)
                      Text(
                        'By ${_p.manufacturer}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tabs.
              Row(
                children: [
                  _tab(_kTabs[0], 0),
                  _tab(_kTabs[1], 1),
                  _tab(_kTabs[2], 2),
                  _tab(_kTabs[3], 3),
                ],
              ),
              const SizedBox(height: 16),

              // Tab content.
              switch (_tabIndex) {
                0 => _productCard(),
                1 => _classificationCard(),
                2 => _resistanceCard(),
                _ => _evidenceCard(),
              },
              const SizedBox(height: 24),

              // Bottom: Back + Use this product.
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
                      onTap: _useProduct,
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
                          'Use this product',
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

  /// Card 1 (Product tab): name, manufacturer, formulation, price.
  Widget _productCard() => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            _specRow('Name', _p.name),
            _specRow('Manufacturer', _p.manufacturer ?? '—'),
            _specRow('Formulation', _p.formulation),
            _specRow('Price', '₱${_p.price.toStringAsFixed(0)} ${_p.priceUnit}'),
          ],
        ),
      );

  /// Card 2 (Efficacy & use tab): identity & classification rows with dividers.
  Widget _classificationCard() => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Identity & classification',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            _specRow('Active ingredient', _p.activeIngredient),
            const Divider(height: 1, color: AppColors.borderGrey),
            _specRow('Chemical group', _p.chemicalGroup),
            const Divider(height: 1, color: AppColors.borderGrey),
            _specRow('Mode of action', _p.mode),
            const Divider(height: 1, color: AppColors.borderGrey),
            _specRow('Mobility', _p.mobility),
            const Divider(height: 1, color: AppColors.borderGrey),
            _specRow('Rate', _p.rate),
            const Divider(height: 1, color: AppColors.borderGrey),
            _specRow('Rainfast', _p.rainfast),
            const Divider(height: 1, color: AppColors.borderGrey),
            _specRow('Interval', _p.interval),
          ],
        ),
      );

  /// Card 3 (Resistance tab): eligibility checks with red/amber/green pills.
  Widget _resistanceCard() => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resistance & eligibility',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            _eligibilityRow(
              'FRAC group',
              _isRestricted
                  ? _pill('Restricted', const Color(0xFFFDECEA), const Color(0xFFB3261E))
                  : _pill('OK', AppColors.infectionLowBackground, AppColors.infectionLowText),
            ),
            const Divider(height: 1, color: AppColors.borderGrey),
            _eligibilityRow(
              'Mode of action',
              _pill(
                _p.mode,
                _p.mode == 'Contact'
                    ? AppColors.infectionLowBackground
                    : AppColors.badgeAmberBackground,
                _p.mode == 'Contact'
                    ? AppColors.infectionLowText
                    : AppColors.badgeAmberText,
              ),
            ),
            const Divider(height: 1, color: AppColors.borderGrey),
            _eligibilityRow(
              'Resistance risk',
              _pill(
                _isRestricted ? 'High' : 'Low',
                _isRestricted
                    ? const Color(0xFFFDECEA)
                    : AppColors.infectionLowBackground,
                _isRestricted
                    ? const Color(0xFFB3261E)
                    : AppColors.infectionLowText,
              ),
            ),
          ],
        ),
      );

  /// Evidence tab: why this product is recommended / supported.
  Widget _evidenceCard() => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Efficacy evidence',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Recommended for this line and week based on leaf stage, '
              'infection risk and recent spray history.',
              style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4),
            ),
            const SizedBox(height: 12),
            if (_p.badges.isNotEmpty) ...[
              const Text(
                'Badges',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _p.badges
                    .map((b) => _pill(b, AppColors.badgeAmberBackground, AppColors.badgeAmberText))
                    .toList(),
              ),
            ],
          ],
        ),
      );
}
