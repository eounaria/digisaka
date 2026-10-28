import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/features/leaf_scan/data/line_insights_data.dart';
import 'package:digisaka/features/leaf_scan/presentation/pages/leaf_scan_screen.dart';
import 'package:digisaka/features/notification/presentation/pages/notifications_screen.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/canopy_check_card.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/line_insights_card.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/line_week_selector.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/weekly_trends_card.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/why_management_card.dart';
import 'package:digisaka/shared/components/app_bar_widget.dart';
import 'package:digisaka/shared/components/app_button.dart';
import 'package:digisaka/shared/navigation/shell_scope.dart';

/// Scan pre-screen: pick a line and week, view line insights, then continue
/// to the leaf scan page carrying the selected line/week/date.
class LineInsightsScreen extends StatefulWidget {
  const LineInsightsScreen({super.key});

  @override
  State<LineInsightsScreen> createState() => _LineInsightsScreenState();
}

class _LineInsightsScreenState extends State<LineInsightsScreen> {
  String _selectedLine = 'L04';
  final DateTime _selectedDate = DateTime(2026, 6, 8); // Monday of 2026-W24

  String get _isoWeek => isoWeekLabel(_selectedDate);

  LineInsightsData get _data => LineInsightsData.mockInsightsFor(_selectedLine, _selectedDate);

  void _goToNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _goBack() {
    final shell = ShellScope.maybeOf(context);
    if (shell != null) {
      shell.changeTab(0);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LeafScanScreen(
          line: _selectedLine,
          isoWeek: _isoWeek,
          selectedDate: _selectedDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Line Insights',
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
                'Review the line condition for the selected week before scanning leaves.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              LineWeekSelector(
                selectedDate: _selectedDate,
                onLineChanged: (line) => setState(() => _selectedLine = line),
              ),
              const SizedBox(height: 20),
              LineInsightsCard(data: _data),
              const SizedBox(height: 16),
              WeeklyTrendsCard(data: _data),
              const SizedBox(height: 16),
              CanopyCheckCard(
                leaves: _data.functionalLeaves,
                critical: _data.functionalLeavesCritical,
                target: _data.functionalLeavesThreshold,
              ),
              const SizedBox(height: 16),
              _demoBanner(),
              const SizedBox(height: 16),
              WhyManagementCard(
                line: _data.line,
                isoWeek: _data.isoWeek,
                rows: [
                  WhyRowData(
                    'Disease stage (Fouré)',
                    'Stage 4 on 1 leaf, stage 3 on 1, stage 1 on 2. 1 leaf could not be rated.',
                    [WhyBadge.noted, WhyBadge.provisional],
                  ),
                  WhyRowData(
                    'Youngest leaf spotted (YLS)',
                    'Leaf 8 to leaf 6 over 3 weeks. Spots are reaching younger leaves.',
                    [WhyBadge.concerning('R2'), WhyBadge.provisional],
                  ),
                  WhyRowData(
                    'Youngest leaf infected (YLI)',
                    'Leaf 5 to leaf 4. A lower number means a younger leaf.',
                    [WhyBadge.concerning('R1'), WhyBadge.provisional],
                  ),
                  WhyRowData(
                    'Functional leaves',
                    '9 counted. Target 10, critical 8.',
                    [WhyBadge.watch('R3'), WhyBadge.provisional],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buttonRow(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _demoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBEFC8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Sample data for demo. Not validated guidance or label information.',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B4A00)),
      ),
    );
  }

  Widget _buttonRow() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: _goBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: BorderSide(color: AppColors.primaryGreen),
                backgroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Back',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: 'Continue',
            onPressed: _continue,
            backgroundColor: AppColors.primaryGreen,
            textColor: AppColors.white,
          ),
        ),
      ],
    );
  }
}
