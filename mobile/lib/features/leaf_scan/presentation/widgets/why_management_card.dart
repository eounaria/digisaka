import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';

class WhyBadge {
  final String label;
  final Color bg;
  final Color fg;
  const WhyBadge(this.label, this.bg, this.fg);

  static const noted = WhyBadge('Noted', Color(0xFFE6E8E4), Color(0xFF555B54));
  static const provisional = WhyBadge('Provisional', Color(0xFFFBE9C6), Color(0xFF7A5200));
  static WhyBadge concerning(String r) => WhyBadge('Concerning · $r', const Color(0xFFFADADA), const Color(0xFFC62828));
  static WhyBadge watch(String r) => WhyBadge('Watch · $r', const Color(0xFFFBE9C6), const Color(0xFF7A5200));
}

class WhyRowData {
  final String title;
  final String body;
  final List<WhyBadge> badges; // status badge first, then Provisional
  const WhyRowData(this.title, this.body, this.badges);
}

class WhyManagementCard extends StatelessWidget {
  final String line;
  final String isoWeek;
  final List<WhyRowData> rows;
  final String note;
  const WhyManagementCard({
    super.key,
    required this.line,
    required this.isoWeek,
    required this.rows,
    this.note =
        'One reading never decides this alone. Several indicators and the weather point the same way.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Why management is needed',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
          const SizedBox(height: 2),
          Text('Line $line · $isoWeek',
              style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          const SizedBox(height: 12),
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 10),
                color: const Color(0xFFE9ECE7),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rows[i].title,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      const SizedBox(height: 3),
                      Text(rows[i].body,
                          style: const TextStyle(fontSize: 13, height: 1.3, color: AppColors.textDark)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int b = 0; b < rows[i].badges.length; b++) ...[
                      if (b > 0) const SizedBox(height: 6),
                      _pill(rows[i].badges[b]),
                    ],
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(note,
                style: const TextStyle(fontSize: 13, height: 1.3, color: AppColors.textDark)),
          ),
        ],
      ),
    );
  }

  Widget _pill(WhyBadge b) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: b.bg, borderRadius: BorderRadius.circular(999)),
        child: Text(b.label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: b.fg)),
      );
}
