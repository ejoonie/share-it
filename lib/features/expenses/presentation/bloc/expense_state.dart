import 'package:equatable/equatable.dart';
import '../../data/models/expense_model.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
}

class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

class ExpenseLoaded extends ExpenseState {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final List<ExpenseModel> monthlyExpenses;
  final List<ExpenseModel> selectedDateExpenses;
  final Map<DateTime, Map<String, int>> monthlySummary;
  final ExpenseType? activeFilter;
  final String searchQuery;

  const ExpenseLoaded({
    required this.focusedMonth,
    required this.selectedDate,
    required this.monthlyExpenses,
    required this.selectedDateExpenses,
    required this.monthlySummary,
    this.activeFilter,
    this.searchQuery = '',
  });

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

  ExpenseLoaded copyWith({
    DateTime? focusedMonth,
    DateTime? selectedDate,
    List<ExpenseModel>? monthlyExpenses,
    List<ExpenseModel>? selectedDateExpenses,
    Map<DateTime, Map<String, int>>? monthlySummary,
    ExpenseType? Function()? activeFilter,
    String? searchQuery,
  }) {
    return ExpenseLoaded(
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDate: selectedDate ?? this.selectedDate,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      selectedDateExpenses: selectedDateExpenses ?? this.selectedDateExpenses,
      monthlySummary: monthlySummary ?? this.monthlySummary,
      activeFilter: activeFilter != null ? activeFilter() : this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        focusedMonth,
        selectedDate,
        monthlyExpenses,
        selectedDateExpenses,
        monthlySummary,
        activeFilter,
        searchQuery,
      ];
}

class ExpenseError extends ExpenseState {
  final String message;
  const ExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}
