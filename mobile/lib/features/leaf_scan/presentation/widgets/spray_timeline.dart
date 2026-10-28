import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';

/// One row of the spray-log timeline.
class SprayEntry {
  final String? date;        // null for the "Today" item
  final String title;        // "Next spray decision" or product name
  final String? type;        // "Systemic" / "Contact"
  final bool isToday;
  final List<SprayPill> pills; // FRAC code pill + status pill

  const SprayEntry({
    this.date,
    required this.title,
    this.type,
    this.isToday = false,
    this.pills = const [],
  });
}

/// One pill chip shown under a timeline entry.
class SprayPill {
  final String label;
  final Color bg;
  final Color fg;

  const SprayPill(this.label, this.bg, this.fg);
}

/// Spray-history timeline: one continuous grey spine with a dot per item.
///
/// Per item: date (small grey) above, then the product name in bold with the
/// type in regular grey on the same line, then the pills row below. Dots
/// align with the date line.
class SprayTimeline extends StatelessWidget {
  final List<SprayEntry> entries;

  const SprayTimeline({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < entries.length; i++) _item(entries[i], isLast: i == entries.length - 1),
      ],
    );
  }

  Widget _item(SprayEntry e, {required bool isLast}) {
    final dot = e.isToday || e.pills.any((p) => p.label == 'OK')
        ? const Color(0xFF1E7D3A) : const Color(0xFFD94A5A);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Stack(
              children: [
                Positioned(
                  left: 7,
                  top: 6,
                  bottom: isLast ? 14 : 0,
                  width: 2,
                  child: Container(color: const Color(0xFFD5DAD2)),
                ),
                Positioned(
                  left: 1,
                  top: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.isToday ? 'Today' : (e.date ?? ''),
                    style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: e.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (e.type != null)
                          TextSpan(
                            text: '  ${e.type}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textGrey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (e.pills.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in e.pills)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: p.bg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              p.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: p.fg,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
