import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';
import '../../data/models/expense_model.dart';
import 'expense_form.dart';

class ExpenseList extends StatelessWidget {
  final ExpenseLoaded state;

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
            Icon(Icons.receipt_long_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              '${formatter.format(state.selectedDate)}\nNo transactions',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = items[index];
        return _ExpenseListTile(expense: item);
      },
    );
  }
}

class _ExpenseListTile extends StatelessWidget {
  final ExpenseModel expense;

  const _ExpenseListTile({required this.expense});

  void _showEditForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ExpenseBloc>(),
        child: ExpenseForm(expense: expense, initialDate: expense.createdAt),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
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
              context.read<ExpenseBloc>().add(DeleteExpense(expense.id!));
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = expense.isIncome;
    final amountColor =
        isIncome ? const Color(0xFF43A047) : const Color(0xFFE53935);
    final amountPrefix = isIncome ? '+' : '-';
    final formatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isIncome
              ? const Color(0xFF43A047).withOpacity(0.1)
              : const Color(0xFFE53935).withOpacity(0.1),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: amountColor,
            size: 20,
          ),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: expense.note != null && expense.note!.isNotEmpty
            ? Text(expense.note!, style: const TextStyle(fontSize: 12))
            : expense.category != null
                ? Text(expense.category!,
                    style: const TextStyle(fontSize: 12))
                : null,
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
                if (value == 'delete') _confirmDelete(context);
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
