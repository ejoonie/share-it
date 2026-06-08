import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/models/shopping_item_model.dart';
import '../../data/repositories/shopping_repository.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository?>((ref) {
  final entryRepo = ref.watch(entryRepositoryProvider);
  if (entryRepo == null) return null;
  return ShoppingRepository(entryRepository: entryRepo);
});

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
  final ShoppingRepository? _repository;

  ShoppingNotifier(this._repository) : super(ShoppingState.initial()) {
    if (_repository != null) {
      _load();
    }
  }

  Future<void> _load() async {
    final repo = _repository;
    if (repo == null) return;
    try {
      final items = await repo.getAllItems();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: () => e.toString());
    }
  }

  Future<void> addItem(ShoppingItemModel item) async {
    final repo = _repository;
    if (repo == null) return;
    try {
      final added = await repo.addItem(item);
      state = state.copyWith(items: [...state.items, added]);
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> updateItem(ShoppingItemModel item) async {
    final repo = _repository;
    if (repo == null) return;
    try {
      final updated = await repo.updateItem(item);
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
    final repo = _repository;
    if (repo == null) return;
    try {
      await repo.deleteItem(id);
      state = state.copyWith(
          items: state.items.where((i) => i.id != id).toList());
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> toggleItem(ShoppingItemModel item) async {
    final repo = _repository;
    if (repo == null) return;
    try {
      final toggled = await repo.toggleItem(item);
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
    final repo = _repository;
    if (repo == null) return;
    try {
      await repo.deleteCheckedItems();
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
