import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../design_system/design_system.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

class SummaryDrawer extends ConsumerWidget {
  const SummaryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseNotifierProvider);
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final balance = state.monthlyIncomeTotal - state.monthlyExpenseTotal;

    return Drawer(
      width: (MediaQuery.sizeOf(context).width * 0.88)
          .clamp(320.0, 380.0)
          .toDouble(),
      backgroundColor: PiggyColors.background,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(PiggyRadius.sheet),
        ),
      ),
      child: SafeArea(
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: PiggyColors.accent),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  PiggySpace.page,
                  PiggySpace.sm,
                  PiggySpace.page,
                  PiggySpace.xl,
                ),
                children: [
                  _DrawerHeader(month: state.focusedMonth),
                  const SizedBox(height: PiggySpace.lg),
                  _BalanceCard(
                    amount: formatter.format(balance / 100),
                    positive: balance >= 0,
                  ),
                  const SizedBox(height: PiggySpace.md),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryMetric(
                          label: 'Income',
                          amount: formatter.format(
                            state.monthlyIncomeTotal / 100,
                          ),
                          icon: Icons.south_west_rounded,
                          tone: PiggyTone.income,
                        ),
                      ),
                      const SizedBox(width: PiggySpace.sm),
                      Expanded(
                        child: _SummaryMetric(
                          label: 'Expenses',
                          amount: formatter.format(
                            state.monthlyExpenseTotal / 100,
                          ),
                          icon: Icons.north_east_rounded,
                          tone: PiggyTone.expense,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: PiggySpace.xl),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Spending by category',
                          style: PiggyType.sectionTitle,
                        ),
                      ),
                      Text(
                        '${state.monthlyExpenses.where((item) => item.isExpense).length} entries',
                        style: PiggyType.metadata,
                      ),
                    ],
                  ),
                  const SizedBox(height: PiggySpace.md),
                  _CategoryBreakdown(
                    expenses: state.monthlyExpenses,
                    formatter: formatter,
                  ),
                ],
              ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final DateTime month;

  const _DrawerHeader({required this.month});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MONTHLY OVERVIEW',
                  style: PiggyType.metadata.copyWith(
                    color: PiggyColors.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: PiggySpace.xs),
                Text(
                  DateFormat('MMMM').format(month),
                  style: PiggyType.pageTitle.copyWith(fontSize: 24),
                ),
                Text(
                  DateFormat('yyyy').format(month),
                  style: PiggyType.caption,
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Close summary',
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: PiggyColors.card,
              foregroundColor: PiggyColors.secondary,
            ),
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      );
}

class _BalanceCard extends StatelessWidget {
  final String amount;
  final bool positive;

  const _BalanceCard({required this.amount, required this.positive});

  @override
  Widget build(BuildContext context) => PiggySurface(
        color: PiggyColors.accentSoft,
        radius: PiggyRadius.summary,
        padding: const EdgeInsets.all(PiggySpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(PiggyRadius.small),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: PiggyColors.accent,
                  ),
                ),
                const SizedBox(width: PiggySpace.sm),
                const Text('Net balance', style: PiggyType.label),
              ],
            ),
            const SizedBox(height: PiggySpace.md),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount,
                style: PiggyType.summaryAmount.copyWith(
                  fontSize: 30,
                  color: positive ? PiggyColors.accent : PiggyColors.expense,
                ),
              ),
            ),
            const SizedBox(height: PiggySpace.xs),
            Text(
              positive
                  ? 'You kept more than you spent this month.'
                  : 'Expenses are above income this month.',
              style: PiggyType.caption,
            ),
          ],
        ),
      );
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final PiggyTone tone;

  const _SummaryMetric({
    required this.label,
    required this.amount,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) => PiggySurface(
        color: tone.background,
        radius: PiggyRadius.card,
        padding: const EdgeInsets.all(PiggySpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: tone.foreground),
                const SizedBox(width: PiggySpace.xs),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PiggyType.label.copyWith(color: tone.foreground),
                  ),
                ),
              ],
            ),
            const SizedBox(height: PiggySpace.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount,
                style: PiggyType.amount.copyWith(
                  color: tone.foreground,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
      );
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
    final totals = <String, int>{};
    for (final expense in expenses.where((item) => item.isExpense)) {
      final category = expense.category?.trim();
      final label = category == null || category.isEmpty ? 'Other' : category;
      totals[label] = (totals[label] ?? 0) + expense.amount;
    }

    if (totals.isEmpty) {
      return const PiggySurface(
        color: PiggyColors.card,
        child: Row(
          children: [
            Icon(Icons.auto_awesome_outlined, color: PiggyColors.muted),
            SizedBox(width: PiggySpace.md),
            Expanded(
              child: Text(
                'No spending recorded this month.',
                style: PiggyType.caption,
              ),
            ),
          ],
        ),
      );
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (sum, entry) => sum + entry.value);

    return PiggySurface(
      color: PiggyColors.card,
      padding: const EdgeInsets.symmetric(vertical: PiggySpace.xs),
      child: Column(
        children: [
          for (var index = 0; index < sorted.length; index++) ...[
            _CategoryRow(
              category: sorted[index].key,
              amount: formatter.format(sorted[index].value / 100),
              share: sorted[index].value / total,
            ),
            if (index != sorted.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 56),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final String amount;
  final double share;

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.share,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(PiggySpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: PiggyColors.expenseSoft,
                borderRadius: BorderRadius.circular(PiggyRadius.small),
              ),
              child: Icon(
                _categoryIcon(category),
                size: 17,
                color: PiggyColors.expense,
              ),
            ),
            const SizedBox(width: PiggySpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PiggyType.itemTitle,
                        ),
                      ),
                      const SizedBox(width: PiggySpace.sm),
                      Text(
                        amount,
                        style: PiggyType.amount.copyWith(
                          color: PiggyColors.expense,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: PiggySpace.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: share,
                      minHeight: 4,
                      backgroundColor: PiggyColors.line,
                      valueColor: const AlwaysStoppedAnimation(
                        PiggyColors.expense,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  IconData _categoryIcon(String value) {
    final category = value.toLowerCase();
    if (category.contains('food') || category.contains('식')) {
      return Icons.restaurant_rounded;
    }
    if (category.contains('transport') || category.contains('교통')) {
      return Icons.directions_transit_rounded;
    }
    if (category.contains('shopping') || category.contains('쇼핑')) {
      return Icons.shopping_bag_outlined;
    }
    if (category.contains('housing') || category.contains('주거')) {
      return Icons.home_outlined;
    }
    if (category.contains('medical') || category.contains('의료')) {
      return Icons.medical_services_outlined;
    }
    return Icons.sell_outlined;
  }
}
