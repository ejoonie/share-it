import '../../../../core/database/database_helper.dart';
import '../models/shopping_item_model.dart';

class ShoppingRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const String _table = DatabaseHelper.shoppingTable;

  Future<List<ShoppingItemModel>> getAllItems() async {
    final rows = await _db.queryAll(_table);
    return rows.map(ShoppingItemModel.fromMap).toList();
  }

  Future<ShoppingItemModel> addItem(ShoppingItemModel item) async {
    final now = DateTime.now();
    final model = item.copyWith(createdAt: now, updatedAt: now);
    final id = await _db.insert(_table, model.toMap());
    return model.copyWith(id: id);
  }

  Future<ShoppingItemModel> updateItem(ShoppingItemModel item) async {
    final updated = item.copyWith(updatedAt: DateTime.now());
    await _db.update(_table, updated.toMap(), item.id!);
    return updated;
  }

  Future<void> deleteItem(int id) async {
    await _db.delete(_table, id);
  }

  Future<ShoppingItemModel> toggleItem(ShoppingItemModel item) async {
    final toggled = item.copyWith(
      isChecked: !item.isChecked,
      updatedAt: DateTime.now(),
    );
    await _db.update(_table, toggled.toMap(), item.id!);
    return toggled;
  }

  Future<void> deleteCheckedItems() async {
    final db = await _db.database;
    await db.delete(
      _table,
      where: '${DatabaseHelper.colIsChecked} = ?',
      whereArgs: [1],
    );
  }
}
