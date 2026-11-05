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

class ExpenseList extends ConsumerStatefulWidget {
  final ExpenseState state;
  final List<Widget> headerSlivers;
  final bool chromeVisible;
  final ValueChanged<bool>? onChromeVisibilityChanged;

  const ExpenseList({
    super.key,
    required this.state,
    this.chromeVisible = true,
    this.onChromeVisibilityChanged,
    this.headerSlivers = const [],
  });

  @override
  ConsumerState<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends ConsumerState<ExpenseList> {
  static const _hideThreshold = 28.0;
  static const _showThreshold = 16.0;
  final ScrollController _scrollController = ScrollController();
  double _lastOffset = 0;
  double _directionDistance = 0;
  int _direction = 0;
  late bool _chromeVisible;

  @override
  void initState() {
    super.initState();
    _chromeVisible = widget.chromeVisible;
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant ExpenseList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chromeVisible != _chromeVisible) {
      _chromeVisible = widget.chromeVisible;
      _directionDistance = 0;
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final pixels = _scrollController.position.pixels;
    final delta = pixels - _lastOffset;
    _lastOffset = pixels;

    if (pixels <= 0) {
      _direction = 0;
      _directionDistance = 0;
      _setChromeVisible(true);
      return;
    }
    if (delta.abs() < 0.5) return;

    final direction = delta > 0 ? 1 : -1;
    if (_direction != direction) {
      _direction = direction;
      _directionDistance = 0;
    }
    _directionDistance += delta.abs();
    final threshold = direction > 0 ? _hideThreshold : _showThreshold;
    if (_directionDistance >= threshold) {
      _setChromeVisible(direction < 0);
      _directionDistance = 0;
    }
  }

  void _setChromeVisible(bool visible) {
    if (_chromeVisible == visible) return;
    _chromeVisible = visible;
    widget.onChromeVisibilityChanged?.call(visible);
  }

  Future<void> _refresh() async {
    _direction = 0;
    _directionDistance = 0;
    _setChromeVisible(true);
    await ref.read(expenseNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.state.filteredSelectedDateExpenses;
    final filtered = widget.state.searchQuery.isNotEmpty ||
        widget.state.activeFilter != null;

    return RefreshIndicator(
      color: LedgerStyle.accent,
      displacement: 32,
      edgeOffset: 4,
      strokeWidth: 2.4,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        key: const PageStorageKey('expense-ledger'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ...widget.headerSlivers,
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: PiggySpace.page),
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: LedgerStyle.line)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                        color: LedgerStyle.secondary,
                      ),
                    ),
                  ),
                  Text(
                    filtered
                        ? '${items.length} shown'
                        : '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                    style: PiggyType.metadata,
                  ),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  PiggySpace.page,
                  PiggySpace.md,
                  PiggySpace.page,
                  PiggySpace.xl,
                ),
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
                          : 'No transactions for this day',
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
                          : 'Tap + to add one.',
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
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
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
      useSafeArea: true,
      showDragHandle: true,
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
