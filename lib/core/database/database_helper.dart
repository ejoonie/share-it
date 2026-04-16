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
  static const int boolFalse = 0;
  static const int boolTrue = 1;

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
    await _createEventsTable(db);
  }

  Future<void> _createEventsTable(
    Database db, {
    bool ifNotExists = false,
  }) async {
    final ifNotExistsClause = ifNotExists ? 'IF NOT EXISTS ' : '';
    // amount is nullable because shopping events can omit price.
    await db.execute('''
      CREATE TABLE ${ifNotExistsClause}$eventsTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colEventType TEXT NOT NULL,
        $colTitle TEXT NOT NULL,
        $colAmount INTEGER,
        $colNote TEXT,
        $colCategory TEXT,
        $colType TEXT,
        $colQuantity TEXT,
        $colIsChecked INTEGER NOT NULL DEFAULT $boolFalse,
        $colCreatedAt TEXT NOT NULL,
        $colUpdatedAt TEXT NOT NULL,
        CHECK (
          ($colEventType = 'expense' AND $colAmount IS NOT NULL)
          OR $colEventType = 'shopping'
        ),
        CHECK (
          ($colEventType = 'expense' AND $colType IN ('income', 'expense'))
          OR ($colEventType = 'shopping' AND $colType IS NULL)
        )
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_events_event_type ON $eventsTable($colEventType)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Product decision for this phase: reset local data during v2 upgrade.
      await db.execute('DROP TABLE IF EXISTS $eventsTable');
      await db.execute('DROP TABLE IF EXISTS expenses');
      await db.execute('DROP TABLE IF EXISTS shopping_items');
      await _createEventsTable(db, ifNotExists: false);
    }
  }

  // Generic CRUD helpers
  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async { // TODO sort by param?
    final db = await database;
    return db.query(table, orderBy: '$colCreatedAt ASC');
  }

  Future<List<Map<String, dynamic>>> queryWhere( // TODO sort by param?
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
