import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:digisaka/features/smart_schedule/presentation/widgets/schedule_widgets.dart';
import 'package:digisaka/features/smart_schedule/domain/models/smart_schedule_models.dart';

/// Details of the suggested treatment. Pops with `true` when confirmed.
class TreatmentDetailsScreen extends StatelessWidget {
  final DateTime suggestedDate;

  const TreatmentDetailsScreen({super.key, required this.suggestedDate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScheduleBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScheduleHeader(title: 'Treatment Details'),
              const SizedBox(height: 22),
              const Text(
                'Black Sigatoka',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 4),
              // TODO: replace with the real field name / size.
              const Text(
                'Field A · 2.4 ha',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: kCardShadow,
                ),
                child: Column(
                  children: [
                    _row('TREATMENT', _value('Suggested Treatment')),
                    const Divider(height: 1, color: kScheduleBorder),
                    _row('SUGGESTED DATE', _value(formatMonthDay(suggestedDate))),
                    const Divider(height: 1, color: kScheduleBorder),
                    _row(
                      'STATUS',
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1CC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Suggested',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7A5A00),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'SUGGESTED → CONFIRMED → APPLIED → FOLLOW-UP. NOTHING HERE IS ASSUMED APPLIED UNTIL YOU SAY SO.',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ScheduleOutlineButton(
                      label: 'Cancel',
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ScheduleGradientButton(
                      label: 'Confirm',
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'AI-assisted scheduling should be verified by an agricultural specialist before treatment decisions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _value(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryGreen,
      ),
    );
  }

  Widget _row(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textGrey,
            ),
          ),
          value,
        ],
      ),
    );
  }
}