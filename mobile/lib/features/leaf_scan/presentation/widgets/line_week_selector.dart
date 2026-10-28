import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/features/leaf_scan/data/line_insights_data.dart';

/// Line + week selector for the Line Insights screen.
///
/// Shows a Line dropdown (L01-L06) and a grey week caption computed from the
/// fixed demo date. Manages its own line state and reports changes via
/// [onLineChanged] so [LineInsightsScreen] can refresh every card below.
class LineWeekSelector extends StatefulWidget {
  final String initialLine;
  final DateTime selectedDate;
  final ValueChanged<String>? onLineChanged;

  const LineWeekSelector({
    super.key,
    this.initialLine = 'L04',
    required this.selectedDate,
    this.onLineChanged,
  });

  @override
  State<LineWeekSelector> createState() => _LineWeekSelectorState();
}

class _LineWeekSelectorState extends State<LineWeekSelector> {
  late String _line;

  static const List<String> _kLines = <String>['L01', 'L02', 'L03', 'L04', 'L05', 'L06'];

  @override
  void initState() {
    super.initState();
    _line = widget.initialLine;
  }

  String get _isoWeek => isoWeekLabel(widget.selectedDate);

  DateTime get _weekStart => weekStart(widget.selectedDate);

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  @override
  Widget build(BuildContext context) {
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
            initialValue: _line,
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
              if (newValue == null) return;
              setState(() => _line = newValue);
              widget.onLineChanged?.call(newValue);
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Week $_isoWeek (${formatMonthDay(_weekStart)} to ${formatMonthDay(_weekEnd)})',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
