import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:digisaka/features/notification/presentation/pages/notifications_screen.dart';
import 'package:digisaka/features/auth/presentation/pages/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // TODO: Replace these with real user data later.
  final String _initials = 'JD';
  final String _fullName = 'Juan Dela Cruz';
  final String _farmLocation = 'Sitio Malabo Banana Farm · Balayan, Batangas';

  bool _notificationsEnabled = true;

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _goToNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F2),
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        // This is what makes the whole page scrollable.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(),
              const SizedBox(height: 24),

              _buildSectionLabel('ACCOUNT'),
              const SizedBox(height: 10),
              _buildListItem(
                icon: Icons.person_outline,
                label: 'User Information',
                onTap: () => _showMessage('User Information tapped'),
              ),
              const SizedBox(height: 10),
              _buildListItem(
                icon: Icons.eco_outlined,
                label: 'Farm Information',
                onTap: () => _showMessage('Farm Information tapped'),
              ),
              const SizedBox(height: 24),

              _buildSectionLabel('PREFERENCES'),
              const SizedBox(height: 10),
              _buildToggleItem(
                icon: Icons.notifications_none,
                label: 'Notifications',
                value: _notificationsEnabled,
                onChanged: (value) => setState(() => _notificationsEnabled = value),
              ),
              const SizedBox(height: 10),
              _buildListItem(
                icon: Icons.language,
                label: 'Language',
                trailingText: 'English',
                onTap: () => _showMessage('Language tapped'),
              ),
              const SizedBox(height: 24),

              _buildSectionLabel('SUPPORT'),
              const SizedBox(height: 10),
              _buildListItem(
                icon: Icons.info_outline,
                label: 'About Bogart AI',
                onTap: () => _showMessage('About Digisaka tapped'),
              ),
              const SizedBox(height: 10),
              _buildListItem(
                icon: Icons.help_outline,
                label: 'Help & Support',
                onTap: () => _showMessage('Help & Support tapped'),
              ),
              const SizedBox(height: 24),

              _buildLogoutButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// "My Profile" title on the left, bell icon on the right.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      titleSpacing: 20,
      title: const Text(
        'My Profile',
        style: TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
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

  /// Green gradient card with the avatar initials, name, and farm location.
  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.55),
            AppColors.accentYellow.withOpacity(0.25),
          ],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primaryGreen,
            child: Text(
              _initials,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _fullName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _farmLocation,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  /// Small grey uppercase heading like "ACCOUNT", "PREFERENCES", "SUPPORT".
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.textGrey,
        letterSpacing: 0.5,
      ),
    );
  }

  /// A white row with a small icon tile, a label, and either a
  /// trailing chevron or an optional trailing text (like "English").
  Widget _buildListItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _buildIconTile(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText,
                  style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
                const SizedBox(width: 4),
              ],
              const Icon(Icons.chevron_right, color: AppColors.textGrey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Same style as _buildListItem but with a Switch instead of a chevron.
  Widget _buildToggleItem({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildIconTile(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  /// The small rounded cream-colored square behind each row's icon.
  Widget _buildIconTile(IconData icon) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF3E9D8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.primaryGreen, size: 20),
    );
  }

  /// Red-ish "Log Out" row, styled differently from normal settings items
  /// so it's clearly not just another preference.
  Widget _buildLogoutButton() {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _confirmLogout,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 14),
              const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Asks "are you sure?" before actually logging out, so a stray tap
  /// doesn't kick the user out by accident.
  Future<void> _confirmLogout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // Clears the whole navigation stack so the user can't press back
    // into the app after logging out.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}