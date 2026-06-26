import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/expense_provider.dart';
import '../../data/models/expense_model.dart';
import 'expense_form.dart';

class ExpenseList extends StatelessWidget {
  final ExpenseState state;

  const ExpenseList({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final items = state.filteredSelectedDateExpenses;
    final formatter = DateFormat('yyyy-MM-dd');

    if (items.isEmpty) {
      return Center(
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
              '${formatter.format(DateTime(state.year, state.month, state.day))}\nNo transactions',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _ExpenseListTile(expense: item);
      },
    );
  }
}

class _ExpenseListTile extends ConsumerWidget {
  final ExpenseModel expense;

  const _ExpenseListTile({required this.expense});

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
        content: Text('Delete "${expense.title}"?'),
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

  Text? _buildSubTitle(BuildContext context) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(expense.occurredAt);
    final details = expense.content?.isNotEmpty == true
        ? expense.content!
        : expense.category;
    final subtitle = details == null || details.isEmpty
        ? timestamp
        : '$details\n$timestamp';

    return Text(
      subtitle,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF6B707A),
        height: 1.45,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = expense.isIncome;
    final amountColor =
        isIncome ? const Color(0xFF43A047) : const Color(0xFFE53935);
    final amountPrefix = isIncome ? '+' : '-';
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        minVerticalPadding: 16,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isIncome
              ? const Color(0xFF43A047).withOpacity(0.1)
              : const Color(0xFFE53935).withOpacity(0.1),
          radius: 28,
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: amountColor,
            size: 30,
          ),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        subtitle: _buildSubTitle(context),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$amountPrefix${formatter.format(expense.amountInDollars)}',
              style: TextStyle(
                fontSize: 20,
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
