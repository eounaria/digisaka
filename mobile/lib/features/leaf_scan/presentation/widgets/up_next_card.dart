import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';

/// "Up next" card shown below the calendar.
///
/// Displays the next treatment action with its window and a computed
/// "IN N DAYS" chip. When [rejected] is true the whole card is hidden.
class UpNextCard extends StatelessWidget {
  final String line;
  final DateTime scanDate;
  final DateTime windowStart;
  final DateTime windowEnd;
  final bool rejected;

  const UpNextCard({
    super.key,
    required this.line,
    required this.scanDate,
    required this.windowStart,
    required this.windowEnd,
    this.rejected = false,
  });

  @override
  Widget build(BuildContext context) {
    if (rejected) return const SizedBox.shrink();

    final diff = windowStart.difference(scanDate).inDays;
    final chip = diff == 1 ? 'IN 1 DAY' : 'IN $diff DAYS';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'UP NEXT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textGrey,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: AppColors.accentYellow,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UP NEXT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textGrey,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Treatment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Window ${windowStart.day} ${_monthShort(windowStart.month)} to ${windowEnd.day} ${_monthShort(windowEnd.month)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryGreen, width: 1),
                      ),
                      child: Text(
                        chip,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Protectant fungicide spray. Apply between June 15, 2026 and June 17, 2026.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _monthShort(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }
}
