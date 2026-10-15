import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/features/leaf_scan/presentation/pages/bulk_stages_screen.dart';
import 'package:digisaka/features/smart_schedule/presentation/widgets/schedule_widgets.dart';
import 'package:digisaka/features/smart_schedule/domain/models/smart_schedule_models.dart';
import 'package:digisaka/features/smart_schedule/data/smart_schedule_store.dart';
import 'package:digisaka/features/smart_schedule/presentation/pages/smart_calendar_screen.dart';

/// Lists every bulk that has a confirmed treatment schedule.
class SmartScheduleScreen extends StatelessWidget {
  const SmartScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScheduleBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: AnimatedBuilder(
            animation: ScheduleStore.instance,
            builder: (context, _) {
              final bulks = ScheduleStore.instance.bulks;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScheduleHeader(),
                  const SizedBox(height: 22),
                  const Text(
                    'Scheduled Treatments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Grouped by Bulk assessment — tap a bulk to see its stages',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (bulks.isEmpty)
                    _emptyState()
                  else
                    for (final bulk in bulks) _bulkCard(context, bulk),
                  const SizedBox(height: 18),
                  const ScheduleSectionLabel('FULL CALENDAR'),
                  const SizedBox(height: 12),
                  _calendarCard(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy, size: 44, color: AppColors.textGrey),
          SizedBox(height: 14),
          Text(
            'No scheduled treatments yet',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Finish a bulk assessment to see it here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: kBeige,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF9A6B3A), size: 24),
    );
  }

  Widget _bulkCard(BuildContext context, ScheduledBulk bulk) {
    final count = bulk.stages.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: kCardShadow,
        ),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BulkStagesScreen(bulkId: bulk.id),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _iconBox(Icons.inventory_2_outlined),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bulk.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${bulk.plantName} · ${bulk.id}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textGrey, size: 22),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: kScheduleBorder),
                  const SizedBox(height: 12),
                  Text(
                    '$count scheduled stage${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _calendarCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SmartCalendarScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _iconBox(Icons.calendar_month),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Schedule Calendar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'View the month-by-month treatment calendar',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textGrey,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textGrey, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}