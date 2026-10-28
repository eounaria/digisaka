import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:digisaka/features/notification/presentation/pages/notifications_screen.dart';
import 'package:digisaka/features/smart_schedule/presentation/pages/smart_schedule_screen.dart'; // FIX: needed for SmartScheduleScreen

// ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
// Demo data — replace with real data (user profile, farm stats, proposals)
// once the backing APIs are wired up. Kept in one place so they can be
// swapped without touching the layout.
// ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈

const String _kUserName = 'Juan';
const String _kLocation = 'Sitio Malabo, Balayan, Batangas';

const int _kLeavesScanned = 49;
const int _kLineWeeksAssessed = 5;
const int _kAwaitingDecisions = 2;

enum _ProposalStatus { awaitingDecision, applied }

class _Proposal {
  const _Proposal({
    required this.line,
    required this.week,
    required this.status,
  });

  final String line;
  final String week;
  final _ProposalStatus status;
}

extension _ProposalStatusExtension on _ProposalStatus {
  String get label {
    switch (this) {
      case _ProposalStatus.awaitingDecision:
        return 'Awaiting decision';
      case _ProposalStatus.applied:
        return 'Applied';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _ProposalStatus.awaitingDecision:
        return AppColors.pillAwaitingDecisionBackground;
      case _ProposalStatus.applied:
        return AppColors.pillAppliedBackground;
    }
  }

  Color get textColor {
    switch (this) {
      case _ProposalStatus.awaitingDecision:
        return AppColors.pillAwaitingDecisionText;
      case _ProposalStatus.applied:
        return AppColors.pillAppliedText;
    }
  }
}

const List<_Proposal> _kRecentProposals = <_Proposal>[
  _Proposal(line: 'Line L03', week: '2026-W24', status: _ProposalStatus.awaitingDecision),
  _Proposal(line: 'Line L05', week: '2026-W24', status: _ProposalStatus.awaitingDecision),
  _Proposal(line: 'Line L02', week: '2026-W23', status: _ProposalStatus.applied),
];

class HomeScreen extends StatefulWidget {
  /// Asks the MainShell to switch tabs (1 = History, 2 = Scan).
  final ValueChanged<int>? onTabChange;

  const HomeScreen({super.key, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _goToLeafScan() => widget.onTabChange?.call(2);

  void _goToNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _goToHistory() => widget.onTabChange?.call(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingCard(),
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 24),
              _buildFarmOverviewHeader(),
              const SizedBox(height: 14),
              _buildFarmOverviewStats(),
              const SizedBox(height: 24),
              _buildFarmOverviewCaption(),
              const SizedBox(height: 24),
              _buildRecentProposals(),
              const SizedBox(height: 26), // keeps the last card clear of the bottom nav
            ],
          ),
        ),
      ),
    );
  }

  /// Top bar: logo + "Bogart AI" title on the left, bell icon on the right.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco, color: AppColors.white, size: 22),
          ),
          const SizedBox(width: 10),
          const Text(
            'Bogart AI',
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.pageBackground,
            child: IconButton(
              icon: const Icon(Icons.notifications_none, color: AppColors.primaryGreen),
              onPressed: _goToNotifications,
            ),
          ),
        ),
      ],
    );
  }

  /// White card: greeting, location, Smart Schedule row, and next suggested action.
  Widget _buildGreetingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.avatarBackground,
                child: Icon(Icons.person, color: AppColors.textDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good afternoon, $_kUserName!',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _kLocation,
                            style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderGrey),
          const SizedBox(height: 16),
          _buildSmartScheduleRow(),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderGrey),
          const SizedBox(height: 14),
          _buildNextSuggestedAction(),
        ],
      ),
    );
  }

  /// "Smart Schedule" row with the yellow calendar icon.
  Widget _buildSmartScheduleRow() {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SmartScheduleScreen()),
        );
      },
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.accentYellow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_month, color: AppColors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Schedule',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'AI-assisted, rule-based monitoring & treatment plan',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textGrey),
        ],
      ),
    );
  }

  /// The small "Next Suggested Action" line with a green dot.
  Widget _buildNextSuggestedAction() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          height: 8,
          width: 8,
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Next Suggested Action',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Leaf Monitoring - Tomorrow - Plant # 001',
                style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Two big green buttons side by side: Disease Detection and Diagnosis History.
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            title: 'Disease Detection',
            subtitle: 'Scan banana leaves',
            onTap: _goToLeafScan,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildActionButton(
            title: 'Diagnosis History',
            subtitle: 'Review weeks & proposals',
            onTap: _goToHistory,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.primaryGreen,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 105,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _scanFrameIcon(iconColor: AppColors.white, size: 32),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The round scan frame with a bold "A" in the center
  /// (Icons.crop_free as the frame). ~32dp, drawn in [iconColor].
  Widget _scanFrameIcon({required Color iconColor, double size = 32}) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.crop_free, color: iconColor, size: size * 0.78),
          Text(
            'A',
            style: TextStyle(
              color: iconColor,
              fontSize: size * 0.36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// "Farm Overview" title + "View history →" link (opens History, tab 1).
  Widget _buildFarmOverviewHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Farm Overview',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        GestureDetector(
          onTap: _goToHistory,
          child: const Text(
            'View history →',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  /// Row of 3 stat cards: Leaves Scanned, Line-weeks Assessed, Awaiting Decision.
  Widget _buildFarmOverviewStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            chipBackground: AppColors.chipBlueBackground,
            chipIcon: AppColors.chipBlueIcon,
            chipIconData: Icons.add,
            number: _kLeavesScanned.toString(),
            label: 'Leaves\nScanned',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            chipBackground: AppColors.chipPurpleBackground,
            chipIcon: AppColors.chipPurpleIcon,
            chipIconData: Icons.description_outlined,
            number: _kLineWeeksAssessed.toString(),
            label: 'Line-weeks\nAssessed',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            chipBackground: AppColors.chipOrangeBackground,
            chipIcon: AppColors.chipOrangeIcon,
            chipIconData: Icons.warning_amber_rounded,
            number: _kAwaitingDecisions.toString(),
            label: 'Awaiting\nDecision',
          ),
        ),
      ],
    );
  }

  /// One stat card: icon chip, big number, two-line label.
  Widget _buildStatCard({
    required Color chipBackground,
    required Color chipIcon,
    required IconData chipIconData,
    required String number,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: chipBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(chipIconData, color: chipIcon, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey, height: 1.3),
          ),
        ],
      ),
    );
  }

  /// Small grey caption under the stat cards.
  Widget _buildFarmOverviewCaption() {
    return Text(
      'Counts cover closed weeks across 6 lines.\n1 line needs human review.',
      style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey, height: 1.4),
    );
  }

  /// "Recent proposals" section: a vertical list of tappable proposal cards.
  Widget _buildRecentProposals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent proposals',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 12),
        for (final proposal in _kRecentProposals) ...[
          _buildProposalCard(proposal),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// One proposal card: line + week on the left, status pill on the right.
  Widget _buildProposalCard(_Proposal proposal) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: AppColors.white,
          child: InkWell(
            onTap: () {
              // TODO: open the proposal detail screen once it exists
              // (no destination screen yet — do not invent one).
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proposal.line,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          proposal.week,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: proposal.status.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      proposal.status.label,
                      style: TextStyle(
                        color: proposal.status.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
}
