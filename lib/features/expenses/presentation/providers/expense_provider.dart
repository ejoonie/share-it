import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository?>((ref) {
  final entryRepo = ref.watch(entryRepositoryProvider);
  if (entryRepo == null) return null;
  return ExpenseRepository(entryRepository: entryRepo);
});

class ExpenseState {
  final DateTime focusedMonth;
  final int year;
  final int month;
  final int day;
  final List<ExpenseModel> monthlyExpenses;
  final List<ExpenseModel> selectedDateExpenses;
  final Map<DateTime, Map<String, int>> monthlySummary;
  final ExpenseType? activeFilter;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const ExpenseState({
    required this.focusedMonth,
    required this.year,
    required this.month,
    required this.day,
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
      year: now.year,
      month: now.month,
      day: now.day,
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
      year: selectedDate?.year ?? this.year,
      month: selectedDate?.month ?? this.month,
      day: selectedDate?.day ?? this.day,
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

/// Manages expense data for the main Expense screen.
///
/// [expenseNotifierProvider] watches [expenseRepositoryProvider], which in
/// turn depends on [entryRepositoryProvider] → [bootstrapNotifierProvider].
/// When bootstrap succeeds the repository chain resolves from null to a real
/// instance, causing Riverpod to recreate this notifier with a non-null
/// repository. The constructor then kicks off the initial load automatically —
/// no manual trigger from the UI is needed.
///
/// After that, tapping the Expenses tab calls [load] explicitly to refresh.
class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final ExpenseRepository? _repository;

  ExpenseNotifier(this._repository) : super(ExpenseState.initial()) {
    if (_repository != null) load();
  }

  Future<void> load() => _load(state.focusedMonth);

  Future<void> _load(DateTime month) async {
    final repo = _repository;
    if (repo == null) return;
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final m = DateTime(month.year, month.month);
      final today = DateTime.now();
      final selectedDate = DateTime(today.year, today.month, today.day);
      final monthly = await repo.getExpensesByMonth(m.year, m.month);
      final summary = repo.buildMonthlySummary(monthly);
      final daily = await repo.getExpensesByDate(selectedDate.year, selectedDate.month, selectedDate.day);
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
    final repo = _repository;
    if (repo == null) return;
    try {
      final m = DateTime(month.year, month.month);
      final selectedDate = DateTime(m.year, m.month, 1);
      final monthly = await repo.getExpensesByMonth(m.year, m.month);
      final summary = repo.buildMonthlySummary(monthly);
      final daily = await repo.getExpensesByDate(selectedDate.year, selectedDate.month, selectedDate.day);
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

  Future<void> selectDate(int year, int month, int day) async {
    final date = DateTime(year, month, day); // local
    final repo = _repository;
    if (repo == null) return;
    try {
      final daily = await repo.getExpensesByDate(year, month, day);
      state = state.copyWith(
        selectedDate: date,
        selectedDateExpenses: daily,
      );
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> addExpense(ExpenseModel expense) async {
    final repo = _repository;
    if (repo == null) return;
    try {
      await repo.addExpense(expense);
      await _refresh();
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final repo = _repository;
    if (repo == null) return;
    try {
      await repo.updateExpense(expense);
      await _refresh();
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> deleteExpense(int id) async {
    final repo = _repository;
    if (repo == null) return;
    try {
      await repo.deleteExpense(id);
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
    final repo = _repository;
    if (repo == null) return;
    final monthly = await repo.getExpensesByMonth(
      state.focusedMonth.year,
      state.focusedMonth.month,
    );
    final summary = repo.buildMonthlySummary(monthly);
    final daily = await repo.getExpensesByDate(state.year, state.month, state.day);
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
