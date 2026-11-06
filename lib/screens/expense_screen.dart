import '../widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../design_system/design_system.dart';
import '../models/topic_filter.dart';
import '../providers/expense_provider.dart';
import '../providers/core_providers.dart';
import '../widgets/create_piggy_dialog.dart';
import '../theme/ledger_style.dart';
import '../widgets/expense/expense_filter_sheet.dart';
import '../widgets/expense/expense_overview.dart';
import '../widgets/expense_list.dart';
import '../widgets/summary_drawer.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  final bool chromeVisible;
  final ValueChanged<bool>? onChromeVisibilityChanged;
  final VoidCallback? onAddExpense;
  final ValueChanged<bool>? onAddButtonDockedChanged;

  const ExpenseScreen({
    super.key,
    this.chromeVisible = true,
    this.onChromeVisibilityChanged,
    this.onAddExpense,
    this.onAddButtonDockedChanged,
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
    final picked = await showPiggyDatePicker(
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
    showPiggySheet<void>(
      context: context,
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
    final topics = ref.watch(myViewableTopicsProvider);
    final hasTopics = topics.valueOrNull?.isNotEmpty ?? false;
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
                onPressed: hasTopics ? () => _pickMonth(focusedMonth) : null,
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
            onPressed: hasTopics ? _toggleSearch : null,
          ),
          IconButton(
            tooltip: 'Filter transactions',
            icon: Badge(
              isLabelVisible: hasTopics && hasFilter,
              backgroundColor: LedgerStyle.accent,
              child: const Icon(Icons.tune_rounded, size: 21),
            ),
            onPressed: hasTopics ? _showFilterDialog : null,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: topics.when(
        loading: () => const AppLoadingIndicator(showLogo: false),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Couldn’t load your piggies.'),
              TextButton(
                onPressed: () => ref.invalidate(myViewableTopicsProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (items) =>
            items.isEmpty ? _buildNoPiggies() : _buildBody(state, focusedMonth),
      ),
    );
  }

  Widget _buildNoPiggies() => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 120),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 44,
                backgroundColor: PiggyColors.accentSoft,
                child: Icon(
                  Icons.savings_outlined,
                  size: 44,
                  color: PiggyColors.accent,
                ),
              ),
              const SizedBox(height: PiggySpace.xl),
              const Text(
                'A fresh start for your spending',
                style: PiggyType.pageTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: PiggySpace.sm),
              const Text(
                'You don’t have any piggies yet.\nCreate one to start tracking your expenses.',
                style: PiggyType.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: PiggySpace.xl),
              FilledButton.icon(
                onPressed: () => showCreatePiggyDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create a piggy'),
              ),
            ],
          ),
        ),
      );

  Widget _buildBody(ExpenseState state, DateTime focusedMonth) {
    if (state.isLoading) {
      return const AppLoadingIndicator(showLogo: false);
    }
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(PiggySpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.error!,
                textAlign: TextAlign.center,
              ),
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
      onAddExpense: widget.onAddExpense,
      onAddButtonDockedChanged: widget.onAddButtonDockedChanged,
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
