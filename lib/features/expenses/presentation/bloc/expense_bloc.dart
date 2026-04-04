import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import 'expense_event.dart';
import 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository repository;

  ExpenseBloc({required this.repository}) : super(const ExpenseInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<ChangeMonth>(_onChangeMonth);
    on<SelectDate>(_onSelectDate);
    on<AddExpense>(_onAddExpense);
    on<UpdateExpense>(_onUpdateExpense);
    on<DeleteExpense>(_onDeleteExpense);
    on<SearchExpenses>(_onSearchExpenses);
    on<FilterExpenses>(_onFilterExpenses);
  }

  Future<void> _onLoadExpenses(
    LoadExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseLoading());
    try {
      final month = DateTime(event.month.year, event.month.month);
      final monthly = await repository.getExpensesByMonth(month.year, month.month);
      final summary = await repository.getMonthlySummary(month.year, month.month);
      final today = DateTime.now();
      final selectedDate = DateTime(today.year, today.month, today.day);
      final daily = await repository.getExpensesByDate(selectedDate);

      emit(ExpenseLoaded(
        focusedMonth: month,
        selectedDate: selectedDate,
        monthlyExpenses: monthly,
        selectedDateExpenses: daily,
        monthlySummary: summary,
      ));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onChangeMonth(
    ChangeMonth event,
    Emitter<ExpenseState> emit,
  ) async {
    final current = state is ExpenseLoaded ? (state as ExpenseLoaded) : null;
    try {
      final month = DateTime(event.month.year, event.month.month);
      final monthly = await repository.getExpensesByMonth(month.year, month.month);
      final summary = await repository.getMonthlySummary(month.year, month.month);
      final selectedDate = DateTime(month.year, month.month, 1);
      final daily = await repository.getExpensesByDate(selectedDate);

      emit(ExpenseLoaded(
        focusedMonth: month,
        selectedDate: selectedDate,
        monthlyExpenses: monthly,
        selectedDateExpenses: daily,
        monthlySummary: summary,
        activeFilter: current?.activeFilter,
        searchQuery: current?.searchQuery ?? '',
      ));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onSelectDate(
    SelectDate event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is! ExpenseLoaded) return;
    final current = state as ExpenseLoaded;
    try {
      final daily = await repository.getExpensesByDate(event.date);
      emit(current.copyWith(
        selectedDate: event.date,
        selectedDateExpenses: daily,
      ));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onAddExpense(
    AddExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is! ExpenseLoaded) return;
    final current = state as ExpenseLoaded;
    try {
      await repository.addExpense(event.expense);
      final monthly = await repository.getExpensesByMonth(
        current.focusedMonth.year,
        current.focusedMonth.month,
      );
      final summary = await repository.getMonthlySummary(
        current.focusedMonth.year,
        current.focusedMonth.month,
      );
      final daily = await repository.getExpensesByDate(current.selectedDate);
      emit(current.copyWith(
        monthlyExpenses: monthly,
        selectedDateExpenses: daily,
        monthlySummary: summary,
      ));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onUpdateExpense(
    UpdateExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is! ExpenseLoaded) return;
    final current = state as ExpenseLoaded;
    try {
      await repository.updateExpense(event.expense);
      final monthly = await repository.getExpensesByMonth(
        current.focusedMonth.year,
        current.focusedMonth.month,
      );
      final summary = await repository.getMonthlySummary(
        current.focusedMonth.year,
        current.focusedMonth.month,
      );
      final daily = await repository.getExpensesByDate(current.selectedDate);
      emit(current.copyWith(
        monthlyExpenses: monthly,
        selectedDateExpenses: daily,
        monthlySummary: summary,
      ));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is! ExpenseLoaded) return;
    final current = state as ExpenseLoaded;
    try {
      await repository.deleteExpense(event.id);
      final monthly = await repository.getExpensesByMonth(
        current.focusedMonth.year,
        current.focusedMonth.month,
      );
      final summary = await repository.getMonthlySummary(
        current.focusedMonth.year,
        current.focusedMonth.month,
      );
      final daily = await repository.getExpensesByDate(current.selectedDate);
      emit(current.copyWith(
        monthlyExpenses: monthly,
        selectedDateExpenses: daily,
        monthlySummary: summary,
      ));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  void _onSearchExpenses(
    SearchExpenses event,
    Emitter<ExpenseState> emit,
  ) {
    if (state is! ExpenseLoaded) return;
    final current = state as ExpenseLoaded;
    emit(current.copyWith(searchQuery: event.query));
  }

  void _onFilterExpenses(
    FilterExpenses event,
    Emitter<ExpenseState> emit,
  ) {
    if (state is! ExpenseLoaded) return;
    final current = state as ExpenseLoaded;
    emit(current.copyWith(activeFilter: () => event.type));
  }
}
