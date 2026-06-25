import '../../../../core/repositories/entry_repository.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final EntryRepository _entryRepository;

  ExpenseRepository({required EntryRepository entryRepository})
      : _entryRepository = entryRepository;

  static const _kindFilter = {'q[kind_in][]': ['income', 'expense']};

  Future<List<ExpenseModel>> getAllExpenses() async {
    final entries = await _entryRepository.listEntries(q: _kindFilter);
    return entries.map(ExpenseModel.fromEntry).toList();
  }

  Future<List<ExpenseModel>> getExpensesByMonth(int year, int month) async {
    final startLocal = DateTime(year, month, 1);
    final endLocal = DateTime(year, month + 1, 1);
    final entries = await _entryRepository.listEntries(q: {
      ..._kindFilter,
      'q[occurred_at_gteq]': startLocal.toUtc().toIso8601String(),
      'q[occurred_at_lt]': endLocal.toUtc().toIso8601String(),
    });
    return entries.map(ExpenseModel.fromEntry).toList();
  }

  Future<List<ExpenseModel>> getExpensesByDate(int year, int month, int day) async {
    final startLocal = DateTime(year, month, day);
    final endLocal = startLocal.add(const Duration(days: 1));
    final entries = await _entryRepository.listEntries(q: {
      ..._kindFilter,
      'q[occurred_at_gteq]': startLocal.toUtc().toIso8601String(),
      'q[occurred_at_lt]': endLocal.toUtc().toIso8601String(),
    });
    return entries.map(ExpenseModel.fromEntry).toList();
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

  Map<DateTime, Map<String, int>> buildMonthlySummary(List<ExpenseModel> expenses) {
    final Map<DateTime, Map<String, int>> summary = {};

    for (final e in expenses) {
      final local = e.occurredAt.toLocal();
      final day = DateTime(
        local.year,
        local.month,
        local.day,
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

  Future<Map<DateTime, Map<String, int>>> getMonthlySummary(
    int year,
    int month,
  ) async {
    final expenses = await getExpensesByMonth(year, month);
    return buildMonthlySummary(expenses);
  }
}
