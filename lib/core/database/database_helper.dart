import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const String _databaseName = 'share_it.db';
  static const int _databaseVersion = 2;

  // Tables
  static const String eventsTable = 'events';

  // Shared event columns
  static const String colId = 'id';
  static const String colEventType = 'event_type'; // 'expense' or 'shopping'
  static const String colTitle = 'title';
  static const String colAmount = 'amount';
  static const String colNote = 'note';
  static const String colCategory = 'category';
  static const String colType = 'type'; // only for expense rows: 'income' or 'expense'
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';

  // Shopping-specific columns
  static const String colIsChecked = 'is_checked';
  static const String colQuantity = 'quantity';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $eventsTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colEventType TEXT NOT NULL,
        $colTitle TEXT NOT NULL,
        $colAmount INTEGER,
        $colNote TEXT,
        $colCategory TEXT,
        $colType TEXT,
        $colQuantity TEXT,
        $colIsChecked INTEGER NOT NULL DEFAULT 0,
        $colCreatedAt TEXT NOT NULL,
        $colUpdatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _onCreate(db, newVersion);

      if (await _tableExists(db, 'expenses')) {
        await db.execute('''
          INSERT INTO $eventsTable (
            $colEventType,
            $colTitle,
            $colAmount,
            $colNote,
            $colCategory,
            $colType,
            $colCreatedAt,
            $colUpdatedAt
          )
          SELECT
            'expense',
            $colTitle,
            $colAmount,
            $colNote,
            $colCategory,
            $colType,
            $colCreatedAt,
            $colUpdatedAt
          FROM expenses
        ''');
        await db.execute('DROP TABLE expenses');
      }

      if (await _tableExists(db, 'shopping_items')) {
        await db.execute('''
          INSERT INTO $eventsTable (
            $colEventType,
            $colTitle,
            $colAmount,
            $colQuantity,
            $colNote,
            $colIsChecked,
            $colCreatedAt,
            $colUpdatedAt
          )
          SELECT
            'shopping',
            $colTitle,
            $colAmount,
            $colQuantity,
            $colNote,
            $colIsChecked,
            $colCreatedAt,
            $colUpdatedAt
          FROM shopping_items
        ''');
        await db.execute('DROP TABLE shopping_items');
      }
    }
  }

  Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', tableName],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Generic CRUD helpers
  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return db.query(table, orderBy: '$colCreatedAt ASC');
  }

  Future<List<Map<String, dynamic>>> queryWhere(
    String table,
    String where,
    List<dynamic> whereArgs, {
    String orderBy = '$colCreatedAt ASC',
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> row,
    int id,
  ) async {
    final db = await database;
    return db.update(table, row, where: '$colId = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return db.delete(table, where: '$colId = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
