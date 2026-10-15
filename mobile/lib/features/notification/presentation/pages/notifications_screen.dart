import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace this hardcoded list with real data later.
    final List<_NotificationData> notifications = [
      _NotificationData(
        icon: Icons.opacity,
        iconColor: AppColors.accentYellow,
        title: 'Oil application scheduled for tomorrow.',
        subtitle: 'Field A · 2h ago',
      ),
      _NotificationData(
        icon: Icons.notifications,
        iconColor: AppColors.accentYellow,
        title: 'Upcoming Black Sigatoka treatment for Field A.',
        subtitle: 'Yesterday',
      ),
      _NotificationData(
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.accentYellow,
        title: 'Treatment schedule needs review.',
        subtitle: '2 days ago',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F2),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildNotificationCard(notifications[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Notifications" title on the left, circular X close button on the right.
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFF3F5F2),
              child: const Icon(Icons.close, color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(_NotificationData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E9D8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No notifications yet',
        style: TextStyle(color: AppColors.textGrey, fontSize: 14),
      ),
    );
  }
}

/// Small internal model just to keep the hardcoded list above tidy.
class _NotificationData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  _NotificationData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}