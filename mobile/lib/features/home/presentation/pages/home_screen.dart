import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:digisaka/features/notification/presentation/pages/notifications_screen.dart';
import 'package:digisaka/features/smart_schedule/presentation/pages/smart_schedule_screen.dart'; // FIX: needed for SmartScheduleScreen

class HomeScreen extends StatefulWidget {
  /// Asks the MainShell to switch tabs (1 = History, 2 = Scan).
  final ValueChanged<int>? onTabChange;

  const HomeScreen({super.key, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _userName = 'Juan';
  final String _location = 'Sitio Malabo, Balayan, Batangas';

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
      backgroundColor: const Color(0xFFF3F5F2), // light grey-green page background
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
              const SizedBox(height: 40),
              _buildFarmOverviewHeader(),
              const SizedBox(height: 14),
              _buildFarmOverviewStats(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Top bar: logo + "Digisaka" title on the left, bell icon on the right.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco, color: AppColors.white, size: 20),
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
            backgroundColor: const Color(0xFFF3F5F2),
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
                radius: 22,
                backgroundColor: Color(0xFFEFEFEF),
                child: Icon(Icons.person, color: AppColors.textGrey),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good afternoon, $_userName!',
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
                            _location,
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
          child: RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 13.5, color: AppColors.textDark, height: 1.4),
              children: [
                TextSpan(text: 'Next Suggested Action\n'),
                TextSpan(
                  text: 'Leaf Monitoring',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                ),
                TextSpan(text: ' · Tomorrow · Plant #001'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Two big green buttons: Scan Leaf and Bulk History.
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.center_focus_strong,
            label: 'SCAN LEAF',
            onTap: _goToLeafScan,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildActionButton(
            icon: Icons.description_outlined,
            label: 'BULK HISTORY',
            onTap: _goToHistory,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.primaryGreen,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 110,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.white, size: 30),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Farm Overview" title + "View Bulks →" link.
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
            'View Bulks →',
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

  /// Row of 3 stat cards: Leaves Scanned, Bulks Assessed, Need Treatment.
  Widget _buildFarmOverviewStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('24', 'Leaves\nScanned')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('8', 'Bulks\nAssessed')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('3', 'Need\nTreatment')),
      ],
    );
  }

  Widget _buildStatCard(String number, String label) {
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
        children: [
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
}