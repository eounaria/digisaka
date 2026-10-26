import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/features/notification/presentation/pages/notifications_screen.dart';

/// Reusable app bar matching the Home screen style: white background,
/// no elevation, green rounded-square logo tile, bold green title, and a
/// bell icon that opens [NotificationsScreen].
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onNotificationsPressed;

  const AppBarWidget({
    super.key,
    required this.title,
    required this.onNotificationsPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
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
          Text(
            title,
            style: const TextStyle(
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
              onPressed: onNotificationsPressed,
            ),
          ),
        ),
      ],
    );
  }
}
