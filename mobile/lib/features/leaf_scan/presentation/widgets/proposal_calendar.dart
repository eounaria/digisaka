import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';

/// Calendar card showing the treatment window month.
///
/// Only days in [month] are shown — no greyed filler days from adjacent
/// months. Data-driven: takes month, line, scan date, window start/end and
/// re-assessment date. When [rejected] is true, window highlights and icons
/// are hidden (plain month grid + scan date only).
///
/// The grid is built with `Row`s of 7 `Expanded` cells (one per weekday), not
/// a `GridView`, so every cell gets a bounded width. Each cell is a fixed
/// 62px-tall `Stack` with `clipBehavior: Clip.none` so the UPCOMING tag and
/// icon can sit just outside the day square without triggering a layout
/// overflow.
class ProposalCalendar extends StatelessWidget {
  final DateTime month;
  final String line;
  final DateTime scanDate;
  final DateTime windowStart;
  final DateTime windowEnd;
  final DateTime reassessmentDate;
  final bool rejected;

  const ProposalCalendar({
    super.key,
    required this.month,
    required this.line,
    required this.scanDate,
    required this.windowStart,
    required this.windowEnd,
    required this.reassessmentDate,
    this.rejected = false,
  });

  @override
  Widget build(BuildContext context) {
    final cells = _monthCells(month);
    final weekdays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_monthName(month.month)} ${month.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Line $line',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Weekday header: 7 aligned Expanded cells matching the grid below.
          Row(
            children: weekdays
                .map((w) => Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          ...List.generate((cells.length / 7).ceil(), (row) {
            final rowCells = cells.skip(row * 7).take(7).toList();
            return Row(
              children: rowCells.map((day) {
                if (day == null) return const SizedBox(height: 62);
                return Expanded(child: SizedBox(height: 62, child: _dayCell(day.day)));
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _dayCell(int day) {
    final date = DateTime(month.year, month.month, day);
    final isScan = _isSameDay(date, scanDate);
    final inWindow = !rejected && _isInWindow(date);
    final isReassess = inWindow && _isSameDay(date, reassessmentDate);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (inWindow)
          Positioned(
            left: 2,
            right: 2,
            top: 10,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFDDF1EE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1C9A8F), width: 1),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          top: 14,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 24,
                alignment: Alignment.center,
                decoration: isScan
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryGreen, width: 2))
                    : null,
                child: Text(
                  '$day',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (inWindow)
                Icon(
                  isReassess ? Icons.search : Icons.local_fire_department,
                  size: 14,
                  color: isReassess ? const Color(0xFF1C9A8F) : const Color(0xFFF59E0B),
                ),
            ],
          ),
        ),
        if (inWindow)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5B82E),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'UPCOMING',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontSize: 6,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3B2A00),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Returns one entry per grid cell. Days outside [month] are null (empty cell).
  List<DateTime?> _monthCells(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final cells = <DateTime?>[];
    var d = first;
    while (d.month == month.month) {
      cells.add(d);
      d = d.add(const Duration(days: 1));
    }
    // Pad the last row to 7 columns.
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isInWindow(DateTime day) {
    final s = DateTime(windowStart.year, windowStart.month, windowStart.day);
    final e = DateTime(windowEnd.year, windowEnd.month, windowEnd.day);
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}
