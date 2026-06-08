import '../../../../core/repositories/entry_repository.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final EntryRepository _entryRepository;

  ExpenseRepository({required EntryRepository entryRepository})
      : _entryRepository = entryRepository;

  Future<List<ExpenseModel>> _fetchExpenses() async {
    final entries = await _entryRepository.listEntries();
    return entries
        .where((e) => e.kind == 'income' || e.kind == 'expense')
        .map(ExpenseModel.fromEntry)
        .toList();
  }

  Future<List<ExpenseModel>> getAllExpenses() => _fetchExpenses();

  Future<List<ExpenseModel>> getExpensesByMonth(int year, int month) async {
    final expenses = await _fetchExpenses();
    return expenses.where((e) {
      return e.occurredAt.year == year && e.occurredAt.month == month;
    }).toList();
  }

  Future<List<ExpenseModel>> getExpensesByDate(DateTime date) async {
    final expenses = await _fetchExpenses();
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return expenses
        .where((e) =>
            !e.occurredAt.isBefore(start) && e.occurredAt.isBefore(end))
        .toList();
  }

  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    final entry = await _entryRepository.createEntry(
      occurredAt: expense.occurredAt,
      kind: expense.type.name,
      amount: expense.amount,
      category: expense.category,
      title: expense.title.isEmpty ? null : expense.title,
      content: expense.content,
    );
    return ExpenseModel.fromEntry(entry);
  }

  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    final entry = await _entryRepository.updateEntry(
      expense.id!,
      occurredAt: expense.occurredAt,
      kind: expense.type.name,
      amount: expense.amount,
      category: expense.category,
      title: expense.title.isEmpty ? null : expense.title,
      content: expense.content,
    );
    return ExpenseModel.fromEntry(entry);
  }

  Future<void> deleteExpense(int id) async {
    await _entryRepository.deleteEntry(id);
  }

  Future<Map<DateTime, Map<String, int>>> getMonthlySummary(
    int year,
    int month,
  ) async {
    final expenses = await getExpensesByMonth(year, month);
    final Map<DateTime, Map<String, int>> summary = {};

    for (final e in expenses) {
      final day = DateTime(
        e.occurredAt.year,
        e.occurredAt.month,
        e.occurredAt.day,
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
