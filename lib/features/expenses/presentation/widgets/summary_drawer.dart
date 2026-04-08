import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/expense_provider.dart';
import '../../data/models/expense_model.dart';

class SummaryDrawer extends ConsumerWidget {
  const SummaryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseNotifierProvider);
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Drawer(
      child: SafeArea(
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
                  if (!state.isLoading)
                    Text(
                      DateFormat('MMM yyyy').format(state.focusedMonth),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            if (state.isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _SummaryTile(
                icon: Icons.arrow_downward,
                iconColor: const Color(0xFF43A047),
                label: 'Total Income',
                value: formatter.format(state.monthlyIncomeTotal / 100.0),
                valueColor: const Color(0xFF43A047),
              ),
              const Divider(indent: 16, endIndent: 16),
              _SummaryTile(
                icon: Icons.arrow_upward,
                iconColor: const Color(0xFFE53935),
                label: 'Total Expense',
                value: formatter.format(state.monthlyExpenseTotal / 100.0),
                valueColor: const Color(0xFFE53935),
              ),
              const Divider(indent: 16, endIndent: 16),
              _SummaryTile(
                icon: Icons.account_balance_wallet,
                iconColor: Colors.blueGrey,
                label: 'Net Balance',
                value: formatter.format(
                  (state.monthlyIncomeTotal - state.monthlyExpenseTotal) /
                      100.0,
                ),
                valueColor:
                    state.monthlyIncomeTotal >= state.monthlyExpenseTotal
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
                  expenses: state.monthlyExpenses,
                  formatter: formatter,
                ),
              ),
            ],
          ],
        ),
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
              title:
                  Text(entry.key, style: const TextStyle(fontSize: 14)),
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
