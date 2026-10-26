import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';

/// One week's readings: YLS (leaf-spot stage), YLI (leaf index), rainfall.
class _WeekReading {
  final String isoWeek;
  final int? yls;
  final int? yli;
  final int rainMm;

  const _WeekReading({
    required this.isoWeek,
    this.yls,
    this.yli,
    required this.rainMm,
  });
}

/// Self-contained week context card: line/date selectors, ISO-week charts
/// (YLS line + rainfall bars), and a collapsible numbers table.
///
/// Manages its own line/date/expanded state; the rest of the screen does
/// not depend on week selection.
class WeekContextCard extends StatefulWidget {
  final String initialLine;
  final DateTime initialDate;
  final DateTime demoToday;
  final ValueChanged<String>? onLineChanged;
  final ValueChanged<DateTime>? onDateChanged;

  WeekContextCard({
    super.key,
    this.initialLine = 'L04',
    DateTime? initialDate,
    required this.demoToday,
    this.onLineChanged,
    this.onDateChanged,
  }) : initialDate = initialDate ?? DateTime(2026, 6, 9);

  @override
  State<WeekContextCard> createState() => _WeekContextCardState();
}

class _WeekContextCardState extends State<WeekContextCard> {
  late String _line;
  late DateTime _selectedDate;
  late TextEditingController _dateController;
  bool _showNumbers = false;

  static const List<String> _kLines = <String>['L01', 'L02', 'L03', 'L04', 'L05', 'L06'];

  @override
  void initState() {
    super.initState();
    _line = widget.initialLine;
    _selectedDate = widget.initialDate;
    _dateController = TextEditingController(text: _formatMdY(_selectedDate));
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  // ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
  // ISO-8601 week helpers (Monday–Sunday)
  // ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈

  int _dayOfYear(DateTime d) {
    final start = DateTime(d.year, 1, 1);
    return d.difference(start).inDays + 1;
  }

  int _isoWeekNumber(DateTime d) {
    final int weekday = d.weekday; // Mon=1 … Sun=7
    final thursday = d.add(Duration(days: 4 - weekday));
    final int thursdayDoY = _dayOfYear(thursday);
    return ((thursdayDoY - thursday.weekday + 10) ~/ 7);
  }

  DateTime _weekStart(DateTime d) {
    return d.subtract(Duration(days: d.weekday - 1));
  }

  String _isoWeekLabel(DateTime d) {
    final int week = _isoWeekNumber(d);
    final thursday = d.add(Duration(days: 4 - d.weekday));
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  String _formatMdY(DateTime d) {
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatYmd(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
  // Mock data (TODO: replace with real API data)
  // ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈

  /// Returns the selected week + the 2 before it.
  /// Values: oldest 8 / – / 30, middle 5 / 5 / 26, latest – / – / 12.
  List<_WeekReading> _mockReadingsFor(String line, DateTime date) {
    final weekStart = _weekStart(date);
    final latest = weekStart;
    final middle = latest.subtract(const Duration(days: 7));
    final oldest = middle.subtract(const Duration(days: 7));

    return [
      _WeekReading(
        isoWeek: _isoWeekLabel(oldest),
        yls: 8,
        yli: null,
        rainMm: 30,
      ),
      _WeekReading(
        isoWeek: _isoWeekLabel(middle),
        yls: 5,
        yli: 5,
        rainMm: 26,
      ),
      _WeekReading(
        isoWeek: _isoWeekLabel(latest),
        yls: null,
        yli: null,
        rainMm: 12,
      ),
    ];
  }

  List<_WeekReading> get _readings => _mockReadingsFor(_line, _selectedDate);

  // ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
  // Missing-week captions
  // ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈

  String _missing(List<int?> values, List<String> weeks) {
    final missing = <String>[];
    for (int i = 0; i < values.length; i++) {
      if (values[i] == null) missing.add(weeks[i]);
    }
    return missing.isEmpty ? 'none' : missing.join(', ');
  }

  // ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
  // Build
  // ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈

  @override
  Widget build(BuildContext context) {
    final weekStart = _weekStart(_selectedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final readings = _readings;
    final weeks = readings.map((r) => r.isoWeek).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
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
          // Line selector.
          const Text(
            'Line',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _line,
            items:
                _kLines
                    .map(
                      (l) => DropdownMenuItem<String>(
                        value: l,
                        child: Text(l, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _line = newValue);
                widget.onLineChanged?.call(newValue);
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.borderGrey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.borderGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryGreen),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Date selector + Previous / Next week buttons.
          const Text(
            'Date',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(flex: 2, child: _buildDateField()),
              const SizedBox(width: 8),
              Expanded(flex: 1, child: _buildWeekButton('Previous week', -7, enabled: true)),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildWeekButton(
                  'Next week',
                  7,
                  enabled: _isNextWeekEnabled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Week caption.
          Text(
            'Week ${_isoWeekLabel(_selectedDate)} (${_formatYmd(weekStart)} to ${_formatYmd(weekEnd)})',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 16),

          // Charts heading.
          Text(
            'Line $_line: last 3 weeks',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),

          // YLS line chart.
          const Text(
            'Leaf-spot stage (YLS) by week',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'lower = disease on a younger leaf, so worsening goes down',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: _LeafSpotLineChart(readings: readings),
          ),
          const SizedBox(height: 4),
          const Text(
            'YLI (lighter line) is shown for context.',
            style: TextStyle(
              fontSize: 9,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 16),

          // Rainfall bar chart.
          const Text(
            'Rainfall by week (mm)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: _RainfallBarChart(readings: readings),
          ),
          const SizedBox(height: 8),

          // Missing weeks caption.
          Text(
            'Missing weeks - YLS: ${_missing(readings.map((r) => r.yls).toList(), weeks)}; YLI: ${_missing(readings.map((r) => r.yli).toList(), weeks)}.',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 16),

          // Collapsible numbers table.
          InkWell(
            onTap: () => setState(() => _showNumbers = !_showNumbers),
            child: Row(
              children: [
                Text(
                  _showNumbers ? 'Hide the numbers' : 'Show the numbers',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 6),
                RotatedBox(
                  quarterTurns: _showNumbers ? 0 : 2,
                  child: const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          if (_showNumbers) ...[
            const SizedBox(height: 10),
            _buildNumbersTable(readings, weeks),
          ],
        ],
      ),
    );
  }

  bool get _isNextWeekEnabled {
    final nextMonday = _weekStart(_selectedDate).add(const Duration(days: 7));
    return !nextMonday.isAfter(widget.demoToday);
  }

  Widget _buildDateField() {
    return TextField(
      controller: _dateController,
      readOnly: true,
      onTap: _selectDate,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryGreen),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today, size: 20, color: AppColors.primaryGreen),
          onPressed: _selectDate,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: widget.demoToday,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatMdY(picked);
      });
      widget.onDateChanged?.call(picked);
    }
  }

  Widget _buildWeekButton(String label, int days, {required bool enabled}) {
    return OutlinedButton(
      onPressed: enabled ? () => _shiftWeek(days) : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? AppColors.primaryGreen : AppColors.textGrey,
        side: BorderSide(
          color: enabled ? AppColors.primaryGreen : AppColors.borderGrey,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _shiftWeek(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _dateController.text = _formatMdY(_selectedDate);
    });
    widget.onDateChanged?.call(_selectedDate);
  }

  Widget _buildNumbersTable(List<_WeekReading> readings, List<String> weeks) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1.5),
      },
      border: TableBorder.all(color: AppColors.borderGrey),
      children: [
        TableRow(
          children: [
            _tableCell('Week', bold: true, align: TextAlign.left),
            _tableCell('YLS', bold: true),
            _tableCell('YLI', bold: true),
            _tableCell('Rain (mm)', bold: true),
          ],
        ),
        for (int i = 0; i < readings.length; i++) ...[
          TableRow(
            children: [
              _tableCell(weeks[i], align: TextAlign.left),
              _tableCell(readings[i].yls?.toString() ?? '-'),
              _tableCell(readings[i].yli?.toString() ?? '-'),
              _tableCell(readings[i].rainMm.toString()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _tableCell(String text, {bool bold = false, TextAlign align = TextAlign.center}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: AppColors.textDark,
        ),
        textAlign: align,
      ),
    );
  }
}

/// Line chart drawing YLS (primary green) and YLI (lighter green) by week.
/// Null values break the line and draw no dot.
class _LeafSpotLineChart extends StatelessWidget {
  final List<_WeekReading> readings;

  const _LeafSpotLineChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.fromWidth(double.infinity),
      painter: _LeafSpotLinePainter(readings: readings),
    );
  }
}

class _LeafSpotLinePainter extends CustomPainter {
  final List<_WeekReading> readings;

  _LeafSpotLinePainter({required this.readings});

  @override
  void paint(Canvas canvas, Size size) {
    final plotWidth = size.width - 40; // room for y-label + x-labels
    final plotHeight = size.height - 30; // room for x-labels below
    final plotLeft = 20.0;
    final plotTop = 10.0;

    // Collect non-null values for scaling.
    final ylsValues = <double>[];
    final yliValues = <double>[];
    for (final r in readings) {
      if (r.yls != null) ylsValues.add(r.yls!.toDouble());
      if (r.yli != null) yliValues.add(r.yli!.toDouble());
    }
    final allValues = <double>[]..addAll(ylsValues)..addAll(yliValues);
    final maxY = allValues.isNotEmpty ? allValues.reduce((a, b) => a > b ? a : b) : 1.0;

    final stepX = plotWidth / (readings.length - 1);

    // Helper to map a value to y pixel.
    double yPix(double v) => plotTop + plotHeight - (v / maxY) * plotHeight;

    // Draw YLS line (primary green).
    final ylsPaint = Paint()
      ..color = AppColors.primaryGreen
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw YLI line (lighter green).
    final yliPaint = Paint()
      ..color = AppColors.chartYliLineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..style = PaintingStyle.fill;

    // Draw lines and dots.
    for (int series = 0; series < 2; series++) {
      final paint = series == 0 ? ylsPaint : yliPaint;
      bool havePrev = false;
      double prevX = 0, prevY = 0;

      for (int i = 0; i < readings.length; i++) {
        final v = series == 0 ? readings[i].yls : readings[i].yli;
        if (v == null) {
          havePrev = false;
          continue;
        }
        final x = plotLeft + i * stepX;
        final y = yPix(v.toDouble());
        if (havePrev) {
          canvas.drawLine(Offset(prevX, prevY), Offset(x, y), paint);
        }
        dotPaint.color = paint.color;
        canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
        prevX = x;
        prevY = y;
        havePrev = true;
      }
    }

    // X-axis labels.
    final labelStyle = TextStyle(
      fontSize: 10,
      color: AppColors.textGrey,
    );
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int i = 0; i < readings.length; i++) {
      final x = plotLeft + i * stepX;
      textPainter.text = TextSpan(text: readings[i].isoWeek.replaceFirst(RegExp(r'^\d{4}-W'), 'W'), style: labelStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 20),
      );
    }

    // Y-axis label.
    final yLabelPainter = TextPainter(
      text: const TextSpan(text: 'YLS', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    yLabelPainter.layout();
    yLabelPainter.paint(canvas, Offset(4, plotTop - yLabelPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bar chart drawing rainfall by week.
class _RainfallBarChart extends StatelessWidget {
  final List<_WeekReading> readings;

  const _RainfallBarChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.fromWidth(double.infinity),
      painter: _RainfallBarPainter(readings: readings),
    );
  }
}

class _RainfallBarPainter extends CustomPainter {
  final List<_WeekReading> readings;

  _RainfallBarPainter({required this.readings});

  @override
  void paint(Canvas canvas, Size size) {
    final plotWidth = size.width - 40;
    final plotHeight = size.height - 25;
    final plotLeft = 20.0;
    final plotTop = 5.0;

    final maxRain = readings.isNotEmpty
        ? readings.map((r) => r.rainMm).reduce((a, b) => a > b ? a : b).toDouble()
        : 1.0;

    final barWidth = 22.0;
    final groupWidth = plotWidth / readings.length;
    final stepX = groupWidth;

    // Gridlines + y-axis tick labels.
    final gridPaint = Paint()
      ..color = AppColors.chartGridlineColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final tickCount = 4;
    for (int t = 0; t <= tickCount; t++) {
      final frac = t / tickCount;
      final y = plotTop + plotHeight - frac * plotHeight;
      canvas.drawLine(Offset(plotLeft, y), Offset(plotLeft + plotWidth, y), gridPaint);

      final value = (maxRain * frac).round();
      final tp = TextPainter(
        text: TextSpan(text: value.toString(), style: const TextStyle(fontSize: 9, color: AppColors.textGrey)),
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(plotLeft - tp.width - 4, y - tp.height / 2));
    }

    // Bars.
    final barPaint = Paint()..color = AppColors.chartBarColor;
    for (int i = 0; i < readings.length; i++) {
      final h = (readings[i].rainMm / maxRain) * plotHeight;
      final x = plotLeft + i * stepX + (stepX - barWidth) / 2;
      final y = plotTop + plotHeight - h;
      canvas.drawRect(Rect.fromLTWH(x, y, barWidth, h), barPaint);
    }

    // X-axis labels.
    final labelStyle = TextStyle(fontSize: 10, color: AppColors.textGrey);
    final tp = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int i = 0; i < readings.length; i++) {
      final x = plotLeft + i * stepX + stepX / 2;
      tp.text = TextSpan(text: readings[i].isoWeek.replaceFirst(RegExp(r'^\d{4}-W'), 'W'), style: labelStyle);
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
