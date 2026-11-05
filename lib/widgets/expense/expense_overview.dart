import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../design_system/design_system.dart';
import '../../providers/expense_provider.dart';
import '../expense_calendar.dart';

class ExpenseOverview extends StatelessWidget {
  final ExpenseState state;
  final VoidCallback onToday;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const ExpenseOverview({
    super.key,
    required this.state,
    required this.onToday,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          PiggySpace.page,
          PiggySpace.sm,
          PiggySpace.page,
          0,
        ),
        child: Column(
          children: [
            _DailySummary(state: state),
            const SizedBox(height: PiggySpace.xs),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Calendar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: PiggyColors.secondary,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: PiggyColors.accent,
                    minimumSize: const Size(48, PiggySize.tapTarget),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: onToday,
                  child: const Text('Today'),
                ),
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: onPreviousMonth,
                  icon: const Icon(Icons.chevron_left_rounded, size: 22),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right_rounded, size: 22),
                ),
              ],
            ),
            ExpenseCalendar(state: state),
            const SizedBox(height: PiggySpace.sm),
          ],
        ),
      );
}

class _DailySummary extends StatelessWidget {
  final ExpenseState state;
  const _DailySummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final date = DateTime(state.year, state.month, state.day);
    final today = DateUtils.isSameDay(date, DateTime.now());
    final income = state.selectedDateExpenses
        .where((entry) => entry.isIncome)
        .fold<int>(0, (sum, entry) => sum + entry.amount);
    final expenses = state.selectedDateExpenses
        .where((entry) => entry.isExpense)
        .fold<int>(0, (sum, entry) => sum + entry.amount);

    return PiggyDailySummaryCard(
      eyebrow: today ? 'Today' : 'Selected',
      date: DateFormat('d').format(date),
      metadata: DateFormat('EEE').format(date),
      income: formatter.format(income / 100),
      expenses: formatter.format(expenses / 100),
    );
  }
}
