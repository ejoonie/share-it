import '../../../../core/database/database_helper.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const String _table = DatabaseHelper.eventsTable;
  static const String _eventType = 'expense';

  Future<List<ExpenseModel>> getAllExpenses() async {
    final rows = await _db.queryWhere(
      _table,
      '${DatabaseHelper.colEventType} = ?',
      [_eventType],
    );
    return rows.map(ExpenseModel.fromMap).toList();
  }

  Future<List<ExpenseModel>> getExpensesByMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);
    final rows = await _db.queryWhere(
      _table,
      '${DatabaseHelper.colEventType} = ? AND created_at >= ? AND created_at < ?',
      [_eventType, startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return rows.map(ExpenseModel.fromMap).toList();
  }

  Future<List<ExpenseModel>> getExpensesByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _db.queryWhere(
      _table,
      '${DatabaseHelper.colEventType} = ? AND created_at >= ? AND created_at < ?',
      [_eventType, start.toIso8601String(), end.toIso8601String()],
    );
    return rows.map(ExpenseModel.fromMap).toList();
  }

  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    final model = expense.copyWith(updatedAt: DateTime.now());
    final row = {...model.toMap(), DatabaseHelper.colEventType: _eventType};
    final id = await _db.insert(_table, row);
    return model.copyWith(id: id);
  }

  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    final updated = expense.copyWith(updatedAt: DateTime.now());
    final row = {...updated.toMap(), DatabaseHelper.colEventType: _eventType};
    await _db.update(_table, row, expense.id!);
    return updated;
  }

  Future<void> deleteExpense(int id) async {
    await _db.delete(_table, id);
  }

  /// Returns a map of date -> {income, expense} totals for a given month.
  Future<Map<DateTime, Map<String, int>>> getMonthlySummary(
    int year,
    int month,
  ) async {
    final expenses = await getExpensesByMonth(year, month);
    final Map<DateTime, Map<String, int>> summary = {};

    for (final e in expenses) {
      final day = DateTime(
        e.createdAt.year,
        e.createdAt.month,
        e.createdAt.day,
      );
      summary[day] ??= {'income': 0, 'expense': 0};
      if (e.isIncome) {
        summary[day]!['income'] = summary[day]!['income']! + e.amount;
      } else {
        summary[day]!['expense'] = summary[day]!['expense']! + e.amount;
      }
    }

    return summary;
  }
}
