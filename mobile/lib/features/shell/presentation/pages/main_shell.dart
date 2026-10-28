import 'package:flutter/material.dart';
import 'package:digisaka/features/shell/presentation/widgets/app_bottom_nav.dart';
import 'package:digisaka/features/home/presentation/pages/home_screen.dart';
import 'package:digisaka/features/history/presentation/pages/history_screen.dart';
import 'package:digisaka/features/leaf_scan/presentation/pages/line_insights_screen.dart';
import 'package:digisaka/features/profile/presentation/pages/profile_screen.dart';
import 'package:digisaka/shared/navigation/shell_scope.dart';

/// The main container of the app. It owns the ONE bottom nav bar.
/// Only the body above the nav bar animates when you switch tabs;
/// the nav bar itself stays perfectly still.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // 1 = the new page slides in from the right, -1 = from the left.
  double _direction = 1;

  late final AnimationController _controller;
  late final Animation<double> _animation;

  // Key of the Scan tab's own Navigator (see _ScanFlow at the bottom).
  final GlobalKey<NavigatorState> _scanNavKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1, // start fully visible (no animation on first load)
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changeTab(int index) {
    if (index == _currentIndex) {
      // Tapping Scan while already on Scan goes back to the first Leaf Scan
      // page (closes Validation / Result).
      if (index == 2) {
        _scanNavKey.currentState?.popUntil((route) => route.isFirst);
      }
      return;
    }
    setState(() {
      _direction = index > _currentIndex ? 1 : -1;
      _currentIndex = index;
    });
    _controller.forward(from: 0); // play the page transition
  }

  @override
  Widget build(BuildContext context) {
    // On Android, pressing Back on any other tab returns to Home
    // instead of closing the app.
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _changeTab(0);
      },
      child: ShellScope(
        changeTab: _changeTab,
        child: Scaffold(
          // Only the body is animated. The nav bar is outside of it.
          body: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: _animation.value.clamp(0.0, 1.0),
                child: FractionalTranslation(
                  translation: Offset(_direction * 0.10 * (1 - _animation.value), 0),
                  child: child,
                ),
              );
            },
            // IndexedStack keeps Home, History and Profile alive
            // (scroll position, toggles, etc. are remembered).
            child: IndexedStack(
              index: _currentIndex,
              children: [
                HomeScreen(onTabChange: _changeTab),
                HistoryScreen(onGoHome: () => _changeTab(0)),
                // Built only while selected, so the camera is released
                // when you leave the Scan tab.
                // The Scan tab has its own Navigator, so Validation and Result
                // open INSIDE the tab and the nav bar below stays visible.
                _currentIndex == 2
                    ? _ScanFlow(navKey: _scanNavKey)
                    : const SizedBox.shrink(),
                const ProfileScreen(),
              ],
            ),
          ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: _currentIndex,
            onTap: _changeTab,
          ),
        ),
      ),
    );
  }
}

/// A small Navigator that lives inside the Scan tab.
/// Leaf Scan is its first page; Validation and Result are pushed on top of it,
/// but they stay inside the tab, above the shell's nav bar.
class _ScanFlow extends StatelessWidget {
  final GlobalKey<NavigatorState> navKey;

  const _ScanFlow({required this.navKey});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navKey,
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => const LineInsightsScreen(),
      ),
    );
  }
}