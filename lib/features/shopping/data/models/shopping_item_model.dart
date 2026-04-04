import 'package:equatable/equatable.dart';

class ShoppingItemModel extends Equatable {
  final int? id;
  final String title;
  final int? amount; // estimated price in cents, optional
  final String? quantity;
  final String? note;
  final bool isChecked;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShoppingItemModel({
    this.id,
    required this.title,
    this.amount,
    this.quantity,
    this.note,
    this.isChecked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  double? get amountInDollars =>
      amount != null ? amount! / 100.0 : null;

  ShoppingItemModel copyWith({
    int? id,
    String? title,
    int? Function()? amount,
    String? Function()? quantity,
    String? Function()? note,
    bool? isChecked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount != null ? amount() : this.amount,
      quantity: quantity != null ? quantity() : this.quantity,
      note: note != null ? note() : this.note,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'quantity': quantity,
      'note': note,
      'is_checked': isChecked ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ShoppingItemModel.fromMap(Map<String, dynamic> map) {
    return ShoppingItemModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: map['amount'] as int?,
      quantity: map['quantity'] as String?,
      note: map['note'] as String?,
      isChecked: (map['is_checked'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [id, title, amount, quantity, note, isChecked, createdAt, updatedAt];
}
