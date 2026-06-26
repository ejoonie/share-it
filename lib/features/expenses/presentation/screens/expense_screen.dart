import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/expense_provider.dart';
import '../../data/models/expense_model.dart';
import '../widgets/expense_calendar.dart';
import '../widgets/expense_list.dart';
import '../widgets/expense_form.dart';
import '../widgets/summary_drawer.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSummaryDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  void _navigateToPrevMonth(DateTime current) {
    final prev = DateTime(current.year, current.month - 1);
    ref.read(expenseNotifierProvider.notifier).changeMonth(prev);
  }

  void _navigateToNextMonth(DateTime current) {
    final next = DateTime(current.year, current.month + 1);
    ref.read(expenseNotifierProvider.notifier).changeMonth(next);
  }

  Future<void> _pickMonth(DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && mounted) {
      ref
          .read(expenseNotifierProvider.notifier)
          .changeMonth(DateTime(picked.year, picked.month));
    }
  }

  void _showFilterDialog(ExpenseType? current) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _FilterTile(
              label: 'All',
              selected: current == null,
              onTap: () {
                ref
                    .read(expenseNotifierProvider.notifier)
                    .filterExpenses(null);
                Navigator.pop(context);
              },
            ),
            _FilterTile(
              label: 'Expense',
              selected: current == ExpenseType.expense,
              onTap: () {
                ref
                    .read(expenseNotifierProvider.notifier)
                    .filterExpenses(ExpenseType.expense);
                Navigator.pop(context);
              },
            ),
            _FilterTile(
              label: 'Income',
              selected: current == ExpenseType.income,
              onTap: () {
                ref
                    .read(expenseNotifierProvider.notifier)
                    .filterExpenses(ExpenseType.income);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseForm(int year, int month, int day) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExpenseForm(
        initYear: year,
        initMonth: month,
        initDay: day,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseNotifierProvider);
    final focusedMonth = state.focusedMonth;

    return Scaffold(
      drawer: const SummaryDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Summary',
            onPressed: () => _openSummaryDrawer(ctx),
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Color(0xFF1A1A1A)),
                cursorColor: AppTheme.primaryColor,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (q) =>
                    ref.read(expenseNotifierProvider.notifier).searchExpenses(q),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _navigateToPrevMonth(focusedMonth),
                  ),
                  GestureDetector(
                    onTap: () => _pickMonth(focusedMonth),
                    child: Text(
                      DateFormat('MMM yyyy').format(focusedMonth),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _navigateToNextMonth(focusedMonth),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref
                      .read(expenseNotifierProvider.notifier)
                      .searchExpenses('');
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: () => _showFilterDialog(state.activeFilter),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Builder(
        builder: (ctx) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: Text('Error: ${state.error}'));
          }
          return Column(
            children: [
              _MonthlySummaryBar(state: state),
              ExpenseCalendar(state: state),
              const Divider(height: 1),
              Expanded(child: ExpenseList(state: state)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseForm(state.year, state.month, state.day),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MonthlySummaryBar extends StatelessWidget {
  final ExpenseState state;

  const _MonthlySummaryBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final income = state.monthlyIncomeTotal / 100.0;
    final expense = state.monthlyExpenseTotal / 100.0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      // income, expense summary
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Income',
                amount: formatter.format(income),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppTheme.incomeColor,
                iconBgColor: AppTheme.incomeColor.withValues(alpha: 0.1),
                amountColor: AppTheme.incomeColor,
              ),
            ),
            Container(width: 1, height: 32, color: Colors.grey.shade300), // 가운데 버티컬 바
            Expanded(
              child: _SummaryCard(
                label: 'Expense',
                amount: formatter.format(expense),
                icon: Icons.receipt_long_outlined,
                iconColor: AppTheme.expenseColor,
                iconBgColor: AppTheme.expenseColor.withValues(alpha: 0.1),
                amountColor: AppTheme.expenseColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color amountColor;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          // icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          // blank
          const SizedBox(width: 12),
          // income, expense
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check, color: Color(0xFF4CAF50))
          : null,
      onTap: onTap,
    );
  }
}
