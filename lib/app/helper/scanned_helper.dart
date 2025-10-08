import 'package:lms_qr_generator/app/models/scanned_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('scanned.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void>  dropTable() async {
    final db = await instance.database;
    return  db.execute('DROP TABLE IF EXISTS scanned_log');
  }

  Future<void>  truncateTable() async {
    final db = await instance.database;
    return  db.execute('DELETE FROM scanned_log;');

  }

  Future<void>  createTable() async {
    final db = await instance.database;
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    await db.execute('''
      CREATE TABLE scanned_log (
        id $idType,
        it $textType,
        nt $textType,
        at $textType,
        pt $textType,
        date $textType
      )
    ''');
  }



  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    await db.execute('''
      CREATE TABLE scanned_log (
        id $idType,
        it $textType,
        nt $textType,
        at $textType,
        pt $textType,
        date $textType
      )
    ''');
  }

  // Insert user
  Future<int> insertScanned(ScannedItem scanneditem) async {
    final db = await instance.database;
    return await db.insert('scanned_log', scanneditem.toMap());
  }

  // Get all users
  Future<List<ScannedItem>> getRiwayatScan() async {
    final db = await instance.database;
    final result = await db.query('scanned_log', orderBy: 'id DESC');
    return result.map((map) => ScannedItem.fromMap(map)).toList();
  }


}