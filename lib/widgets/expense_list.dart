import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../theme/ledger_style.dart';
import '../design_system/design_system.dart';
import '../providers/core_providers.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import 'expense_form.dart';
import 'topic_picker.dart';

class ExpenseList extends ConsumerWidget {
  final ExpenseState state;
  final List<Widget> headerSlivers;
  final VoidCallback onAdd;

  const ExpenseList({
    super.key,
    required this.state,
    required this.onAdd,
    this.headerSlivers = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = state.filteredSelectedDateExpenses;
    final date = DateTime(state.year, state.month, state.day);
    final now = DateTime.now();
    final today =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final net = items.fold<int>(
      0,
      (sum, item) => sum + (item.isIncome ? item.amount : -item.amount),
    );
    final money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final filtered = state.searchQuery.isNotEmpty || state.activeFilter != null;

    return RefreshIndicator(
      color: LedgerStyle.accent,
      onRefresh: () => ref.read(expenseNotifierProvider.notifier).refresh(),
      child: CustomScrollView(
        key: const PageStorageKey('expense-ledger'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ...headerSlivers,
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: PiggySpace.page),
              padding: const EdgeInsets.only(top: 20, bottom: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: LedgerStyle.line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${today ? 'Today · ' : ''}${DateFormat('MMM d').format(date)}',
                          style: PiggyType.sectionTitle,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${DateFormat('EEEE').format(date)} · ${items.length} ${items.length == 1 ? 'transaction' : 'transactions'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: LedgerStyle.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (items.isNotEmpty)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${net < 0 ? '−' : net > 0 ? '+' : ''}${money.format(net.abs() / 100)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: net < 0
                                  ? LedgerStyle.expense
                                  : LedgerStyle.income,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            filtered ? 'Filtered net' : 'Daily net',
                            style: const TextStyle(
                              fontSize: 11,
                              color: LedgerStyle.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 12),
                  PiggyAddButton(onPressed: onAdd),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: LedgerStyle.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        filtered
                            ? Icons.search_off_rounded
                            : Icons.receipt_long_outlined,
                        size: 23,
                        color: LedgerStyle.secondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      filtered
                          ? 'No matching transactions'
                          : 'A fresh page for this day',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: LedgerStyle.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      filtered
                          ? 'Try another search or change your filters.'
                          : 'Tap + to record your first transaction.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: LedgerStyle.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: PiggySpace.page),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ExpenseListTile(
                    expense: items[index],
                    first: index == 0,
                    last: index == items.length - 1,
                  ),
                  childCount: items.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }
}

class _ExpenseListTile extends ConsumerWidget {
  final ExpenseModel expense;

  final bool first;
  final bool last;

  const _ExpenseListTile({
    required this.expense,
    required this.first,
    required this.last,
  });

  void _showEditForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExpenseForm(
        expense: expense,
        initYear: expense.occurredAt.year,
        initMonth: expense.occurredAt.month,
        initDay: expense.occurredAt.day,
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Delete "${expense.title.isEmpty ? 'No title' : expense.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(expenseNotifierProvider.notifier)
                  .deleteExpense(expense.id!);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: PiggyColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final topics = ref.watch(myViewableTopicsProvider).valueOrNull ?? const [];
    final topicName = findTopicById(topics, expense.topicId)?.title;
    final subtitle = [expense.category, topicName]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' · ');
    return PiggyTransactionRow(
      title: expense.title.isEmpty ? 'Untitled transaction' : expense.title,
      subtitle: subtitle,
      amount:
          '${expense.isIncome ? '+' : '−'}${formatter.format(expense.amountInDollars)}',
      tone: expense.isIncome ? PiggyTone.income : PiggyTone.expense,
      icon: _categoryIcon(),
      first: first,
      last: last,
      onTap: () => _showEditForm(context),
      trailing: PopupMenuButton<String>(
        tooltip: 'Transaction options',
        icon: const Icon(
          Icons.more_horiz_rounded,
          size: 18,
          color: LedgerStyle.secondary,
        ),
        onSelected: (value) {
          if (value == 'edit') _showEditForm(context);
          if (value == 'delete') _confirmDelete(context, ref);
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }

  IconData _categoryIcon() {
    if (expense.isIncome) return Icons.south_west_rounded;
    final category = expense.category?.toLowerCase() ?? '';
    if (category.contains('food') || category.contains('식')) {
      return Icons.restaurant_rounded;
    }
    if (category.contains('coffee') ||
        category.contains('cafe') ||
        category.contains('카페')) {
      return Icons.local_cafe_outlined;
    }
    if (category.contains('transport') || category.contains('교통')) {
      return Icons.directions_transit_rounded;
    }
    if (category.contains('shop') || category.contains('쇼핑')) {
      return Icons.shopping_bag_outlined;
    }
    return Icons.receipt_long_outlined;
  }
}
