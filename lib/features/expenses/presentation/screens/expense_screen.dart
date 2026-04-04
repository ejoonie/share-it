import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';
import '../../data/models/expense_model.dart';
import '../widgets/expense_calendar.dart';
import '../widgets/expense_list.dart';
import '../widgets/expense_form.dart';
import '../widgets/summary_drawer.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
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

  void _navigateToPrevMonth(BuildContext context, DateTime current) {
    final prev = DateTime(current.year, current.month - 1);
    context.read<ExpenseBloc>().add(ChangeMonth(prev));
  }

  void _navigateToNextMonth(BuildContext context, DateTime current) {
    final next = DateTime(current.year, current.month + 1);
    context.read<ExpenseBloc>().add(ChangeMonth(next));
  }

  Future<void> _pickMonth(BuildContext context, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && context.mounted) {
      context
          .read<ExpenseBloc>()
          .add(ChangeMonth(DateTime(picked.year, picked.month)));
    }
  }

  void _showFilterDialog(BuildContext context, ExpenseType? current) {
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
                context.read<ExpenseBloc>().add(const FilterExpenses(null));
                Navigator.pop(context);
              },
            ),
            _FilterTile(
              label: 'Expense',
              selected: current == ExpenseType.expense,
              onTap: () {
                context
                    .read<ExpenseBloc>()
                    .add(const FilterExpenses(ExpenseType.expense));
                Navigator.pop(context);
              },
            ),
            _FilterTile(
              label: 'Income',
              selected: current == ExpenseType.income,
              onTap: () {
                context
                    .read<ExpenseBloc>()
                    .add(const FilterExpenses(ExpenseType.income));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseForm(BuildContext context, DateTime selectedDate) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ExpenseBloc>(),
        child: ExpenseForm(initialDate: selectedDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        final loaded = state is ExpenseLoaded ? state : null;
        final focusedMonth = loaded?.focusedMonth ?? DateTime.now();

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
                        context.read<ExpenseBloc>().add(SearchExpenses(q)),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () =>
                            _navigateToPrevMonth(context, focusedMonth),
                      ),
                      GestureDetector(
                        onTap: () => _pickMonth(context, focusedMonth),
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
                        onPressed: () =>
                            _navigateToNextMonth(context, focusedMonth),
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
                      context
                          .read<ExpenseBloc>()
                          .add(const SearchExpenses(''));
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () =>
                    _showFilterDialog(context, loaded?.activeFilter),
              ),
            ],
          ),
          body: Builder(
            builder: (ctx) {
              if (state is ExpenseLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ExpenseError) {
                return Center(child: Text('Error: ${state.message}'));
              }
              if (state is ExpenseLoaded) {
                return Column(
                  children: [
                    // Income / Expense summary bar
                    _MonthlySummaryBar(state: state),
                    // Calendar
                    ExpenseCalendar(state: state),
                    // Divider
                    const Divider(height: 1),
                    // List of expenses for selected date
                    Expanded(child: ExpenseList(state: state)),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddExpenseForm(
              context,
              loaded?.selectedDate ?? DateTime.now(),
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _MonthlySummaryBar extends StatelessWidget {
  final ExpenseLoaded state;

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
                const Text('Income', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                const Text('Expense', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
      trailing: selected ? const Icon(Icons.check, color: Color(0xFF4CAF50)) : null,
      onTap: onTap,
    );
  }
}
