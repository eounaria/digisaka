import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';

/// Proposal status used by the timeline to decide which actions to show.
enum TimelineStatus { proposed, approved, rejected }

/// Detailed timeline shown below "Up Next".
///
/// Renders treatment / re-assessment / follow-up items as a vertical timeline
/// with colored dots. When [rejected] the action buttons are hidden and cards
/// are greyed read-only. When [approved] the treatment item shows a green
/// "Mark as done" button that toggles via [onToggleDone].
class ProposalTimeline extends StatelessWidget {
  final String monthYear;
  final TimelineStatus status;
  final int doneCount;
  final int totalCount;
  final VoidCallback? onToggleDone;

  const ProposalTimeline({
    super.key,
    required this.monthYear,
    required this.status,
    required this.doneCount,
    required this.totalCount,
    this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    final rejected = status == TimelineStatus.rejected;
    final approved = status == TimelineStatus.approved;
    final treatmentDone = doneCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$monthYear — Detailed Timeline',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryGreen, width: 1),
              ),
              child: Text(
                '$doneCount / $totalCount done',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Vertical timeline.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item 1 — Treatment (orange dot).
            _TimelineItem(
              dotColor: const Color(0xFFF59E0B),
              dotSize: 10,
              date: 'Jun 15 - Jun 17',
              title: 'Treatment',
              titleColor: const Color(0xFFF59E0B),
              body:
                  'Protectant fungicide spray. Apply between June 15, 2026 and June 17, 2026.',
              proposedLine: rejected
                  ? null
                  : approved
                      ? null
                      : 'Approve the proposal to record this treatment.',
              approved: approved,
              rejected: rejected,
              treatmentDone: treatmentDone,
              onToggleDone: approved && !treatmentDone ? onToggleDone : null,
              isLast: false,
            ),
            const SizedBox(height: 20),

            // Item 2 — Re-assessment (purple dot).
            _TimelineItem(
              dotColor: const Color(0xFF8B5CF6),
              dotSize: 10,
              date: 'Jun 15',
              title: 'Re-assessment',
              titleColor: AppColors.textDark,
              body: 'Scan this line again in the week of June 15, 2026.',
              proofLine: 'Re-assessment outcome — not available yet',
              approved: false,
              rejected: rejected,
              treatmentDone: false,
              onToggleDone: null,
              isLast: false,
            ),
            const SizedBox(height: 20),

            // "Coming later" between items.
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Coming later',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Item 3 — Follow-up (blue dot, faded, disabled checkbox).
            _TimelineItem(
              dotColor: const Color(0xFF5B8DEF),
              dotSize: 10,
              date: 'Follow-up',
              title: 'Follow-up',
              titleColor: const Color(0xFF5B8DEF),
              body: 'Follow-up steps aren\'t scheduled yet.',
              proofLine: null,
              approved: false,
              rejected: rejected,
              treatmentDone: false,
              onToggleDone: null,
              isLast: true,
              faded: true,
              disabledCheckbox: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// One timeline item: dot + date + content card.
class _TimelineItem extends StatelessWidget {
  final Color dotColor;
  final double dotSize;
  final String date;
  final String title;
  final Color titleColor;
  final String body;
  final String? proposedLine;
  final String? proofLine;
  final bool approved;
  final bool rejected;
  final bool treatmentDone;
  final VoidCallback? onToggleDone;
  final bool isLast;
  final bool faded;
  final bool disabledCheckbox;

  const _TimelineItem({
    required this.dotColor,
    required this.dotSize,
    required this.date,
    required this.title,
    required this.titleColor,
    required this.body,
    this.proposedLine,
    this.proofLine,
    this.approved = false,
    this.rejected = false,
    this.treatmentDone = false,
    this.onToggleDone,
    this.isLast = false,
    this.faded = false,
    this.disabledCheckbox = false,
  });

  @override
  Widget build(BuildContext context) {
    final bodyColor = faded
        ? AppColors.textGrey.withValues(alpha: 0.4)
        : AppColors.textGrey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dot column: dot + connecting line.
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 52,
                color: dotColor.withValues(alpha: 0.4),
              ),
          ],
        ),
        const SizedBox(width: 14),
        // Content column: date above card.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              date,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: faded
                    ? AppColors.textGrey.withValues(alpha: 0.5)
                    : titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: faded
                    ? AppColors.white.withValues(alpha: 0.5)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: faded
                      ? AppColors.borderGrey.withValues(alpha: 0.5)
                      : AppColors.borderGrey,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: bodyColor,
                      height: 1.4,
                    ),
                  ),
                  if (!rejected && proposedLine != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      proposedLine!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                  if (approved && !treatmentDone && !rejected) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: onToggleDone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Mark as done',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (treatmentDone) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryGreen,
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: AppColors.primaryGreen),
                          SizedBox(width: 6),
                          Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (disabledCheckbox) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: false,
                          onChanged: null,
                          activeColor: AppColors.primaryGreen,
                          checkColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const Text(
                          'Mark as done',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (proofLine != null && proofLine!.isNotEmpty)
                    Text(
                      proofLine!,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textGrey.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
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
}
