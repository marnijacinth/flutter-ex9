import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/account.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bank.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, fileName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        accountHolder TEXT NOT NULL,
        balance REAL NOT NULL
      )
    ''');
  }

  Future<Account> insertAccount(Account account) async {
    final db = await instance.database;
    final id = await db.insert('accounts', account.toMap());
    return account..id = id;
  }

  Future<List<Account>> getAccounts() async {
    final db = await instance.database;
    final maps = await db.query('accounts', orderBy: 'id DESC');
    return maps.map((m) => Account.fromMap(m)).toList();
  }

  Future<int> updateAccount(Account account) async {
    final db = await instance.database;
    return db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await instance.database;
    return db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> totalBalance() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(balance) as total FROM accounts',
    );
    final total = result.first['total'];
    if (total == null) return 0.0;
    return (total as num).toDouble();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
