import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:digisaka/features/smart_schedule/presentation/widgets/schedule_widgets.dart';
import 'package:digisaka/features/smart_schedule/domain/models/smart_schedule_models.dart';

/// Month grid (Mon-Sun) that marks missed / upcoming / done steps.
class ScheduleMonthCalendar extends StatefulWidget {
  final List<TimelineStep> steps;
  final String plantTag;

  const ScheduleMonthCalendar({
    super.key,
    required this.steps,
    required this.plantTag,
  });

  @override
  State<ScheduleMonthCalendar> createState() => _ScheduleMonthCalendarState();
}

class _ScheduleMonthCalendarState extends State<ScheduleMonthCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shift(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  TimelineStep? _eventOn(int day) {
    for (final s in widget.steps) {
      if (s.type == StepType.diseaseLogged) continue;
      if (s.date.year == _month.year &&
          s.date.month == _month.month &&
          s.date.day == day) {
        return s;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_month.year, _month.month, 1);
    final lead = first.weekday - 1; // Monday = 0
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((lead + days) / 7).ceil();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _arrow(Icons.chevron_left, () => _shift(-1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  formatMonthYear(_month),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              _arrow(Icons.chevron_right, () => _shift(1)),
              const Spacer(),
              Text(
                widget.plantTag,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C9A8F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final d in const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (var r = 0; r < rows; r++) _week(r, lead, days),
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 22, color: AppColors.textGrey),
    );
  }

  Widget _week(int row, int lead, int days) {
    final cells = <Widget>[];
    var tall = false;
    final now = DateTime.now();

    for (var c = 0; c < 7; c++) {
      final day = row * 7 + c - lead + 1;
      if (day < 1 || day > days) {
        cells.add(const Expanded(child: SizedBox()));
        continue;
      }
      final step = _eventOn(day);
      if (step != null) tall = true;
      final isToday = now.year == _month.year &&
          now.month == _month.month &&
          now.day == day;
      cells.add(Expanded(child: _DayCell(day: day, step: step, isToday: isToday)));
    }

    return Padding(
      padding: EdgeInsets.only(top: tall ? 12 : 4),
      child: SizedBox(height: tall ? 62 : 38, child: Row(children: cells)),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final TimelineStep? step;
  final bool isToday;

  const _DayCell({required this.day, required this.step, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final s = step;

    if (s == null) {
      return Center(
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFFEAF3EC) : null,
            borderRadius: BorderRadius.circular(10),
            border: isToday
                ? Border.all(color: AppColors.primaryGreen, width: 1.5)
                : null,
          ),
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isToday ? AppColors.primaryGreen : AppColors.textDark,
            ),
          ),
        ),
      );
    }

    final status = s.status;
    final Color bg;
    final Color border;
    final Color textColor;
    final String caption;
    final Widget icon;
    Widget? badge;

    switch (status) {
      case StepStatus.missed:
        bg = const Color(0xFFFDE8E8);
        border = const Color(0xFFE57373);
        textColor = const Color(0xFFC62828);
        caption = 'MISSED';
        icon = const Icon(Icons.local_fire_department,
            size: 15, color: Color(0xFFE53935));
        badge = _badge('MISSED', const Color(0xFFD32F2F), AppColors.white);
        break;
      case StepStatus.done:
        bg = const Color(0xFFE3F3E6);
        border = const Color(0xFF8FCFA0);
        textColor = AppColors.primaryGreen;
        caption = 'DONE';
        icon = const Icon(Icons.check_circle,
            size: 15, color: Color(0xFF22A055));
        break;
      case StepStatus.upcoming:
        bg = const Color(0xFFE2F1F1);
        border = const Color(0xFF8FCBC9);
        textColor = const Color(0xFF1C7F86);
        caption = _captionFor(s.type);
        icon = Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: stepColor(s.type),
          ),
        );
        badge = _badge('UPCOMING', const Color(0xFFF2B93B), const Color(0xFF5A4300));
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 1.2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  icon,
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        caption,
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (badge != null)
            Positioned(top: -7, left: 0, right: 0, child: Center(child: badge)),
        ],
      ),
    );
  }

  static String _captionFor(StepType type) {
    switch (type) {
      case StepType.oil:
        return 'OIL';
      case StepType.fungicide:
        return 'FUNGICIDE';
      case StepType.monitoring:
        return 'CHECK';
      case StepType.diseaseLogged:
        return 'LOGGED';
    }
  }

  static Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(
        text,
        style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}