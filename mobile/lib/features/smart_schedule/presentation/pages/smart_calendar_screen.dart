import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/features/smart_schedule/presentation/widgets/schedule_month_calendar.dart';
import 'package:digisaka/features/smart_schedule/data/smart_schedule_store.dart';
import 'package:digisaka/features/smart_schedule/presentation/widgets/schedule_widgets.dart';

/// "Smart Schedule Calendar": every step from every scheduled bulk.
class SmartCalendarScreen extends StatelessWidget {
  const SmartCalendarScreen({super.key});

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
              final steps = ScheduleStore.instance.bulks
                  .expand((b) => b.stages)
                  .expand((s) => s.steps)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScheduleHeader(),
                  const SizedBox(height: 20),
                  const Text(
                    'Smart Schedule Calendar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'All scheduled treatments, month by month.',
                    style: TextStyle(fontSize: 13.5, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 16),
                  ScheduleMonthCalendar(steps: steps, plantTag: 'All plants'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}