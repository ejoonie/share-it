import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const String _databaseName = 'share_it.db';
  static const int _databaseVersion = 1;

  // Tables
  static const String expenseTable = 'expenses';
  static const String shoppingTable = 'shopping_items';

  // Expense columns
  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colAmount = 'amount';
  static const String colNote = 'note';
  static const String colCategory = 'category';
  static const String colType = 'type'; // 'income' or 'expense'
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';

  // Shopping columns
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
      CREATE TABLE $expenseTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colTitle TEXT NOT NULL,
        $colAmount INTEGER NOT NULL,
        $colNote TEXT,
        $colCategory TEXT,
        $colType TEXT NOT NULL DEFAULT 'expense',
        $colCreatedAt TEXT NOT NULL,
        $colUpdatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $shoppingTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colTitle TEXT NOT NULL,
        $colAmount INTEGER,
        $colQuantity TEXT,
        $colNote TEXT,
        $colIsChecked INTEGER NOT NULL DEFAULT 0,
        $colCreatedAt TEXT NOT NULL,
        $colUpdatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
  }

  // Generic CRUD helpers
  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return db.query(table, orderBy: '$colCreatedAt DESC');
  }

  Future<List<Map<String, dynamic>>> queryWhere(
    String table,
    String where,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: '$colCreatedAt ASC',
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
