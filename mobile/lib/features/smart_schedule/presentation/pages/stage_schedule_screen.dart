import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/shared/widgets/dashed_rrect_painter.dart';
import '../widgets/schedule_month_calendar.dart';
import '../widgets/schedule_widgets.dart';
import '../../domain/models/smart_schedule_models.dart';
import '../../data/smart_schedule_store.dart';
import 'treatment_details_screen.dart';

const Color _kRed = Color(0xFFD32F2F);
const Color _kRedSoft = Color(0xFFFCEEEE);
const Color _kRedBorder = Color(0xFFE57373);

String _stageDescription(LeafStage stage) {
  switch (stage) {
    case LeafStage.stage1:
      return 'Early Treatment Consideration';
    case LeafStage.stage2:
      return 'Developing Treatment Consideration';
    case LeafStage.stage3:
      return 'Treatment Window Consideration';
    case LeafStage.stage4:
      return 'Priority Treatment Consideration';
    default:
      return 'Treatment Consideration';
  }
}

/// Detailed schedule of one stage inside one bulk.
class StageScheduleScreen extends StatelessWidget {
  final String bulkId;
  final LeafStage stage;

  const StageScheduleScreen({
    super.key,
    required this.bulkId,
    required this.stage,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ScheduleStore.instance,
      builder: (context, _) {
        final bulk = ScheduleStore.instance.bulkById(bulkId);
        final scheduled = bulk?.stageOf(stage);

        if (bulk == null || scheduled == null) {
          return const Scaffold(
            backgroundColor: kScheduleBg,
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScheduleHeader(),
                    SizedBox(height: 24),
                    Text(
                      'This schedule could not be found.',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: kScheduleBg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScheduleHeader(),
                  const SizedBox(height: 20),
                  _title(),
                  const SizedBox(height: 14),
                  _generatedPill(),
                  const SizedBox(height: 16),
                  ScheduleMonthCalendar(
                    steps: scheduled.steps,
                    plantTag: bulk.plantTag,
                  ),
                  const SizedBox(height: 22),
                  const ScheduleSectionLabel('UP NEXT'),
                  const SizedBox(height: 10),
                  _upNext(scheduled),
                  const SizedBox(height: 24),
                  _timelineHeader(scheduled),
                  const SizedBox(height: 14),
                  for (var i = 0; i < scheduled.steps.length; i++)
                    _timelineRow(
                      context,
                      bulk,
                      scheduled,
                      scheduled.steps[i],
                      isLast: i == scheduled.steps.length - 1,
                    ),
                  const SizedBox(height: 10),
                  if (scheduled.nextStep != null) ...[
                    const ScheduleSectionLabel('NEXT SUGGESTED ACTION'),
                    const SizedBox(height: 10),
                    _suggestedCard(context, scheduled.nextStep!),
                    const SizedBox(height: 24),
                  ],
                  const ScheduleSectionLabel('TREATMENT ROTATION'),
                  const SizedBox(height: 10),
                  _rotationCard(),
                  const SizedBox(height: 24),
                  const ScheduleSectionLabel('TREATMENT HISTORY'),
                  const SizedBox(height: 10),
                  ..._historyCards(bulk.historyFor(scheduled)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- top section ----------

  Widget _title() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Black Sigatoka — Stage ${stage.index}',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_stageDescription(stage)} · Stage-specific schedule',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your schedule is automatically generated based on the AI-assisted assessment and available treatment information.',
          style: TextStyle(fontSize: 13.5, color: AppColors.textGrey, height: 1.4),
        ),
      ],
    );
  }

  Widget _generatedPill() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD3E8D8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_box, size: 16, color: Color(0xFF22A055)),
          SizedBox(width: 8),
          Text(
            'Schedule Generated',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- UP NEXT ----------

  Widget _upNext(ScheduledStage scheduled) {
    final step = scheduled.nextStep;

    if (step == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kCardShadow,
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF22A055), size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'All treatment steps are completed for this stage.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final overdue = step.overdueDays;
    final isOverdue = overdue > 0;
    final dateText = formatLongDate(step.date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue ? _kRedSoft : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isOverdue ? _kRedBorder : kScheduleBorder),
        boxShadow: isOverdue
            ? const [
                BoxShadow(
                  color: Color(0x33E53935),
                  blurRadius: 14,
                  offset: Offset(0, 3),
                ),
              ]
            : kCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isOverdue ? const Color(0xFFF9DADA) : kBeige,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_fire_department,
              color: isOverdue ? const Color(0xFFE53935) : const Color(0xFF9A6B3A),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UP NEXT',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isOverdue ? '${step.title} — Missed' : step.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Scheduled on $dateText',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                  ),
                ),
                if (isOverdue) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFADBD8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department,
                            size: 13, color: _kRed),
                        const SizedBox(width: 4),
                        Text(
                          '$overdue DAY${overdue == 1 ? '' : 'S'} OVERDUE',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _kRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  isOverdue
                      ? "This was scheduled for ${formatMonthDay(step.date)} and hasn't been marked done yet. Please complete it as soon as possible."
                      : 'Complete this step on or around the scheduled date.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- timeline ----------

  Widget _timelineHeader(ScheduledStage scheduled) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${formatMonthYear(DateTime.now())} — Detailed Timeline',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFD3E8D8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            TimelineStep.doneCount(scheduled.steps),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _timelineRow(
    BuildContext context,
    ScheduledBulk bulk,
    ScheduledStage scheduled,
    TimelineStep step, {
    required bool isLast,
  }) {
    final color = stepColor(step.type);

    final node = Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: step.done ? const Color(0xFF22A055) : color,
          width: 2,
        ),
      ),
      child: step.done
          ? const Icon(Icons.check, size: 12, color: Color(0xFF22A055))
          : Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                node,
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(width: 2, color: kScheduleBorder),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatShortDate(step.date),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _stepCard(context, bulk, scheduled, step),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard(
    BuildContext context,
    ScheduledBulk bulk,
    ScheduledStage scheduled,
    TimelineStep step,
  ) {
    final bool isLog = step.type == StepType.diseaseLogged;
    final Color titleColor = (step.type == StepType.oil)
        ? const Color(0xFF9A6B00)
        : (step.type == StepType.fungicide)
            ? const Color(0xFF2B4FA8)
            : AppColors.textDark;
    final proof = step.proofImagePath;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          if (step.subtitle != null && step.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              step.subtitle!,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
            ),
          ],
          if (!isLog) ...[
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: step.done
                  ? null
                  : () => _onMarkDone(context, bulk, scheduled, step),
              child: Row(
                children: [
                  Icon(
                    step.done ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 22,
                    color: step.done
                        ? const Color(0xFF22A055)
                        : AppColors.textGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    step.done ? 'Done' : 'Mark as done',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!isLog && step.requiresPhotoProof && !step.done) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.photo_camera, size: 13, color: Color(0xFFE5674A)),
                SizedBox(width: 6),
                Text(
                  'Photo proof required',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE5674A),
                  ),
                ),
              ],
            ),
          ],
          if (step.done && proof != null && proof.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(proof),
                height: 80,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onMarkDone(
    BuildContext context,
    ScheduledBulk bulk,
    ScheduledStage scheduled,
    TimelineStep step,
  ) {
    if (!step.requiresPhotoProof) {
      ScheduleStore.instance.markStepDone(bulk.id, scheduled.stage, step.id);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProofSheet(
        stepTitle: step.title,
        onConfirm: (path) => ScheduleStore.instance.markStepDone(
          bulk.id,
          scheduled.stage,
          step.id,
          proofImagePath: path,
        ),
      ),
    );
  }

  // ---------- suggested / rotation / history ----------

  Widget _suggestedCard(BuildContext context, TimelineStep next) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC93C), Color(0xFFF5A623)],
              ),
            ),
            child: const Text(
              'SUGGESTED TREATMENT',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A3300),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SUGGESTED WINDOW',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
              Text(
                formatLongDate(next.date),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STATUS',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1CC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Suggested — Not Yet Confirmed',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7A5A00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ScheduleOutlineButton(
            label: 'View Details',
            onTap: () async {
              final confirmed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => TreatmentDetailsScreen(suggestedDate: next.date),
                ),
              );
              if (confirmed == true && context.mounted) {
                // TODO: store the confirmation (Suggested -> Confirmed).
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Treatment confirmed')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _rotationCard() {
    // TODO: only show when 2+ consecutive applications share a FRAC group.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBEAE4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0B8A8)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFE08A1E), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rotation Check',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD9573A),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Review consecutive applications from the same FRAC group.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF8A4B3C),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _historyCards(List<TreatmentRecord> records) {
    if (records.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: kCardShadow,
          ),
          child: const Text(
            'No treatments recorded yet.',
            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
        ),
      ];
    }

    return [
      for (final r in records)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: kCardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: r.kind == StepType.oil
                      ? const Color(0xFFF5B83D)
                      : const Color(0xFF3B6FD4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  r.kind == StepType.oil ? Icons.water_drop : Icons.science,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatShortDateYear(r.date),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _statusLine(r.status),
                  ],
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _statusLine(StepStatus status) {
    final String text;
    final Color color;
    switch (status) {
      case StepStatus.done:
        text = '✓ Completed';
        color = const Color(0xFF22A055);
        break;
      case StepStatus.missed:
        text = 'Missed';
        color = _kRed;
        break;
      case StepStatus.upcoming:
        text = 'Upcoming';
        color = const Color(0xFFB7791F);
        break;
    }
    return Row(
      children: [
        const Text(
          'Field A · ',
          style: TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// Proof of treatment bottom sheet
// ======================================================================

class _ProofSheet extends StatefulWidget {
  final String stepTitle;
  final ValueChanged<String> onConfirm;

  const _ProofSheet({required this.stepTitle, required this.onConfirm});

  @override
  State<_ProofSheet> createState() => _ProofSheetState();
}

class _ProofSheetState extends State<_ProofSheet> {
  String? _path;

  Future<void> _pick() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file != null && mounted) setState(() => _path = file.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera or gallery.')),
      );
    }
  }

  void _confirm() {
    final path = _path;
    if (path == null) return;
    widget.onConfirm(path);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        22,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.photo_camera, color: AppColors.textDark, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Proof of Treatment Required',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a photo showing the ${widget.stepTitle} treatment was applied before marking this step as done.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pick,
              child: CustomPaint(
                foregroundPainter: const DashedRRectPainter(),
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8F3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: path == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_camera,
                                size: 34, color: AppColors.textGrey),
                            SizedBox(height: 8),
                            Text(
                              'Tap to upload a photo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'JPG or PNG',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(File(path), fit: BoxFit.cover),
                        ),
                ),
              ),
            ),
            if (path == null) ...[
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 15, color: Color(0xFFE5674A)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "This step can't be checked off without a photo.",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE5674A),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ScheduleOutlineButton(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ScheduleGradientButton(
                    label: 'Confirm & Mark Done',
                    enabled: path != null,
                    onTap: _confirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}