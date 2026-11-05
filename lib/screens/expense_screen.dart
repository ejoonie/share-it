import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../theme/ledger_style.dart';
import '../design_system/design_system.dart';
import '../providers/core_providers.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import '../models/topic_filter.dart';
import '../models/topic_model.dart';
import '../widgets/expense_calendar.dart';
import '../widgets/expense_list.dart';
import '../widgets/summary_drawer.dart';
import 'amount_entry_screen.dart';

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
    Scaffold.of(context).openDrawer();
  }

  void _navigateToPrevMonth(DateTime current) {
    final prev = DateTime(current.year, current.month - 1);
    ref.read(expenseNotifierProvider.notifier).changeMonth(prev);
  }

  void _navigateToNextMonth(DateTime current) {
    final next = DateTime(current.year, current.month + 1);
    ref.read(expenseNotifierProvider.notifier).changeMonth(next);
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(expenseNotifierProvider);
          final current = state.activeFilter;
          final topicFilter = state.topicFilter;
          final topicsAsync = ref.watch(myViewableTopicsProvider);

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _FilterTile(
                      label: 'All',
                      selected: current == null,
                      onTap: () {
                        ref
                            .read(expenseNotifierProvider.notifier)
                            .filterExpenses(null);
                        Navigator.pop(context);
                      },
                    ),
                    _FilterTile(
                      label: 'Expense',
                      selected: current == ExpenseType.expense,
                      onTap: () {
                        ref
                            .read(expenseNotifierProvider.notifier)
                            .filterExpenses(ExpenseType.expense);
                        Navigator.pop(context);
                      },
                    ),
                    _FilterTile(
                      label: 'Income',
                      selected: current == ExpenseType.income,
                      onTap: () {
                        ref
                            .read(expenseNotifierProvider.notifier)
                            .filterExpenses(ExpenseType.income);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Topics',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        topicsAsync.maybeWhen(
                          data: (topics) {
                            if (topics.isEmpty) return const SizedBox.shrink();
                            final allSelected = topics
                                .every((t) => topicFilter.isSelected(t.id));
                            return TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: LedgerStyle.accent,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => ref
                                  .read(expenseNotifierProvider.notifier)
                                  .filterByTopics(
                                    allSelected
                                        ? const TopicFilterNone()
                                        : TopicFilterSelected(
                                            topics.map((t) => t.id).toSet(),
                                          ),
                                  ),
                              child: Text(
                                allSelected ? 'Unselect All' : 'Select All',
                              ),
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    topicsAsync.when(
                      data: (topics) => _TopicFilterList(
                        topics: topics,
                        topicFilter: topicFilter,
                        onChanged: (next) => ref
                            .read(expenseNotifierProvider.notifier)
                            .filterByTopics(next),
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Failed to load topics',
                          style: TextStyle(color: Colors.red.shade400),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddExpenseForm(int year, int month, int day) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AmountEntryScreen(
          initYear: year,
          initMonth: month,
          initDay: day,
        ),
      ),
    );
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
      appBar: AppBar(
        backgroundColor: LedgerStyle.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.space_dashboard_outlined, size: 21),
            tooltip: 'Summary',
            onPressed: () => _openSummaryDrawer(ctx),
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
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
                onChanged: (q) => ref
                    .read(expenseNotifierProvider.notifier)
                    .searchExpenses(q),
              )
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
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(expenseNotifierProvider.notifier).searchExpenses('');
                }
              });
            },
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: IgnorePointer(
        ignoring: !widget.chromeVisible,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          offset: widget.chromeVisible ? Offset.zero : const Offset(0, 1.4),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: widget.chromeVisible ? 1 : 0,
            child: FloatingActionButton(
              heroTag: 'expense_add_fab',
              tooltip: 'Add transaction',
              elevation: 3,
              highlightElevation: 1,
              onPressed: () =>
                  _showAddExpenseForm(state.year, state.month, state.day),
              child: const Icon(Icons.add_rounded, size: 27),
            ),
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: LedgerStyle.accent),
            )
          : state.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => ref
                              .read(expenseNotifierProvider.notifier)
                              .refresh(),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : ExpenseList(
                  state: state,
                  chromeVisible: widget.chromeVisible,
                  onChromeVisibilityChanged: widget.onChromeVisibilityChanged,
                  headerSlivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          PiggySpace.page,
                          PiggySpace.md,
                          PiggySpace.page,
                          0,
                        ),
                        child: Column(
                          children: [
                            _DailySummary(state: state),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Calendar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                      color: LedgerStyle.secondary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: LedgerStyle.accent,
                                    minimumSize: const Size(48, 44),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onPressed: () {
                                    final now = DateTime.now();
                                    ref
                                        .read(expenseNotifierProvider.notifier)
                                        .selectDate(
                                          now.year,
                                          now.month,
                                          now.day,
                                        );
                                  },
                                  child: const Text('Today'),
                                ),
                                IconButton(
                                  tooltip: 'Previous month',
                                  onPressed: () =>
                                      _navigateToPrevMonth(focusedMonth),
                                  icon: const Icon(
                                    Icons.chevron_left_rounded,
                                    size: 22,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Next month',
                                  onPressed: () =>
                                      _navigateToNextMonth(focusedMonth),
                                  icon: const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                            ExpenseCalendar(state: state),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _DailySummary extends StatelessWidget {
  final ExpenseState state;
  const _DailySummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final date = DateTime(state.year, state.month, state.day);
    final now = DateTime.now();
    final today = DateUtils.isSameDay(date, now);
    final income = state.selectedDateExpenses
        .where((entry) => entry.isIncome)
        .fold<int>(0, (sum, entry) => sum + entry.amount);
    final expenses = state.selectedDateExpenses
        .where((entry) => entry.isExpense)
        .fold<int>(0, (sum, entry) => sum + entry.amount);

    return PiggyDailySummaryCard(
      eyebrow: today ? 'Today' : DateFormat('EEEE').format(date),
      date: DateFormat('MMM d').format(date),
      metadata: today
          ? DateFormat('EEEE · yyyy').format(date)
          : DateFormat('yyyy').format(date),
      income: formatter.format(income / 100),
      expenses: formatter.format(expenses / 100),
    );
  }
}

class _FilterTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing:
          selected ? const Icon(Icons.check, color: LedgerStyle.accent) : null,
      onTap: onTap,
    );
  }
}

/// 토픽 멀티 선택 체크박스 목록. [topicFilter]가 [TopicFilterAll]이면 기본값(전체
/// 선택)으로 취급해 체크박스를 모두 채워 둔다.
class _TopicFilterList extends StatelessWidget {
  final List<TopicModel> topics;
  final TopicFilter topicFilter;
  final ValueChanged<TopicFilter> onChanged;

  const _TopicFilterList({
    required this.topics,
    required this.topicFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No topics', style: TextStyle(color: Colors.black45)),
      );
    }

    final allIds = topics.map((t) => t.id).toSet();

    return Column(
      children: topics.map((topic) {
        final isSelected = topicFilter.isSelected(topic.id);
        return CheckboxListTile(
          activeColor: LedgerStyle.accent,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(topic.title),
          value: isSelected,
          onChanged: (checked) {
            // 기본값(전체 선택)에서 시작하면 전체 Set에서부터 하나씩 제외해 나간다.
            final next = switch (topicFilter) {
              TopicFilterAll() => allIds.toSet(),
              TopicFilterNone() => <int>{},
              TopicFilterSelected(:final topicIds) => topicIds.toSet(),
            };
            if (checked == true) {
              next.add(topic.id);
            } else {
              next.remove(topic.id);
            }
            onChanged(TopicFilterSelected(next));
          },
        );
      }).toList(),
    );
  }
}
