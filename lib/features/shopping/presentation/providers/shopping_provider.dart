import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/shopping_item_model.dart';
import '../../data/repositories/shopping_repository.dart';

final shoppingRepositoryProvider =
    Provider<ShoppingRepository>((_) => ShoppingRepository());

class ShoppingState {
  final List<ShoppingItemModel> items;
  final bool isLoading;
  final String? error;

  const ShoppingState({
    required this.items,
    this.isLoading = false,
    this.error,
  });

  factory ShoppingState.initial() =>
      const ShoppingState(items: [], isLoading: true);

  List<ShoppingItemModel> get uncheckedItems =>
      items.where((i) => !i.isChecked).toList();

  List<ShoppingItemModel> get checkedItems =>
      items.where((i) => i.isChecked).toList();

  int get totalEstimated =>
      items.fold(0, (sum, i) => sum + (i.amount ?? 0));

  ShoppingState copyWith({
    List<ShoppingItemModel>? items,
    bool? isLoading,
    String? Function()? error,
  }) {
    return ShoppingState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

class ShoppingNotifier extends StateNotifier<ShoppingState> {
  final ShoppingRepository _repository;

  ShoppingNotifier(this._repository) : super(ShoppingState.initial()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _repository.getAllItems();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: () => e.toString());
    }
  }

  Future<void> addItem(ShoppingItemModel item) async {
    try {
      final added = await _repository.addItem(item);
      state = state.copyWith(items: [...state.items, added]);
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> updateItem(ShoppingItemModel item) async {
    try {
      final updated = await _repository.updateItem(item);
      state = state.copyWith(
        items: state.items
            .map((i) => i.id == updated.id ? updated : i)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _repository.deleteItem(id);
      state = state.copyWith(
          items: state.items.where((i) => i.id != id).toList());
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> toggleItem(ShoppingItemModel item) async {
    try {
      final toggled = await _repository.toggleItem(item);
      state = state.copyWith(
        items: state.items
            .map((i) => i.id == toggled.id ? toggled : i)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> deleteCheckedItems() async {
    try {
      await _repository.deleteCheckedItems();
      state = state.copyWith(
          items: state.items.where((i) => !i.isChecked).toList());
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }
}

final shoppingNotifierProvider =
    StateNotifierProvider<ShoppingNotifier, ShoppingState>(
  (ref) => ShoppingNotifier(ref.watch(shoppingRepositoryProvider)),
);
