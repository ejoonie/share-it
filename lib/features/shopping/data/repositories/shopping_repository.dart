import '../../../../core/database/database_helper.dart';
import '../models/shopping_item_model.dart';

class ShoppingRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const String _table = DatabaseHelper.eventsTable;
  static const String _eventType = 'shopping';

  Future<List<ShoppingItemModel>> getAllItems() async {
    final rows = await _db.queryWhere(
      _table,
      '${DatabaseHelper.colEventType} = ?',
      [_eventType],
    );
    return rows.map(ShoppingItemModel.fromMap).toList();
  }

  Future<ShoppingItemModel> addItem(ShoppingItemModel item) async {
    final model = item.copyWith(updatedAt: DateTime.now());
    final row = model.toMap()
      ..[DatabaseHelper.colEventType] = _eventType
      ..[DatabaseHelper.colType] = null
      ..[DatabaseHelper.colCategory] = null;
    final id = await _db.insert(_table, row);
    return model.copyWith(id: id);
  }

  Future<ShoppingItemModel> updateItem(ShoppingItemModel item) async {
    final updated = item.copyWith(updatedAt: DateTime.now());
    final row = updated.toMap()
      ..[DatabaseHelper.colEventType] = _eventType
      ..[DatabaseHelper.colType] = null
      ..[DatabaseHelper.colCategory] = null;
    await _db.update(_table, row, item.id!);
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
    final row = toggled.toMap()
      ..[DatabaseHelper.colEventType] = _eventType
      ..[DatabaseHelper.colType] = null
      ..[DatabaseHelper.colCategory] = null;
    await _db.update(_table, row, item.id!);
    return toggled;
  }

  Future<void> deleteCheckedItems() async {
    final db = await _db.database;
    await db.delete(
      _table,
      where: '${DatabaseHelper.colEventType} = ? AND ${DatabaseHelper.colIsChecked} = ?',
      whereArgs: [_eventType, 1],
    );
  }
}
