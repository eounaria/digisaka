import 'package:flutter/material.dart';

import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/components/app_bar_widget.dart';
import 'package:digisaka/features/history/data/history_store.dart';
import 'package:digisaka/features/notification/presentation/pages/notifications_screen.dart';
import 'package:digisaka/shared/models/history_cycle.dart';

/// Diagnosis History screen per Figma "bogart-ai-diagnosis-history 1" (Screenshot 1).
///
/// Shows one card per line (L01–L06, always, even when empty). Each card's
/// header shows the line name, the last cycle's subtitle ("No cycles yet" or
/// "Last cycle 2026-W24: awaiting decision") and a trash icon to clear the line. Below the
/// header are the line's most recent proposal cycles (newest first, up to 3).
/// Listens to [HistoryStore] so newly saved scans appear immediately.
class HistoryScreen extends StatefulWidget {
  /// Kept for compatibility with [MainShell], which switches back to Home.
  final VoidCallback? onGoHome;

  const HistoryScreen({super.key, this.onGoHome});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const List<String> _lines = ['L01', 'L02', 'L03', 'L04', 'L05', 'L06'];

  void _goToNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  /// Confirm then clear all cycles for [line].
  Future<void> _confirmDeleteLine(String line) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete all history for Line $line?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      HistoryStore.instance.clearLine(line);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'History',
        onNotificationsPressed: _goToNotifications,
      ),
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: HistoryStore.instance,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diagnosis History',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your completed scans, grouped by line, newest first.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final line in _lines)
                    _LineCard(
                      line: line,
                      cycles: HistoryStore.instance.cyclesForLine(line),
                      onDelete: () => _confirmDeleteLine(line),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One line card: header (line name, last-cycle subtitle, trash) plus proposal rows.
class _LineCard extends StatelessWidget {
  final String line;
  final List<HistoryCycle> cycles;
  final VoidCallback onDelete;

  const _LineCard({
    required this.line,
    required this.cycles,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final last = cycles.isNotEmpty ? cycles.first : null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: light-green tile, line name, subtitle, trash icon.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emptyPhotoTileFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.eco,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Line $line',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      last == null
                          ? 'No cycles yet'
                          : 'Last cycle ${last.isoWeek}: ${last.status.label}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.textGrey,
                  size: 20,
                ),
                onPressed: cycles.isEmpty ? null : onDelete,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Proposal rows (newest first, up to 3) or empty placeholder.
          if (cycles.isEmpty)
            const Text(
              'No proposals yet.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
              ),
            )
          else ...cycles.take(3).map((cycle) => _ProposalRow(cycle: cycle)),
        ],
      ),
    );
  }
}

/// One proposal cycle row.
///
/// TODO: make tappable to open this cycle's TreatmentProposalScreen (read-only
/// when applied/rejected). Opening TreatmentProposalScreen read-only is out of
/// scope for this slice, so rows are intentionally non-tappable for now.
class _ProposalRow extends StatelessWidget {
  final HistoryCycle cycle;

  const _ProposalRow({required this.cycle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                cycle.isoWeek,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                cycle.status.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
          if (cycle.windowStart != null && cycle.windowEnd != null) ...[
            const SizedBox(height: 4),
            Text(
              '${_formatDate(cycle.windowStart!)} – ${_formatDate(cycle.windowEnd!)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textGrey,
              ),
            ),
          ],
          if (cycle.status == HistoryStatus.applied &&
              cycle.appliedDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Applied ${_formatDate(cycle.appliedDate!)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}
