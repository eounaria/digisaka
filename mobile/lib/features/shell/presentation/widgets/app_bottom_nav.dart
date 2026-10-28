import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Reusable bottom navigation bar. It does NOT navigate by itself;
/// it only reports which tab was tapped through [onTap].
///
/// Indexes: 0 = Home, 1 = History, 2 = Scan, 3 = Profile
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.primaryGreen,
      height: 70,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            label: 'Home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
          ),
          _buildNavItem(
            index: 1,
            label: 'History',
            icon: Icons.description_outlined,
            activeIcon: Icons.description,
          ),
          _buildScanItem(),
          _buildNavItem(
            index: 3,
            label: 'Profile',
            icon: Icons.person_outlined,
            activeIcon: Icons.person,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final bool isSelected = currentIndex == index;
    final Color color = isSelected ? AppColors.white : AppColors.white.withValues(alpha: 0.7);

    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// The Scan tab item. It uses the same scan-frame "A" icon as the home
  /// action buttons (see HomeScreen._ScanFrameIcon), rendered here as a
  /// regular tab item instead of a floating button above the bar.
  Widget _buildScanItem() {
    final bool isSelected = currentIndex == 2;
    final Color color = isSelected ? AppColors.white : AppColors.white.withValues(alpha: 0.7);

    return InkWell(
      onTap: () => onTap(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 26,
            width: 26,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.crop_free, color: color, size: 22),
                Text(
                  'A',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scan',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
