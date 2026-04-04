import 'package:equatable/equatable.dart';
import '../../data/models/expense_model.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class LoadExpenses extends ExpenseEvent {
  final DateTime month;
  const LoadExpenses(this.month);

  @override
  List<Object?> get props => [month];
}

class SelectDate extends ExpenseEvent {
  final DateTime date;
  const SelectDate(this.date);

  @override
  List<Object?> get props => [date];
}

class AddExpense extends ExpenseEvent {
  final ExpenseModel expense;
  const AddExpense(this.expense);

  @override
  List<Object?> get props => [expense];
}

class UpdateExpense extends ExpenseEvent {
  final ExpenseModel expense;
  const UpdateExpense(this.expense);

  @override
  List<Object?> get props => [expense];
}

class DeleteExpense extends ExpenseEvent {
  final int id;
  const DeleteExpense(this.id);

  @override
  List<Object?> get props => [id];
}

class ChangeMonth extends ExpenseEvent {
  final DateTime month;
  const ChangeMonth(this.month);

  @override
  List<Object?> get props => [month];
}

class SearchExpenses extends ExpenseEvent {
  final String query;
  const SearchExpenses(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterExpenses extends ExpenseEvent {
  final ExpenseType? type; // null means all
  const FilterExpenses(this.type);

  @override
  List<Object?> get props => [type];
}
