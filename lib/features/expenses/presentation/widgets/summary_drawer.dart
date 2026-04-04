import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/expense_bloc.dart';
import '../bloc/expense_state.dart';
import '../../data/models/expense_model.dart';

class SummaryDrawer extends StatelessWidget {
  const SummaryDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          final loaded = state is ExpenseLoaded ? state : null;
          return _SummaryDrawerBody(loadedState: loaded);
        },
      ),
    );
  }
}

class _SummaryDrawerBody extends StatelessWidget {
  final ExpenseLoaded? loadedState;

  const _SummaryDrawerBody({required this.loadedState});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final loaded = loadedState;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (loaded != null)
                  Text(
                    DateFormat('MMM yyyy').format(loaded.focusedMonth),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          if (loaded != null) ...[
            _SummaryTile(
              icon: Icons.arrow_downward,
              iconColor: const Color(0xFF43A047),
              label: 'Total Income',
              value: formatter.format(loaded.monthlyIncomeTotal / 100.0),
              valueColor: const Color(0xFF43A047),
            ),
            const Divider(indent: 16, endIndent: 16),
            _SummaryTile(
              icon: Icons.arrow_upward,
              iconColor: const Color(0xFFE53935),
              label: 'Total Expense',
              value: formatter.format(loaded.monthlyExpenseTotal / 100.0),
              valueColor: const Color(0xFFE53935),
            ),
            const Divider(indent: 16, endIndent: 16),
            _SummaryTile(
              icon: Icons.account_balance_wallet,
              iconColor: Colors.blueGrey,
              label: 'Net Balance',
              value: formatter.format(
                (loaded.monthlyIncomeTotal - loaded.monthlyExpenseTotal) /
                    100.0,
              ),
              valueColor: loaded.monthlyIncomeTotal >= loaded.monthlyExpenseTotal
                  ? const Color(0xFF43A047)
                  : const Color(0xFFE53935),
            ),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Expense by Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _CategoryBreakdown(
                expenses: loaded.monthlyExpenses,
                formatter: formatter,
              ),
            ),
          ] else
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final NumberFormat formatter;

  const _CategoryBreakdown({
    required this.expenses,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, int> catTotals = {};
    for (final e in expenses) {
      if (e.isExpense) {
        final cat = e.category ?? 'Other';
        catTotals[cat] = (catTotals[cat] ?? 0) + e.amount;
      }
    }

    if (catTotals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No expenses', style: TextStyle(color: Colors.grey)),
      );
    }

    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      children: sorted
          .map(
            (entry) => ListTile(
              dense: true,
              leading: const Icon(Icons.label_outline, size: 18),
              title: Text(entry.key, style: const TextStyle(fontSize: 14)),
              trailing: Text(
                formatter.format(entry.value / 100.0),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(label),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: valueColor,
        ),
      ),
    );
  }
}
