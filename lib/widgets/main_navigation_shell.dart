import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/design_system.dart';
import '../providers/expense_provider.dart';
import '../providers/core_providers.dart';
import '../screens/amount_entry_screen.dart';
import '../screens/expense_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/share_screen.dart';

/// Owns the app's primary destinations and the floating navigation chrome.
class MainNavigationShell extends ConsumerStatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainNavigationShell({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  bool _chromeVisible = true;
  bool _addButtonDocked = false;

  @override
  void didUpdateWidget(covariant MainNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _chromeVisible = true;
      _addButtonDocked = false;
    }
  }

  void _setChromeVisible(bool visible) {
    if (_chromeVisible == visible || widget.currentIndex != 0) return;
    setState(() => _chromeVisible = visible);
  }

  void _setAddButtonDocked(bool docked) {
    if (_addButtonDocked == docked || widget.currentIndex != 0) return;
    setState(() => _addButtonDocked = docked);
  }

  void _selectDestination(int index) {
    if (!_chromeVisible) setState(() => _chromeVisible = true);
    widget.onTap(index);
  }

  void _showAddExpenseForm() {
    final state = ref.read(expenseNotifierProvider);
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AmountEntryScreen(
          initYear: state.year,
          initMonth: state.month,
          initDay: state.day,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: widget.currentIndex,
          children: [
            ExpenseScreen(
              chromeVisible: _chromeVisible,
              onChromeVisibilityChanged: _setChromeVisible,
              onAddExpense: _showAddExpenseForm,
              onAddButtonDockedChanged: _setAddButtonDocked,
            ),
            const ShareScreen(),
            const SettingsScreen(),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: widget.currentIndex == 0 &&
                (ref.watch(myViewableTopicsProvider).valueOrNull?.isNotEmpty ??
                    false)
            ? PiggySlideVisibility(
                visible: _chromeVisible && !_addButtonDocked,
                hiddenOffset: const Offset(0, 1.4),
                child: PiggyFloatingAddButton(
                  key: const ValueKey('floating-add-expense'),
                  heroTag: 'expense_add_fab',
                  onPressed: _showAddExpenseForm,
                ),
              )
            : null,
        bottomNavigationBar: PiggySlideVisibility(
          visible: _chromeVisible,
          child: AppNavigationBar(
            currentIndex: widget.currentIndex,
            onTap: _selectDestination,
          ),
        ),
      );
}

class AppNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavigationBar({
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
