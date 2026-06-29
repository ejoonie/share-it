import 'entry_model.dart';

class ShoppingItemModel {
  final int? id;
  final String title;
  final int? amount; // estimated price (raw integer)
  final String? content;
  final bool isChecked;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShoppingItemModel({
    this.id,
    required this.title,
    this.amount,
    this.content,
    this.isChecked = false,
    this.createdAt,
    this.updatedAt,
  });

  double? get amountInDollars =>
      amount != null ? amount! / 100.0 : null;

  ShoppingItemModel copyWith({
    int? id,
    String? title,
    int? Function()? amount,
    String? Function()? content,
    bool? isChecked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount != null ? amount() : this.amount,
      content: content != null ? content() : this.content,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ShoppingItemModel.fromEntry(EntryModel entry) {
    return ShoppingItemModel(
      id: entry.id,
      title: entry.title ?? '',
      amount: entry.amount > 0 ? entry.amount : null,
      content: entry.content,
      isChecked: entry.checked,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  Map<String, dynamic> toEntryJson() {
    return {
      'kind': 'shopping',
      if (title.isNotEmpty) 'title': title,
      if (amount != null) 'amount': amount,
      if (content != null && content!.isNotEmpty) 'content': content,
      'checked': isChecked,
    };
  }
}
