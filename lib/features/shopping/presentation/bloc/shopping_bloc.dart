import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/shopping_repository.dart';
import 'shopping_event.dart';
import 'shopping_state.dart';

class ShoppingBloc extends Bloc<ShoppingEvent, ShoppingState> {
  final ShoppingRepository repository;

  ShoppingBloc({required this.repository}) : super(const ShoppingInitial()) {
    on<LoadShoppingItems>(_onLoad);
    on<AddShoppingItem>(_onAdd);
    on<UpdateShoppingItem>(_onUpdate);
    on<DeleteShoppingItem>(_onDelete);
    on<ToggleShoppingItem>(_onToggle);
    on<DeleteCheckedItems>(_onDeleteChecked);
  }

  Future<void> _onLoad(
    LoadShoppingItems event,
    Emitter<ShoppingState> emit,
  ) async {
    emit(const ShoppingLoading());
    try {
      final items = await repository.getAllItems();
      emit(ShoppingLoaded(items: items));
    } catch (e) {
      emit(ShoppingError(e.toString()));
    }
  }

  Future<void> _onAdd(
    AddShoppingItem event,
    Emitter<ShoppingState> emit,
  ) async {
    if (state is! ShoppingLoaded) return;
    final current = state as ShoppingLoaded;
    try {
      final added = await repository.addItem(event.item);
      emit(current.copyWith(items: [...current.items, added]));
    } catch (e) {
      emit(ShoppingError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateShoppingItem event,
    Emitter<ShoppingState> emit,
  ) async {
    if (state is! ShoppingLoaded) return;
    final current = state as ShoppingLoaded;
    try {
      final updated = await repository.updateItem(event.item);
      final items = current.items.map((i) {
        return i.id == updated.id ? updated : i;
      }).toList();
      emit(current.copyWith(items: items));
    } catch (e) {
      emit(ShoppingError(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteShoppingItem event,
    Emitter<ShoppingState> emit,
  ) async {
    if (state is! ShoppingLoaded) return;
    final current = state as ShoppingLoaded;
    try {
      await repository.deleteItem(event.id);
      final items = current.items.where((i) => i.id != event.id).toList();
      emit(current.copyWith(items: items));
    } catch (e) {
      emit(ShoppingError(e.toString()));
    }
  }

  Future<void> _onToggle(
    ToggleShoppingItem event,
    Emitter<ShoppingState> emit,
  ) async {
    if (state is! ShoppingLoaded) return;
    final current = state as ShoppingLoaded;
    try {
      final toggled = await repository.toggleItem(event.item);
      final items = current.items.map((i) {
        return i.id == toggled.id ? toggled : i;
      }).toList();
      emit(current.copyWith(items: items));
    } catch (e) {
      emit(ShoppingError(e.toString()));
    }
  }

  Future<void> _onDeleteChecked(
    DeleteCheckedItems event,
    Emitter<ShoppingState> emit,
  ) async {
    if (state is! ShoppingLoaded) return;
    final current = state as ShoppingLoaded;
    try {
      await repository.deleteCheckedItems();
      final items = current.items.where((i) => !i.isChecked).toList();
      emit(current.copyWith(items: items));
    } catch (e) {
      emit(ShoppingError(e.toString()));
    }
  }
}
