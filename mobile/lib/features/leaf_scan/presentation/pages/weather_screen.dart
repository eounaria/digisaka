import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/components/app_bar_widget.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/features/leaf_scan/presentation/pages/spray_log_screen.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/flow_stepper5.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/metric_tile.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/status_pill.dart';
import 'package:digisaka/shared/models/fungicide_product.dart';
import 'package:digisaka/features/notification/presentation/pages/notifications_screen.dart';

/// Screen 1 of the Treatment decision flow: infection risk + weather.
///
/// Step index 1. "Disease" (= Results) is done, "Weather" is current.
/// Back pops to Results; Continue pushes [SprayLogScreen].
class WeatherScreen extends StatefulWidget {
  final String line;
  final String isoWeek;
  final List<LeafAssessment> leaves;
  final String bulkId;
  final DateTime selectedDate;

  const WeatherScreen({
    super.key,
    required this.line,
    required this.isoWeek,
    required this.leaves,
    required this.bulkId,
    required this.selectedDate,
  });

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late final TreatmentDecisionData _data;

  @override
  void initState() {
    super.initState();
    _data = TreatmentDecisionData.mockDecisionFor(widget.line, widget.isoWeek, widget.leaves);
  }

  double _markerFraction(String risk) {
    switch (risk) {
      case 'Low':
        return 0.0;
      case 'Moderate':
        return 0.5;
      case 'High':
      default:
        return 2 / 3;
    }
  }

  void _goBack() => Navigator.of(context).pop();

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SprayLogScreen(
          line: widget.line,
          isoWeek: widget.isoWeek,
          leaves: widget.leaves,
          bulkId: widget.bulkId,
          selectedDate: widget.selectedDate,
        ),
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
              FlowStepper5(currentStepIndex: 1),
              const SizedBox(height: 20),

              Row(
                children: [
                  MetricTile(label: 'RAINFALL', number: '42', caption: 'mm / 7 days'),
                  const SizedBox(width: 10),
                  MetricTile(label: 'HUMIDITY', number: '88', caption: '% average'),
                  const SizedBox(width: 10),
                  MetricTile(label: 'LEAF MOISTURE', number: '11', caption: 'hours / day'),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.borderGrey.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Sample data',
                  style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
              ),
              const SizedBox(height: 16),

              // Infection risk card.
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
                          'Infection risk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const Spacer(),
                        StatusPill(
                          label: 'Provisional',
                          background: AppColors.badgeAmberBackground,
                          text: AppColors.badgeAmberText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _data.weather.riskLevel,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB3261E),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 24,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final fraction = _markerFraction(_data.weather.riskLevel);
                          return Stack(
                            children: [
                              Container(
                                width: constraints.maxWidth,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.infectionLowBackground,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        color: AppColors.infectionLowBackground,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        color: AppColors.infectionMediumBackground,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        color: AppColors.infectionHighBackground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: (constraints.maxWidth * fraction) - 8,
                                top: -3,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryGreen,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: const Text(
                            'Low',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                          ),
                        ),
                        Expanded(
                          child: const Text(
                            'Moderate',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                          ),
                        ),
                        Expanded(
                          child: const Text(
                            'High',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB3261E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _riskDay('Mon', '2 mm'),
                    _riskDay('Tue', '8 mm'),
                    _riskDay('Wed', '12 mm'),
                    _riskDay('Thu', '0 mm'),
                    _riskDay('Fri', '10 mm'),
                    const SizedBox(height: 10),
                    Text(
                      'Next 5 days: rain on ${_data.weather.rainDays} days.',
                      style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bands are provisional, pending expert validation.',
                      style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // What is driving the risk card.
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
                      'What is driving the risk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _riskDriverRow('Rainfall 42 mm', 'Favourable'),
                    const Divider(height: 1, color: AppColors.borderGrey),
                    _riskDriverRow('Humidity 88 %', 'Favourable'),
                    const Divider(height: 1, color: AppColors.borderGrey),
                    _riskDriverRow('Leaf moisture 11 h/day', 'Favourable'),
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

  Widget _riskDay(String day, String amount) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(day, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
        const SizedBox(height: 4),
        Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ],
    );
  }

  Widget _riskDriverRow(String label, String state) {
    Color pillBg;
    Color pillText;
    switch (state) {
      case 'Favourable':
        pillBg = AppColors.infectionLowBackground;
        pillText = AppColors.infectionLowText;
      case 'Neutral':
        pillBg = AppColors.badgeGreyBackground;
        pillText = AppColors.badgeGreyText;
      case 'Unfavourable':
        pillBg = AppColors.badgeConcerningBackground;
        pillText = AppColors.badgeConcerningText;
      default:
        pillBg = AppColors.badgeGreyBackground;
        pillText = AppColors.badgeGreyText;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(label: state, background: pillBg, text: pillText),
        ],
      ),
    );
  }
}
