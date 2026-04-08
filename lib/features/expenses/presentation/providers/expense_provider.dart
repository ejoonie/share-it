import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';

final expenseRepositoryProvider =
    Provider<ExpenseRepository>((_) => ExpenseRepository());

class ExpenseState {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final List<ExpenseModel> monthlyExpenses;
  final List<ExpenseModel> selectedDateExpenses;
  final Map<DateTime, Map<String, int>> monthlySummary;
  final ExpenseType? activeFilter;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const ExpenseState({
    required this.focusedMonth,
    required this.selectedDate,
    required this.monthlyExpenses,
    required this.selectedDateExpenses,
    required this.monthlySummary,
    this.activeFilter,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  factory ExpenseState.initial() {
    final now = DateTime.now();
    return ExpenseState(
      focusedMonth: DateTime(now.year, now.month),
      selectedDate: DateTime(now.year, now.month, now.day),
      monthlyExpenses: const [],
      selectedDateExpenses: const [],
      monthlySummary: const {},
      isLoading: true,
    );
  }

  int get monthlyIncomeTotal => monthlyExpenses
      .where((e) => e.isIncome)
      .fold(0, (sum, e) => sum + e.amount);

  int get monthlyExpenseTotal => monthlyExpenses
      .where((e) => e.isExpense)
      .fold(0, (sum, e) => sum + e.amount);

  List<ExpenseModel> get filteredSelectedDateExpenses {
    var list = selectedDateExpenses;
    if (activeFilter != null) {
      list = list.where((e) => e.type == activeFilter).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((e) => e.title.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  ExpenseState copyWith({
    DateTime? focusedMonth,
    DateTime? selectedDate,
    List<ExpenseModel>? monthlyExpenses,
    List<ExpenseModel>? selectedDateExpenses,
    Map<DateTime, Map<String, int>>? monthlySummary,
    ExpenseType? Function()? activeFilter,
    String? searchQuery,
    bool? isLoading,
    String? Function()? error,
  }) {
    return ExpenseState(
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDate: selectedDate ?? this.selectedDate,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      selectedDateExpenses: selectedDateExpenses ?? this.selectedDateExpenses,
      monthlySummary: monthlySummary ?? this.monthlySummary,
      activeFilter: activeFilter != null ? activeFilter() : this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final ExpenseRepository _repository;

  ExpenseNotifier(this._repository) : super(ExpenseState.initial()) {
    _load(state.focusedMonth);
  }

  Future<void> _load(DateTime month) async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final m = DateTime(month.year, month.month);
      final today = DateTime.now();
      final selectedDate = DateTime(today.year, today.month, today.day);
      final monthly = await _repository.getExpensesByMonth(m.year, m.month);
      final summary = await _repository.getMonthlySummary(m.year, m.month);
      final daily = await _repository.getExpensesByDate(selectedDate);
      state = state.copyWith(
        focusedMonth: m,
        selectedDate: selectedDate,
        monthlyExpenses: monthly,
        selectedDateExpenses: daily,
        monthlySummary: summary,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: () => e.toString());
    }
  }

  Future<void> changeMonth(DateTime month) async {
    try {
      final m = DateTime(month.year, month.month);
      final selectedDate = DateTime(m.year, m.month, 1);
      final monthly = await _repository.getExpensesByMonth(m.year, m.month);
      final summary = await _repository.getMonthlySummary(m.year, m.month);
      final daily = await _repository.getExpensesByDate(selectedDate);
      state = state.copyWith(
        focusedMonth: m,
        selectedDate: selectedDate,
        monthlyExpenses: monthly,
        selectedDateExpenses: daily,
        monthlySummary: summary,
      );
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> selectDate(DateTime date) async {
    try {
      final daily = await _repository.getExpensesByDate(date);
      state = state.copyWith(
        selectedDate: date,
        selectedDateExpenses: daily,
      );
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await _repository.addExpense(expense);
      await _refresh();
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await _repository.updateExpense(expense);
      await _refresh();
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _repository.deleteExpense(id);
      await _refresh();
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  void searchExpenses(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void filterExpenses(ExpenseType? type) {
    state = state.copyWith(activeFilter: () => type);
  }

  Future<void> _refresh() async {
    final monthly = await _repository.getExpensesByMonth(
      state.focusedMonth.year,
      state.focusedMonth.month,
    );
    final summary = await _repository.getMonthlySummary(
      state.focusedMonth.year,
      state.focusedMonth.month,
    );
    final daily = await _repository.getExpensesByDate(state.selectedDate);
    state = state.copyWith(
      monthlyExpenses: monthly,
      selectedDateExpenses: daily,
      monthlySummary: summary,
    );
  }
}

final expenseNotifierProvider =
    StateNotifierProvider<ExpenseNotifier, ExpenseState>(
  (ref) => ExpenseNotifier(ref.watch(expenseRepositoryProvider)),
);
