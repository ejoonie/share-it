import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
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
  const ExpenseScreen({super.key});

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
                                            topics.map((t) => t.id).toSet()),
                                  ),
                              child: Text(
                                  allSelected ? 'Unselect All' : 'Select All'),
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

    return Scaffold(
      drawer: const SummaryDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Summary',
            onPressed: () => _openSummaryDrawer(ctx),
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Color(0xFF1A1A1A)),
                cursorColor: AppTheme.primaryColor,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
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
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _navigateToPrevMonth(focusedMonth),
                  ),
                  GestureDetector(
                    onTap: () => _pickMonth(focusedMonth),
                    child: Text(
                      DateFormat('MMM yyyy').format(focusedMonth),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _navigateToNextMonth(focusedMonth),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
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
            icon: const Icon(Icons.tune_outlined),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Builder(
        builder: (ctx) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: Text('Error: ${state.error}'));
          }
          return Column(
            children: [
              _MonthlySummaryBar(state: state),
              ExpenseCalendar(state: state),
              const Divider(height: 1),
              Expanded(child: ExpenseList(state: state)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showAddExpenseForm(state.year, state.month, state.day),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MonthlySummaryBar extends StatelessWidget {
  final ExpenseState state;

  const _MonthlySummaryBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final income = state.monthlyIncomeTotal / 100.0;
    final expense = state.monthlyExpenseTotal / 100.0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      // income, expense summary
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Income',
                amount: formatter.format(income),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppTheme.incomeColor,
                iconBgColor: AppTheme.incomeColor.withValues(alpha: 0.1),
                amountColor: AppTheme.incomeColor,
              ),
            ),
            Container(
                width: 1, height: 32, color: Colors.grey.shade300), // 가운데 버티컬 바
            Expanded(
              child: _SummaryCard(
                label: 'Expense',
                amount: formatter.format(expense),
                icon: Icons.receipt_long_outlined,
                iconColor: AppTheme.expenseColor,
                iconBgColor: AppTheme.expenseColor.withValues(alpha: 0.1),
                amountColor: AppTheme.expenseColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color amountColor;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          // icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          // blank
          const SizedBox(width: 12),
          // income, expense
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ],
      ),
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
          selected ? const Icon(Icons.check, color: Color(0xFF4CAF50)) : null,
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
