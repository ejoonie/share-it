import 'package:equatable/equatable.dart';
import '../../data/models/shopping_item_model.dart';

abstract class ShoppingEvent extends Equatable {
  const ShoppingEvent();

  @override
  List<Object?> get props => [];
}

class LoadShoppingItems extends ShoppingEvent {
  const LoadShoppingItems();
}

class AddShoppingItem extends ShoppingEvent {
  final ShoppingItemModel item;
  const AddShoppingItem(this.item);

  @override
  List<Object?> get props => [item];
}

class UpdateShoppingItem extends ShoppingEvent {
  final ShoppingItemModel item;
  const UpdateShoppingItem(this.item);

  @override
  List<Object?> get props => [item];
}

class DeleteShoppingItem extends ShoppingEvent {
  final int id;
  const DeleteShoppingItem(this.id);

  @override
  List<Object?> get props => [id];
}

class ToggleShoppingItem extends ShoppingEvent {
  final ShoppingItemModel item;
  const ToggleShoppingItem(this.item);

  @override
  List<Object?> get props => [item];
}

class DeleteCheckedItems extends ShoppingEvent {
  const DeleteCheckedItems();
}
