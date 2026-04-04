import 'package:equatable/equatable.dart';
import '../../data/models/shopping_item_model.dart';

abstract class ShoppingState extends Equatable {
  const ShoppingState();

  @override
  List<Object?> get props => [];
}

class ShoppingInitial extends ShoppingState {
  const ShoppingInitial();
}

class ShoppingLoading extends ShoppingState {
  const ShoppingLoading();
}

class ShoppingLoaded extends ShoppingState {
  final List<ShoppingItemModel> items;

  const ShoppingLoaded({required this.items});

  List<ShoppingItemModel> get uncheckedItems =>
      items.where((i) => !i.isChecked).toList();

  List<ShoppingItemModel> get checkedItems =>
      items.where((i) => i.isChecked).toList();

  int get totalEstimated => items.fold(0, (sum, i) => sum + (i.amount ?? 0));

  ShoppingLoaded copyWith({List<ShoppingItemModel>? items}) {
    return ShoppingLoaded(items: items ?? this.items);
  }

  @override
  List<Object?> get props => [items];
}

class ShoppingError extends ShoppingState {
  final String message;
  const ShoppingError(this.message);

  @override
  List<Object?> get props => [message];
}
