import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../design_system/design_system.dart';
import '../models/topic_filter.dart';
import '../providers/expense_provider.dart';
import '../theme/ledger_style.dart';
import '../widgets/expense/expense_filter_sheet.dart';
import '../widgets/expense/expense_overview.dart';
import '../widgets/expense_list.dart';
import '../widgets/summary_drawer.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  final bool chromeVisible;
  final ValueChanged<bool>? onChromeVisibilityChanged;

  const ExpenseScreen({
    super.key,
    this.chromeVisible = true,
    this.onChromeVisibilityChanged,
  });

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSummaryDrawer(BuildContext context) {
    widget.onChromeVisibilityChanged?.call(false);
    Scaffold.of(context).openDrawer();
  }

  void _navigateToPrevMonth(DateTime current) {
    ref
        .read(expenseNotifierProvider.notifier)
        .changeMonth(DateTime(current.year, current.month - 1));
  }

  void _navigateToNextMonth(DateTime current) {
    ref
        .read(expenseNotifierProvider.notifier)
        .changeMonth(DateTime(current.year, current.month + 1));
  }

  Future<void> _pickMonth(DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && mounted) {
      ref
          .read(expenseNotifierProvider.notifier)
          .changeMonth(DateTime(picked.year, picked.month));
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ExpenseFilterSheet(),
    );
  }

  void _selectToday() {
    final now = DateTime.now();
    ref
        .read(expenseNotifierProvider.notifier)
        .selectDate(now.year, now.month, now.day);
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        ref.read(expenseNotifierProvider.notifier).searchExpenses('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseNotifierProvider);
    final focusedMonth = state.focusedMonth;
    final hasFilter =
        state.activeFilter != null || state.topicFilter is! TopicFilterAll;

    return Scaffold(
      backgroundColor: LedgerStyle.background,
      drawer: const SummaryDrawer(),
      onDrawerChanged: (isOpen) {
        if (!isOpen) widget.onChromeVisibilityChanged?.call(true);
      },
      appBar: AppBar(
        backgroundColor: LedgerStyle.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.space_dashboard_outlined, size: 21),
            tooltip: 'Summary',
            onPressed: () => _openSummaryDrawer(context),
          ),
        ),
        title: _isSearching
            ? _SearchField(controller: _searchController)
            : TextButton(
                onPressed: () => _pickMonth(focusedMonth),
                style: TextButton.styleFrom(
                  foregroundColor: LedgerStyle.ink,
                  padding: EdgeInsets.zero,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        DateFormat('MMMM yyyy').format(focusedMonth),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PiggyType.pageTitle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  ],
                ),
              ),
        actions: [
          IconButton(
            tooltip: _isSearching ? 'Close search' : 'Search transactions',
            icon: Icon(
              _isSearching ? Icons.close : Icons.search_rounded,
              size: 23,
            ),
            onPressed: _toggleSearch,
          ),
          IconButton(
            tooltip: 'Filter transactions',
            icon: Badge(
              isLabelVisible: hasFilter,
              backgroundColor: LedgerStyle.accent,
              child: const Icon(Icons.tune_rounded, size: 21),
            ),
            onPressed: _showFilterDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(state, focusedMonth),
    );
  }

  Widget _buildBody(ExpenseState state, DateTime focusedMonth) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: LedgerStyle.accent),
      );
    }
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(PiggySpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: PiggySpace.lg),
              FilledButton(
                onPressed: () =>
                    ref.read(expenseNotifierProvider.notifier).refresh(),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return ExpenseList(
      state: state,
      chromeVisible: widget.chromeVisible,
      onChromeVisibilityChanged: widget.onChromeVisibilityChanged,
      headerSlivers: [
        SliverToBoxAdapter(
          child: ExpenseOverview(
            state: state,
            onToday: _selectToday,
            onPreviousMonth: () => _navigateToPrevMonth(focusedMonth),
            onNextMonth: () => _navigateToNextMonth(focusedMonth),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends ConsumerWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextField(
        controller: controller,
        autofocus: true,
        style: const TextStyle(fontSize: 16, color: LedgerStyle.ink),
        cursorColor: LedgerStyle.accent,
        decoration: const InputDecoration(
          hintText: 'Search this day',
          hintStyle: TextStyle(color: LedgerStyle.secondary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (query) =>
            ref.read(expenseNotifierProvider.notifier).searchExpenses(query),
      );
}
