import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/components/app_bar_widget.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/flow_stepper5.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/spray_timeline.dart';
import 'package:digisaka/features/leaf_scan/presentation/pages/fungicide_options_screen.dart';
import 'package:digisaka/shared/models/fungicide_product.dart';
import 'package:digisaka/features/notification/presentation/pages/notifications_screen.dart';

/// Screen 3 of the Treatment decision flow: spray history timeline.
///
/// Step index 2. Back pops to Weather; Continue pushes [FungicideOptionsScreen].
class SprayLogScreen extends StatefulWidget {
  final String line;
  final String isoWeek;
  final List<LeafAssessment> leaves;
  final String bulkId;
  final DateTime selectedDate;

  const SprayLogScreen({
    super.key,
    required this.line,
    required this.isoWeek,
    required this.leaves,
    required this.bulkId,
    required this.selectedDate,
  });

  @override
  State<SprayLogScreen> createState() => _SprayLogScreenState();
}

class _SprayLogScreenState extends State<SprayLogScreen> {
  late final TreatmentDecisionData _data;

  @override
  void initState() {
    super.initState();
    _data = TreatmentDecisionData.mockDecisionFor(widget.line, widget.isoWeek, widget.leaves);
  }

  void _goBack() => Navigator.of(context).pop();

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FungicideOptionsScreen(
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
    final entries = _sprayEntries;

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
              FlowStepper5(currentStepIndex: 2),
              const SizedBox(height: 20),

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
                      'Spray history',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rotate FRAC groups to slow resistance',
                      style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 16),
                    SprayTimeline(entries: entries),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Restricted FRAC groups card (red outline).
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD94A5A), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Restricted FRAC groups',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final group in _data.restrictedFracGroups)
                      _restrictedRow(group),
                    const SizedBox(height: 8),
                    Text(
                      'Blocked from today\'s recommendation.',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
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
                          color: AppColors.primaryGreen,
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

  List<SprayEntry> get _sprayEntries {
    final entries = <SprayEntry>[
      const SprayEntry(
        date: null,
        title: 'Next spray decision',
        isToday: true,
        pills: [],
      ),
    ];
    entries.addAll(_data.sprayLog.map((entry) {
      final restricted = entry.restricted;
      return SprayEntry(
        date: _formatDate(entry.date),
        title: entry.product,
        type: entry.productType,
        pills: [
          SprayPill(entry.fracCode, AppColors.infectionLowBackground, AppColors.infectionLowText),
          SprayPill(
            restricted ? 'Restricted' : 'OK',
            restricted ? const Color(0xFFFDECEA) : AppColors.infectionLowBackground,
            restricted ? const Color(0xFFB3261E) : AppColors.infectionLowText,
          ),
        ],
      );
    }));
    return entries;
  }

  Widget _restrictedRow(RestrictedGroup group) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEA),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              group.code,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB3261E),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              group.reason,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}
