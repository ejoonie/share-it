import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import 'expense_form.dart';

class ExpenseList extends StatelessWidget {
  final ExpenseState state;

  const ExpenseList({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final items = state.filteredSelectedDateExpenses;
    final formatter = DateFormat('yyyy-MM-dd');

    return Column(
      children: [
        // Padding(
        //   padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       const Text(
        //         'Recent Transactions',
        //         style: TextStyle(
        //           fontSize: 15,
        //           fontWeight: FontWeight.w600,
        //           color: Color(0xFF1A1A1A),
        //         ),
        //       ),
        //       TextButton(
        //         onPressed: () {},
        //         style: TextButton.styleFrom(
        //           foregroundColor: AppTheme.primaryColor,
        //           padding: const EdgeInsets.symmetric(horizontal: 8),
        //           minimumSize: Size.zero,
        //           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        //         ),
        //         child: const Text('View All', style: TextStyle(fontSize: 13)),
        //       ),
        //     ],
        //   ),
        // ),
        if (items.isEmpty)
          Expanded(
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
                    '${formatter.format(DateTime(state.year, state.month, state.day))}\nNo transactions',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = items[index];
                return _ExpenseListTile(expense: item);
              },
            ),
          ),
      ],
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
    final debug = expense.occurredAt.toIso8601String();
    if (expense.content != null && expense.content!.isNotEmpty) {
      return Text('${expense.content!}\n${debug}', style: const TextStyle(fontSize: 10));
    } else if (expense.category != null) {
      return Text('${expense.category!}\n${debug}', style: const TextStyle(fontSize: 10));
    } else {
      return Text('${debug}', style: const TextStyle(fontSize: 10));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = expense.isIncome;
    final amountColor =
        isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
    final amountPrefix = isIncome ? '+' : '';
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isIncome
              ? AppTheme.incomeColor.withOpacity(0.1)
              : AppTheme.expenseColor.withOpacity(0.1),
          child: Icon(
            isIncome ? Icons.account_balance_wallet_outlined : Icons.receipt_long_outlined,
            color: amountColor,
            size: 20,
          ),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: _buildSubTitle(context),
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
