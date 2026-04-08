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

  void _showAddExpenseForm(DateTime selectedDate) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExpenseForm(initialDate: selectedDate),
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
            icon: const Icon(Icons.summarize_outlined),
            tooltip: 'Summary',
            onPressed: () => _openSummaryDrawer(ctx),
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white70),
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
                        color: Colors.white,
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
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(state.activeFilter),
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
        onPressed: () => _showAddExpenseForm(state.selectedDate),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Income',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  formatter.format(income),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF43A047),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: Colors.grey.shade300),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Expense',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  formatter.format(expense),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53935),
                  ),
                ),
              ],
            ),
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
