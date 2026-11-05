import 'package:flutter/material.dart';

import '../screens/expense_screen.dart';
import '../design_system/design_system.dart';
import '../screens/settings_screen.dart';
import '../screens/share_screen.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  bool _chromeVisible = true;

  @override
  void didUpdateWidget(covariant BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _chromeVisible = true;
    }
  }

  void _setChromeVisible(bool visible) {
    if (_chromeVisible == visible || widget.currentIndex != 0) return;
    setState(() => _chromeVisible = visible);
  }

  void _onTap(int index) {
    if (!_chromeVisible) setState(() => _chromeVisible = true);
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: widget.currentIndex,
        children: [
          ExpenseScreen(
            chromeVisible: _chromeVisible,
            onChromeVisibilityChanged: _setChromeVisible,
          ),
          const ShareScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: IgnorePointer(
        ignoring: !_chromeVisible,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          offset: _chromeVisible ? Offset.zero : const Offset(0, 1.08),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: _chromeVisible ? 1 : 0,
            child: LedgerNavigationBar(
              currentIndex: widget.currentIndex,
              onTap: _onTap,
            ),
          ),
        ),
      ),
    );
  }
}

class LedgerNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const LedgerNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => PiggyNavigationBar(
        selectedIndex: currentIndex,
        onSelected: onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Share',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      );
}
