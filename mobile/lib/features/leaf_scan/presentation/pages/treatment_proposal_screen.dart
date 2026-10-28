import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:digisaka/shared/components/app_bar_widget.dart';
import 'package:digisaka/shared/navigation/shell_scope.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/shared/models/leaf_stage.dart';
import 'package:digisaka/shared/models/history_cycle.dart';
import 'package:digisaka/shared/models/treatment_history.dart';
import 'package:digisaka/shared/models/treatment_proposal.dart';
import 'package:digisaka/shared/models/fungicide_product.dart';
import 'package:digisaka/features/history/data/history_store.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/proposal_calendar.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/proposal_timeline.dart';
import 'package:digisaka/features/leaf_scan/presentation/widgets/up_next_card.dart';
import 'package:digisaka/features/notification/presentation/pages/notifications_screen.dart';
import 'package:digisaka/features/smart_schedule/data/smart_schedule_store.dart';
import 'package:digisaka/features/shell/presentation/pages/main_shell.dart';

/// Screen showing the bulk treatment proposal and schedule per Figma
/// "bogart-ai-proposal-awaiting 2" (Screenshot 2).
///
/// Reflects the treatment decision: the title comes from the selected product,
/// and an optional reviewer note is shown read-only once a decision is made.
/// On Approve this screen registers the bulk with ScheduleStore and saves the
/// cycle as applied in HistoryStore; Reject saves the cycle as rejected. The
/// resulting state ([TreatmentProposalStatus.approved] or [rejected]) is
/// reflected on this screen, which also shows a "Back to Home" button.
class TreatmentProposalScreen extends StatefulWidget {
  final List<LeafAssessment> leaves;
  final String bulkId;
  final String line;
  final String isoWeek;
  final String? note;
  final TreatmentProposalStatus? status;
  final TreatmentProposalStatus? initialStatus;
  final TreatmentHistory? treatmentHistory;
  final FungicideProduct? selectedProduct;
  final DateTime? selectedDate;

  const TreatmentProposalScreen({
    super.key,
    required this.leaves,
    required this.bulkId,
    required this.line,
    required this.isoWeek,
    this.note,
    this.status,
    this.initialStatus,
    this.treatmentHistory,
    this.selectedProduct,
    this.selectedDate,
  });

  @override
  State<TreatmentProposalScreen> createState() =>
      _TreatmentProposalScreenState();
}

class _TreatmentProposalScreenState extends State<TreatmentProposalScreen> {
  late TreatmentProposalStatus _currentStatus;
  late final TextEditingController _noteController;
  final ScrollController _scrollController = ScrollController();

  DateTime? _windowStart;
  DateTime? _windowEnd;
  bool _treatmentDone = false;

  TreatmentProposalStatus get _status => _currentStatus;

  /// The note to display: the typed value when present, otherwise the passed
  /// in note (e.g. the reviewer's note from DecisionScreen).
  String? get _effectiveNote {
    final typed = _noteController.text.trim();
    return typed.isNotEmpty ? typed : widget.note;
  }

  @override
  void initState() {
    super.initState();
    _currentStatus =
        widget.initialStatus ?? widget.status ?? TreatmentProposalStatus.proposed;
    _noteController = TextEditingController(text: widget.note);

    // Build the proposal window from leaf data. The title is overridden by
    // the selected product name when provided; the window uses selectedDate
    // when given, falling back to the mock June 15-17 dates.
    final treatmentLeaves = widget.leaves.where((l) => l.stage.isTreatment).toList();
    if (treatmentLeaves.isNotEmpty) {
      // Capture the getter in a local so Dart promotes it through the null
      // checks below (getters aren't promoted through ternaries).
      final selectedDate = widget.selectedDate;
      final windowStart = selectedDate ?? DateTime(2026, 6, 15);
      final windowEnd = selectedDate != null
          ? selectedDate.add(const Duration(days: 2))
          : DateTime(2026, 6, 17);
      _windowStart = windowStart;
      _windowEnd = windowEnd;

      _proposal = TreatmentProposal(
        title: widget.selectedProduct?.name ?? 'Protectant fungicide spray',
        windowStart: windowStart,
        windowEnd: windowEnd,
        reason: 'The disease is getting worse and rainfall is favourable for it.',
        status: _currentStatus,
        note: widget.note,
      );
      _treatmentDone = _proposal!.treatmentDone;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  TreatmentProposal? _proposal;

  bool get _rejected => _status == TreatmentProposalStatus.rejected;
  bool get _approved => _status == TreatmentProposalStatus.approved;

  void _handleBackToHome() {
    final shell = ShellScope.maybeOf(context);
    if (shell != null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      shell.changeTab(0);
    } else {
      // Fallback when this screen is reached outside the shell: replace the
      // whole stack with MainShell so the back stack stays clean.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    }
  }

  void _goToNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  /// Toggle the "Treatment" timeline item done state.
  void _toggleTreatmentDone() {
    setState(() {
      _treatmentDone = !_treatmentDone;
      _proposal = _proposal?.copyWith(treatmentDone: _treatmentDone);
    });
  }

  /// Approve the proposal: register the bulk and mark the cycle applied in the
  /// stores, then switch to the approved state, scroll to the top and show the
  /// confirmation snackbar. The UI switches to approved even if a store call
  /// fails (failures are logged only). Ignored if already approved (double-tap
  /// guard).
  void _handleApprove() {
    if (_currentStatus == TreatmentProposalStatus.approved) {
      return;
    }
    try {
      HistoryStore.instance.upsertCycle(
        HistoryCycle(
          line: widget.line,
          isoWeek: widget.isoWeek,
          bulkId: widget.bulkId,
          leaves: widget.leaves,
          status: HistoryStatus.applied,
          windowStart: _windowStart ?? DateTime(2026, 6, 15),
          windowEnd: _windowEnd ?? DateTime(2026, 6, 17),
        ),
      );
      ScheduleStore.instance.registerBulk(
        bulkId: widget.bulkId,
        plantName: widget.line,
        leaves: widget.leaves,
        selectedProduct: widget.selectedProduct,
        selectedDate: widget.selectedDate,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : widget.note,
      );
    } catch (e) {
      debugPrint('Approve store error: $e');
    }
    setState(() {
      _currentStatus = TreatmentProposalStatus.approved;
      _proposal = _proposal?.copyWith(status: TreatmentProposalStatus.approved);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treatment approved and scheduled'),
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  /// Reject the proposal: save the rejected cycle to HistoryStore and switch
  /// to the rejected state.
  void _handleReject() {
    if (_currentStatus == TreatmentProposalStatus.rejected) {
      return;
    }
    try {
      HistoryStore.instance.upsertCycle(
        HistoryCycle(
          line: widget.line,
          isoWeek: widget.isoWeek,
          bulkId: widget.bulkId,
          leaves: widget.leaves,
          status: HistoryStatus.rejected,
          windowStart: _windowStart ?? DateTime(2026, 6, 15),
          windowEnd: _windowEnd ?? DateTime(2026, 6, 17),
        ),
      );
    } catch (e) {
      debugPrint('Reject store error: $e');
    }
    setState(() {
      _currentStatus = TreatmentProposalStatus.rejected;
      _proposal = _proposal?.copyWith(status: TreatmentProposalStatus.rejected);
    });
  }

  /// Status banner shown under the subtitle.
  Widget _buildStatusBanner() {
    Color bg;
    Color text;
    String label;
    Widget leading;
    if (_status == TreatmentProposalStatus.proposed) {
      bg = const Color(0xFFE3F1EE);
      text = const Color(0xFF1E7D3A);
      label = 'Proposed — awaiting your decision';
      leading = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFF1E7D3A),
          borderRadius: BorderRadius.circular(3),
        ),
      );
    } else if (_status == TreatmentProposalStatus.approved) {
      bg = const Color(0xFFE3F1EE);
      text = const Color(0xFF1E7D3A);
      label = 'Approved — apply during the treatment window';
      leading = const Icon(Icons.check_box, size: 20, color: Color(0xFF1E7D3A));
    } else {
      bg = const Color(0xFFFDECEA);
      text = const Color(0xFFB3261E);
      label = 'Rejected — no treatment scheduled';
      leading = const Icon(Icons.cancel, size: 18, color: Color(0xFFB3261E));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: text.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Proposal card: title, dates, reason, and (when proposed) the Note field
  /// plus Reject/Approve buttons. Once approved or rejected, the note (if any)
  /// is shown read-only and the decision buttons are hidden.
  Widget _buildProposalCard() {
    if (_proposal == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE3E8E1), width: 1),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No treatment proposal needed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This line has no leaves requiring treatment at this time.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      );
    }

    final proposed = _status == TreatmentProposalStatus.proposed;
    final rejected = _status == TreatmentProposalStatus.rejected;
    final approved = _status == TreatmentProposalStatus.approved;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E8E1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _proposal!.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Apply ${_formatDate(_proposal!.windowStart)} to ${_formatDate(_proposal!.windowEnd)} - next assessment week of ${_formatDate(_proposal!.windowStart)}',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _proposal!.reason,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textDark,
            ),
          ),
          if (proposed) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Note (optional)',
                hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD5DAD2), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD5DAD2), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD5DAD2), width: 1),
                ),
              ),
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _handleReject,
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFB3261E),
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB3261E),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _handleApprove,
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if ((approved || rejected) &&
              _effectiveNote != null &&
              _effectiveNote!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              _effectiveNote!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// "Back to Home" primary button, shown only after Approve or Reject.
  Widget _buildBackToHomeButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF22A055), AppColors.darkGreen],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: GestureDetector(
        onTap: _handleBackToHome,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: const Text(
            'Back to Home',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Treatment Schedule',
        onNotificationsPressed: _goToNotifications,
      ),
      backgroundColor: const Color(0xFFF3F5F2),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _proposal?.title ?? 'Protectant fungicide spray',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              Text(
                '${widget.line} · ${widget.isoWeek}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 24),

              _buildStatusBanner(),
              const SizedBox(height: 16),

              _buildProposalCard(),
              if (_proposal != null) ...[
                const SizedBox(height: 24),

                ProposalCalendar(
                  month: DateTime(2026, 6, 1),
                  line: widget.line,
                  scanDate: DateTime(2026, 6, 8),
                  windowStart: _proposal!.windowStart,
                  windowEnd: _proposal!.windowEnd,
                  reassessmentDate: DateTime(2026, 6, 15),
                  rejected: _rejected,
                ),
                const SizedBox(height: 24),

                UpNextCard(
                  line: widget.line,
                  scanDate: DateTime(2026, 6, 8),
                  windowStart: _proposal!.windowStart,
                  windowEnd: _proposal!.windowEnd,
                  rejected: _rejected,
                ),
                const SizedBox(height: 24),

                ProposalTimeline(
                  monthYear: 'June 2026',
                  status: _approved
                      ? TimelineStatus.approved
                      : _rejected
                          ? TimelineStatus.rejected
                          : TimelineStatus.proposed,
                  doneCount: _treatmentDone ? 1 : 0,
                  totalCount: 2,
                  onToggleDone: _toggleTreatmentDone,
                ),
                const SizedBox(height: 16),

                if (_status != TreatmentProposalStatus.proposed) ...[
                  _buildBackToHomeButton(),
                  const SizedBox(height: 16),
                ],
              ],

              const Center(
                child: Text(
                  'AI-assisted scheduling should be verified by an agricultural '
                  'specialist before treatment decisions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
