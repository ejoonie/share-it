import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      drawer: const SummaryDrawer(),
      backgroundColor: Colors.white,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 76,
        leadingWidth: 72,
        leading: Builder(
          builder: (ctx) => Padding(
            padding: const EdgeInsets.only(left: 18),
            child: IconButton(
              icon: const Icon(Icons.calendar_today_outlined),
              tooltip: 'Summary',
              iconSize: 28,
              onPressed: () => _openSummaryDrawer(ctx),
            ),
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Color(0xFF1F2328)),
                cursorColor: primary,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Color(0xFF8A8F98)),
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
                    iconSize: 32,
                    onPressed: () => _navigateToPrevMonth(focusedMonth),
                  ),
                  GestureDetector(
                    onTap: () => _pickMonth(focusedMonth),
                    child: Text(
                      DateFormat('MMM yyyy').format(focusedMonth),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2328),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    iconSize: 32,
                    onPressed: () => _navigateToNextMonth(focusedMonth),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            iconSize: 31,
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
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: IconButton(
              icon: const Icon(Icons.tune),
              iconSize: 31,
              onPressed: () => _showFilterDialog(state.activeFilter),
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (ctx) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: Text('Error: ${state.error}'));
          }
          return SafeArea(
            top: false,
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _MonthlySummaryBar(state: state),
                const SizedBox(height: 24),
                ExpenseCalendar(state: state),
                const SizedBox(height: 18),
                Divider(height: 1, color: Colors.grey.shade200),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2328),
                        ),
                      ),
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: ExpenseList(state: state)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseForm(state.year, state.month, state.day),
        child: const Icon(Icons.add, size: 34),
      ),
    );
  }
}

class _MonthlySummaryBar extends StatelessWidget {
  final ExpenseState state;

  const _MonthlySummaryBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    final income = state.monthlyIncomeTotal / 100.0;
    final expense = state.monthlyExpenseTotal / 100.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.11),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryAmount(
              icon: Icons.arrow_downward,
              iconColor: const Color(0xFF4FA26A),
              iconBackground: const Color(0xFFEAF7EE),
              label: 'Income',
              amount: formatter.format(income),
              amountColor: const Color(0xFF4FA26A),
            ),
          ),
          Container(width: 1, height: 58, color: const Color(0xFFE0E3E7)),
          Expanded(
            child: _SummaryAmount(
              icon: Icons.arrow_upward,
              iconColor: const Color(0xFFFF3B3F),
              iconBackground: const Color(0xFFFFEFF1),
              label: 'Expense',
              amount: formatter.format(expense),
              amountColor: const Color(0xFFFF3B3F),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryAmount extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String amount;
  final Color amountColor;

  const _SummaryAmount({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.amount,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: iconBackground,
          child: Icon(icon, color: iconColor, size: 32),
        ),
        const SizedBox(width: 18),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF616771),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: amountColor,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ],
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
