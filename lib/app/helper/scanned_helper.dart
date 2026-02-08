import 'package:lms_qr_generator/app/models/scanned_model.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
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
    final path = await _resolveDatabasePath(filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<String> _resolveDatabasePath(String filePath) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final directory = await getApplicationDocumentsDirectory();
      return join(directory.path, filePath);
    }
    final dbPath = await getDatabasesPath();
    return join(dbPath, filePath);
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
        telp $textType,
        ws $textType,
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
        telp $textType,
        ws $textType,
        date $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id $idType,
        it $textType,
        nt $textType,
        at $textType,
        pt $textType,
        ws $textType,
        np $textType,
        created_at $textType
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT';
      await db.execute('''
        CREATE TABLE IF NOT EXISTS customers (
          id $idType,
          it $textType,
          nt $textType,
          at $textType,
          pt $textType,
          ws $textType,
          np $textType,
          created_at $textType
        )
      ''');
    }
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

  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer);
  }

  Future<int> updateCustomer(Map<String, dynamic> customer) async {
    final db = await instance.database;
    return await db.update(
      'customers',
      customer,
      where: 'id = ?',
      whereArgs: [customer['id']],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await instance.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await instance.database;
    return await db.query('customers', orderBy: 'id DESC');
  }


}