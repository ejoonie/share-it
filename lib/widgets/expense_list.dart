import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../theme/app_theme.dart';
import '../providers/core_providers.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import 'expense_form.dart';
import 'topic_picker.dart';

class ExpenseList extends ConsumerStatefulWidget {
  final ExpenseState state;

  const ExpenseList({super.key, required this.state});

  @override
  ConsumerState<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends ConsumerState<ExpenseList> {
  final Map<int, GlobalKey> _tileKeys = {};
  final Set<int> _pendingReadIds = {};
  Timer? _readDebounce;
  int? _lastHandledHighlightId;

  GlobalKey _keyFor(int id) => _tileKeys.putIfAbsent(id, () => GlobalKey());

  @override
  void dispose() {
    _readDebounce?.cancel();
    super.dispose();
  }

  void _onEntryVisible(int id) {
    _pendingReadIds.add(id);
    _readDebounce?.cancel();
    _readDebounce = Timer(const Duration(milliseconds: 600), _flushPendingReads);
  }

  void _flushPendingReads() {
    if (_pendingReadIds.isEmpty) return;
    final ids = Set<int>.from(_pendingReadIds);
    _pendingReadIds.clear();
    ref.read(expenseNotifierProvider.notifier).markEntriesRead(ids);
  }

  void _scrollToHighlighted(int id) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctx = _tileKeys[id]?.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && ref.read(highlightedEntryIdProvider) == id) {
          ref.read(highlightedEntryIdProvider.notifier).state = null;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.state.filteredSelectedDateExpenses;
    final formatter = DateFormat('yyyy-MM-dd');
    final highlightedId = ref.watch(highlightedEntryIdProvider);

    if (highlightedId != null && highlightedId != _lastHandledHighlightId) {
      _lastHandledHighlightId = highlightedId;
      _scrollToHighlighted(highlightedId);
    }

    Future<void> onRefresh() =>
        ref.read(expenseNotifierProvider.notifier).refresh();

    return Column(
      children: [
        if (items.isEmpty)
          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${formatter.format(DateTime(widget.state.year, widget.state.month, widget.state.day))}\nNo transactions',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final id = item.id;
                  final tile = _ExpenseListTile(
                    key: id != null ? _keyFor(id) : null,
                    expense: item,
                    highlighted: id != null && id == highlightedId,
                  );
                  if (id == null) return tile;
                  return VisibilityDetector(
                    key: Key('expense-visibility-$id'),
                    onVisibilityChanged: (info) {
                      if (info.visibleFraction > 0.6 && !item.read) {
                        _onEntryVisible(id);
                      }
                    },
                    child: tile,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ExpenseListTile extends ConsumerStatefulWidget {
  final ExpenseModel expense;
  final bool highlighted;

  const _ExpenseListTile({super.key, required this.expense, this.highlighted = false});

  @override
  ConsumerState<_ExpenseListTile> createState() => _ExpenseListTileState();
}

class _ExpenseListTileState extends ConsumerState<_ExpenseListTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _lift;
  late final Animation<Color?> _tint;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _lift = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -14.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -14.0, end: 0.0).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 65,
      ),
    ]).animate(_controller);
    _tint = ColorTween(
      begin: AppTheme.primaryColor.withValues(alpha: 0.25),
      end: Colors.white,
    ).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0)));

    if (widget.highlighted) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _ExpenseListTile old) {
    super.didUpdateWidget(old);
    if (widget.highlighted && !old.highlighted) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showEditForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExpenseForm(
        expense: widget.expense,
        initYear: widget.expense.occurredAt.year,
        initMonth: widget.expense.occurredAt.month,
        initDay: widget.expense.occurredAt.day,
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final expense = widget.expense;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete "${expense.title.isEmpty ? 'No title' : expense.title}"?'),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Text? _buildSubTitle(BuildContext context, String? topicName) {
    final expense = widget.expense;
    if (expense.content != null && expense.content!.isNotEmpty) {
      return Text('${expense.content!}\n${topicName ?? ''}',
          style: const TextStyle(fontSize: 10));
    } else if (expense.category != null) {
      return Text('${expense.category!}\n${topicName ?? ''}',
          style: const TextStyle(fontSize: 10));
    } else {
      return Text(topicName ?? '', style: const TextStyle(fontSize: 10));
    }
  }

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    final isIncome = expense.isIncome;
    final amountColor = isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
    final amountPrefix = isIncome ? '+' : '';
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final topics = ref.watch(myViewableTopicsProvider).valueOrNull ?? const [];
    final topicName = findTopicById(topics, expense.topicId)?.title;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _lift.value),
        child: Card(
          margin: EdgeInsets.zero,
          color: widget.highlighted ? _tint.value : null,
          child: child,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isIncome
              ? AppTheme.incomeColor.withValues(alpha: 0.1)
              : AppTheme.expenseColor.withValues(alpha: 0.1),
          child: Icon(
            isIncome
                ? Icons.account_balance_wallet_outlined
                : Icons.receipt_long_outlined,
            color: amountColor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            if (!expense.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            Expanded(
              child: Text(
                expense.title.isEmpty ? 'No title' : expense.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: _buildSubTitle(context, topicName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$amountPrefix${formatter.format(expense.amountInDollars)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _showEditForm(context);
                if (value == 'delete') _confirmDelete(context, ref);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        onTap: () => _showEditForm(context),
      ),
    );
  }
}
