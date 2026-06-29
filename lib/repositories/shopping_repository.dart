import 'entry_repository.dart';
import '../models/shopping_item_model.dart';

class ShoppingRepository {
  final EntryRepository _entryRepository;

  ShoppingRepository({required EntryRepository entryRepository})
      : _entryRepository = entryRepository;

  Future<List<ShoppingItemModel>> getAllItems() async {
    final entries = await _entryRepository.listEntries(
      q: {'q[kind_eq]': 'shopping'},
    );
    return entries.map(ShoppingItemModel.fromEntry).toList();
  }

  Future<ShoppingItemModel> addItem(ShoppingItemModel item) async {
    final entry = await _entryRepository.createEntry(
      kind: 'shopping',
      title: item.title.isEmpty ? null : item.title,
      amount: item.amount,
      content: item.content,
      checked: item.isChecked,
    );
    return ShoppingItemModel.fromEntry(entry);
  }

  Future<ShoppingItemModel> updateItem(ShoppingItemModel item) async {
    final entry = await _entryRepository.updateEntry(
      item.id!,
      title: item.title.isEmpty ? null : item.title,
      amount: item.amount,
      content: item.content,
      checked: item.isChecked,
    );
    return ShoppingItemModel.fromEntry(entry);
  }

  Future<void> deleteItem(int id) async {
    await _entryRepository.deleteEntry(id);
  }

  Future<ShoppingItemModel> toggleItem(ShoppingItemModel item) async {
    final entry = await _entryRepository.updateEntry(
      item.id!,
      checked: !item.isChecked,
    );
    return ShoppingItemModel.fromEntry(entry);
  }

  Future<void> deleteCheckedItems() async {
    final entries = await _entryRepository.listEntries(
      q: {'q[kind_eq]': 'shopping', 'q[checked_eq]': 'true'},
    );
    for (final entry in entries) {
      await _entryRepository.deleteEntry(entry.id);
    }
  }
}
