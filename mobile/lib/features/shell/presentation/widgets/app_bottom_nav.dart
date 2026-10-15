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
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
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
            icon: Icons.person_outline,
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
    final Color color = isSelected ? AppColors.accentYellow : AppColors.white;

    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  /// The circular "Scan" button that pops up above the nav bar.
  Widget _buildScanItem() {
    final bool isSelected = currentIndex == 2;

    return InkWell(
      onTap: () => onTap(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 3),
            ),
            child: const Icon(Icons.center_focus_strong, color: AppColors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            'Scan',
            style: TextStyle(
              color: isSelected ? AppColors.accentYellow : AppColors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}