import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/features/leaf_scan/data/line_insights_data.dart';

class WeeklyTrendsCard extends StatefulWidget {
  final LineInsightsData data;
  const WeeklyTrendsCard({super.key, required this.data});

  @override
  State<WeeklyTrendsCard> createState() => _WeeklyTrendsCardState();
}

class _WeeklyTrendsCardState extends State<WeeklyTrendsCard> {
  String _series = 'yls';
  bool _showTable = false;

  static const _kSeries = <String>['yls', 'yli', 'leaves'];
  static const _kLabels = <String, String>{'yls': 'YLS', 'yli': 'YLI', 'leaves': 'Leaves'};
  static const _kIcons = <String, IconData>{
    'yls': Icons.eco_outlined,
    'yli': Icons.spa_outlined,
    'leaves': Icons.park_outlined,
  };

  List<String> get _weekLabels =>
      widget.data.weeklyReadings.map((r) => r.isoWeek.replaceFirst(RegExp(r'^\d{4}-W'), 'W')).toList();

  List<double?> get _values {
    switch (_series) {
      case 'yls':
        return widget.data.weeklyReadings.map((r) => r.yls?.toDouble()).toList();
      case 'yli':
        return widget.data.weeklyReadings.map((r) => r.yli?.toDouble()).toList();
      case 'leaves':
        return widget.data.weeklyReadings.map((r) => r.leaves?.toDouble()).toList();
    }
    return <double?>[];
  }

  List<double> get _rain =>
      widget.data.weeklyReadings.map((r) => r.rainMm.toDouble()).toList();

  List<String> get _nullWeeks {
    final result = <String>[];
    for (int i = 0; i < widget.data.weeklyReadings.length; i++) {
      final v = _values[i];
      if (v == null) result.add(_weekLabels[i]);
    }
    return result;
  }

  String get _caption {
    final lineLabel = _kLabels[_series]!;
    final nullWeeks = _nullWeeks;
    final tail = nullWeeks.isEmpty ? '' : ' ${nullWeeks.join(", ")} not recorded yet.';
    return 'Line: $lineLabel. Bars: rainfall.$tail';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WEEKLY TRENDS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textGrey)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kSeries.map((s) {
              final selected = _series == s;
              return GestureDetector(
                onTap: () => setState(() => _series = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryGreen : AppColors.white,
                    border: Border.all(
                      color: selected ? AppColors.primaryGreen : const Color(0xFF2B2B2B),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_kIcons[s]!, size: 16,
                          color: selected ? AppColors.white : AppColors.textDark),
                      const SizedBox(width: 6),
                      Text(_kLabels[s]!,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                              color: selected ? AppColors.white : AppColors.textDark)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TrendsChart(labels: _weekLabels, values: _values, rain: _rain),
          const SizedBox(height: 10),
          Text(_caption,
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          if (_series == 'yls') ...[
            const SizedBox(height: 4),
            const Text('lower = disease on a younger leaf, so worsening goes down',
                style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _showTable = !_showTable),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_showTable ? 'Hide the numbers' : 'Show the numbers',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                const SizedBox(width: 4),
                Icon(_showTable ? Icons.expand_less : Icons.expand_more,
                    size: 16, color: AppColors.primaryGreen),
              ],
            ),
          ),
          if (_showTable) ...[
            const SizedBox(height: 12),
            _table(),
          ],
        ],
      ),
    );
  }

  Widget _table() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Table(
        children: [
          TableRow(
            children: [
              _tableCell('Week', header: true),
              _tableCell('YLS', header: true),
              _tableCell('YLI', header: true),
              _tableCell('Leaves', header: true),
              _tableCell('Rain (mm)', header: true),
            ],
          ),
          for (final r in widget.data.weeklyReadings)
            TableRow(
              children: [
                _tableCell(r.isoWeek.replaceFirst(RegExp(r'^\d{4}-W'), 'W')),
                _tableCell(r.yls?.toString() ?? '–'),
                _tableCell(r.yli?.toString() ?? '–'),
                _tableCell(r.leaves?.toString() ?? '–'),
                _tableCell('${r.rainMm}'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _tableCell(String text, {bool header = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(text, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, fontWeight: header ? FontWeight.bold : FontWeight.normal,
              color: header ? AppColors.textGrey : AppColors.textDark)),
    );
  }
}

class TrendsChart extends StatelessWidget {
  final List<String> labels;
  final List<double?> values;
  final List<double> rain;
  const TrendsChart({super.key, required this.labels, required this.values, required this.rain});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: LayoutBuilder(
        builder: (context, c) => CustomPaint(
          size: Size(c.maxWidth, 150),
          painter: _TrendsPainter(labels, values, rain),
        ),
      ),
    );
  }
}

class _TrendsPainter extends CustomPainter {
  final List<String> labels;
  final List<double?> values;
  final List<double> rain;
  _TrendsPainter(this.labels, this.values, this.rain);

  void _text(Canvas canvas, String s, double x, double y, {bool center = true, double size = 10}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, color: AppColors.textGrey)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center ? x - tp.width / 2 : x, y - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const double left = 24, right = 8, top = 8, bottom = 22;
    final double plotW = size.width - left - right;
    final double plotH = size.height - top - bottom;
    final int n = labels.length;
    if (n == 0 || plotW <= 0) return;

    final double slot = plotW / n;
    final double barW = slot * 0.58;
    final double base = top + plotH;
    final double maxRain = rain.fold<double>(1, (a, b) => a > b ? a : b);

    // Bars (inside the card, centered in each week slot).
    final barPaint = Paint()..color = const Color(0xFFBFE3D8);
    for (int i = 0; i < n; i++) {
      final double h = rain[i] / maxRain * plotH * 0.62;
      final double cx = left + slot * (i + 0.5);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - barW / 2, base - h, barW, h),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        barPaint,
      );
    }
    // Baseline.
    canvas.drawLine(Offset(left, base), Offset(left + plotW, base),
        Paint()..color = const Color(0xFFDDE3DB)..strokeWidth = 1);

    // Line + dots (breaks where a value is missing).
    final nonNull = values.whereType<double>().toList();
    final double maxV = nonNull.isEmpty ? 1 : nonNull.reduce(math.max);
    double yOf(double v) => top + 6 + (plotH - 6) * (1 - v / maxV);
    final linePaint = Paint()
      ..color = AppColors.primaryGreen
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = AppColors.primaryGreen;
    double? px, py;
    for (int i = 0; i < n; i++) {
      final v = values[i];
      if (v == null) { px = null; py = null; continue; }
      final double x = left + slot * (i + 0.5);
      final double y = yOf(v);
      if (px != null && py != null) canvas.drawLine(Offset(px, py), Offset(x, y), linePaint);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
      px = x; py = y;
    }
    if (nonNull.isNotEmpty) _text(canvas, maxV.round().toString(), 4, yOf(maxV), center: false);

    // X labels centered under each bar.
    for (int i = 0; i < n; i++) {
      _text(canvas, labels[i], left + slot * (i + 0.5), size.height - 8);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendsPainter old) => true;
}
