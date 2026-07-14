import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _db;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'hasna_messaging.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            peer_id TEXT,
            content TEXT,
            timestamp INTEGER,
            is_sent INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE contacts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            peer_id TEXT UNIQUE,
            name TEXT,
            public_key TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE groups(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            members TEXT,
            group_key TEXT
          )
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS contacts(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                peer_id TEXT UNIQUE,
                name TEXT,
                public_key TEXT
              )
            ''');
          } catch (_) {}
        }
        if (oldV < 4) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS groups(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT,
                members TEXT,
                group_key TEXT
              )
            ''');
          } catch (_) {}
        }
      },
    );
  }

  Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await this.db;
    await db.insert('messages', message);
  }

  Future<List<Map<String, dynamic>>> getMessages(String peerId) async {
    final db = await this.db;
    return await db.query('messages', where: 'peer_id = ?', whereArgs: [peerId]);
  }

  Future<void> insertContact(Map<String, dynamic> contact) async {
    final db = await this.db;
    await db.insert('contacts', contact, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await this.db;
    return await db.query('contacts');
  }

  Future<void> close() async {
    final db = await this.db;
    await db.close();
  }
}
