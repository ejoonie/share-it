enum ExpenseType { income, expense }

class ExpenseModel {
  final int? id;
  final String title;
  final int amount; // stored in cents
  final String? note;
  final String? category;
  final ExpenseType type;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseModel({
    this.id,
    required this.title,
    required this.amount,
    this.note,
    this.category,
    this.type = ExpenseType.expense,
    required this.createdAt,
    required this.updatedAt,
  });

  double get amountInDollars => amount / 100.0;

  bool get isIncome => type == ExpenseType.income;
  bool get isExpense => type == ExpenseType.expense;

  ExpenseModel copyWith({
    int? id,
    String? title,
    int? amount,
    String? note,
    String? category,
    ExpenseType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      category: category ?? this.category,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'note': note,
      'category': category,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: map['amount'] as int,
      note: map['note'] as String?,
      category: map['category'] as String?,
      type: map['type'] == 'income' ? ExpenseType.income : ExpenseType.expense,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
