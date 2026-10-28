/// One week's readings used by the Line Insights cards.
class WeeklyReading {
  final String isoWeek;
  final int? yls;
  final int? yli;
  final int? leaves;
  final int rainMm;

  const WeeklyReading({
    required this.isoWeek,
    this.yls,
    this.yli,
    this.leaves,
    required this.rainMm,
  });
}

/// Severity of the infection risk tile shown in the Line Insights card.
enum InfectionRisk { low, medium, high }

/// Progression state shown inside the Line Insights card.
enum ProgressionStatus { worsening, improving, stable, none }

/// Kind of a small rounded badge shown in a Why management row.
enum InsightBadgeKind { noted, provisional, concerning, watch }

/// One small rounded badge in a Why management row.
class InsightBadge {
  final String label;
  final InsightBadgeKind kind;

  const InsightBadge({required this.label, required this.kind});
}

/// One divider-separated row in the Why management card.
class IndicatorRow {
  final String title;
  final String body;
  final List<InsightBadge> badges;

  const IndicatorRow({required this.title, required this.body, required this.badges});
}

/// Snapshot of a line's condition for the selected week. Every card in the
/// Line Insights screen reads from this model only; no hard-coded numbers
/// live inside the widgets.
class LineInsightsData {
  final String line;
  final String isoWeek;
  final DateTime selectedDate;
  final int? yls;
  final int? yli;
  final int functionalLeaves;
  final int functionalLeavesThreshold;
  final int functionalLeavesCritical;
  final InfectionRisk infectionRisk;
  final String infectionRainText;
  final String? lastTreatment;
  final ProgressionStatus progression;
  final List<WeeklyReading> weeklyReadings;
  final List<IndicatorRow> indicatorRows;

  const LineInsightsData({
    required this.line,
    required this.isoWeek,
    required this.selectedDate,
    this.yls,
    this.yli,
    required this.functionalLeaves,
    required this.functionalLeavesThreshold,
    required this.functionalLeavesCritical,
    required this.infectionRisk,
    required this.infectionRainText,
    this.lastTreatment,
    required this.progression,
    required this.weeklyReadings,
    required this.indicatorRows,
  });

  /// Demo data for [line] starting at [weekStart] (Monday of the selected week).
  static LineInsightsData mockInsightsFor(String line, DateTime weekStart) {
    final isoWeek = isoWeekLabel(weekStart);
    final weekLabels = <String>[];
    for (var i = 2; i >= 0; i--) {
      final w = weekStart.subtract(Duration(days: 7 * i));
      weekLabels.add(isoWeekLabel(w));
    }

    return LineInsightsData(
      line: line,
      isoWeek: isoWeek,
      selectedDate: weekStart,
      yls: 8,
      yli: 5,
      functionalLeaves: 9,
      functionalLeavesThreshold: 10,
      functionalLeavesCritical: 8,
      infectionRisk: InfectionRisk.high,
      infectionRainText: 'Rain 42 mm in 7 days',
      lastTreatment: 'Propiconazole · FRAC 3 · Oct 14',
      progression: ProgressionStatus.worsening,
      weeklyReadings: [
        WeeklyReading(isoWeek: weekLabels[0], yls: 8, yli: null, leaves: 10, rainMm: 30),
        WeeklyReading(isoWeek: weekLabels[1], yls: 8, yli: 5, leaves: 9, rainMm: 26),
        WeeklyReading(isoWeek: weekLabels[2], yls: null, yli: null, leaves: null, rainMm: 12),
      ],
      indicatorRows: [
        IndicatorRow(
          title: 'Disease stage (Fouré)',
          body: 'Stage 4 on 1 leaf, stage 3 on 1, stage 1 on 2. 1 leaf could not be rated.',
          badges: [
            InsightBadge(label: 'Noted', kind: InsightBadgeKind.noted),
            InsightBadge(label: 'Provisional', kind: InsightBadgeKind.provisional),
          ],
        ),
        IndicatorRow(
          title: 'Youngest leaf spotted (YLS)',
          body: 'Leaf 8 to leaf 6 over 3 weeks. Spots are reaching younger leaves.',
          badges: [
            InsightBadge(label: 'Concerning · R2', kind: InsightBadgeKind.concerning),
            InsightBadge(label: 'Provisional', kind: InsightBadgeKind.provisional),
          ],
        ),
        IndicatorRow(
          title: 'Youngest leaf infected (YLI)',
          body: 'Leaf 5 to leaf 4. A lower number means a younger leaf.',
          badges: [
            InsightBadge(label: 'Concerning · R1', kind: InsightBadgeKind.concerning),
            InsightBadge(label: 'Provisional', kind: InsightBadgeKind.provisional),
          ],
        ),
        IndicatorRow(
          title: 'Functional leaves',
          body: '9 counted. Target 10, critical 8.',
          badges: [
            InsightBadge(label: 'Watch · R3', kind: InsightBadgeKind.watch),
            InsightBadge(label: 'Provisional', kind: InsightBadgeKind.provisional),
          ],
        ),
      ],
    );
  }
}

// ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
// ISO-8601 week helpers (Monday–Sunday)
// ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈

int _dayOfYear(DateTime d) {
  final start = DateTime(d.year, 1, 1);
  return d.difference(start).inDays + 1;
}

int isoWeekNumber(DateTime d) {
  final thursday = d.add(Duration(days: 4 - d.weekday));
  final int thursdayDoY = _dayOfYear(thursday);
  return ((thursdayDoY - thursday.weekday + 10) ~/ 7);
}

DateTime weekStart(DateTime d) {
  return d.subtract(Duration(days: d.weekday - 1));
}

String isoWeekLabel(DateTime d) {
  final int week = isoWeekNumber(d);
  final thursday = d.add(Duration(days: 4 - d.weekday));
  return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
}

String formatMdY(DateTime d) {
  return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
}

String formatYmd(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day}';
}

/// "Jun 8" style: abbreviated month name + day (no leading zero).
String formatMonthDay(DateTime d) {
  const months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}';
}
