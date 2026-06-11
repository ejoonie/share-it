import '../../../../core/models/entry_model.dart';

enum ExpenseType { income, expense }

class ExpenseModel {
  final int? id;
  final String title;
  final int amount; // raw integer matching server (e.g. cents for USD)
  final String? content;
  final String? category;
  final ExpenseType type;
  final DateTime occurredAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExpenseModel({
    this.id,
    required this.title,
    required this.amount,
    this.content,
    this.category,
    this.type = ExpenseType.expense,
    required this.occurredAt,
    this.createdAt,
    this.updatedAt,
  });

  double get amountInDollars => amount / 100.0;

  bool get isIncome => type == ExpenseType.income;
  bool get isExpense => type == ExpenseType.expense;

  ExpenseModel copyWith({
    int? id,
    String? title,
    int? amount,
    String? Function()? content,
    String? Function()? category,
    ExpenseType? type,
    DateTime? occurredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      content: content != null ? content() : this.content,
      category: category != null ? category() : this.category,
      type: type ?? this.type,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ExpenseModel.fromEntry(EntryModel entry) {
    final expenseType = entry.kind == 'income'
        ? ExpenseType.income
        : ExpenseType.expense;
    return ExpenseModel(
      id: entry.id,
      title: entry.title ?? '',
      amount: entry.amount,
      content: entry.content,
      category: entry.category,
      type: expenseType,
      occurredAt: entry.occurredAt ?? entry.createdAt,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  Map<String, dynamic> toEntryJson() {
    return {
      'occurred_at': occurredAt.toIso8601String(),
      'kind': type.name,
      'amount': amount,
      if (content != null && content!.isNotEmpty) 'content': content,
      if (category != null && category!.isNotEmpty) 'category': category,
      if (title.isNotEmpty) 'title': title,
    };
  }
}
