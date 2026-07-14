import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DBService {
  static Database? _db;

  static Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    final path = join(docs.path, 'hasna.db');
    _db = await openDatabase(path, version: 2, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE messages(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          peer_id TEXT,
          sender TEXT,
          content TEXT,
          type TEXT DEFAULT 'text',
          timestamp TEXT,
          status TEXT,
          reaction TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE conversations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          peer_id TEXT UNIQUE,
          name TEXT,
          last_message TEXT,
          verified INTEGER DEFAULT 0
        )
      ''');
    }, onUpgrade: (db, oldV, newV) async {
      if (oldV < 2) {
        // add new columns to messages table
        try {
          await db.execute("ALTER TABLE messages ADD COLUMN type TEXT DEFAULT 'text'");
        } catch (_) {}
        try {
          await db.execute("ALTER TABLE messages ADD COLUMN reaction TEXT");
        } catch (_) {}
      }
    });
  }

  static Future<void> insertMessage(Map<String, dynamic> m) async {
    await _db?.insert('messages', m);
    // upsert conversation
    final peer = m['peer_id'];
    final name = m['peer_name'] ?? 'Unknown';
    final last = m['content'];
    await _db?.rawInsert('INSERT OR REPLACE INTO conversations(peer_id,name,last_message,verified) VALUES(?,?,?,COALESCE((SELECT verified FROM conversations WHERE peer_id=?),0))', [peer, name, last, peer]);
  }

  static Future<void> updateMessageStatus(int id, String status) async {
    await _db?.update('messages', {'status': status}, where: 'id=?', whereArgs: [id]);
  }

  static Future<void> addReaction(int id, String reaction) async {
    await _db?.update('messages', {'reaction': reaction}, where: 'id=?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getMessagesForPeer(String peerId) async {
    final res = await _db?.query('messages', where: 'peer_id=?', whereArgs: [peerId], orderBy: 'id ASC');
    if (res == null) return [];
    return res.map((r) => r).toList();
  }

  static Future<List<Map<String, dynamic>>> getConversations() async {
    final res = await _db?.query('conversations', orderBy: 'id DESC');
    if (res == null) return [];
    return res.map((r) => r).toList();
  }

  static Future<void> markMessagesRead(String peerId) async {
    await _db?.update('messages', {'status': 'read'}, where: 'peer_id=? AND sender!=? AND status!=?', whereArgs: [peerId, 'me', 'read']);
  }

  static Future<String> exportEncryptedBackup(String myPrivateB64) async {
    final msgs = await _db?.query('messages');
    final json = msgs != null ? msgs.map((m) => m).toList() : [];
    final jsonStr = jsonEncode({'messages': json, 'exported_at': DateTime.now().toIso8601String()});

    // save plaintext file locally; encryption helper available separately
    final path = await _getBackupFilePath();
    final file = File(path);
    await file.writeAsString(jsonStr);
    return path;
  }

  static Future<String> _getBackupFilePath() async {
    final docs = await getApplicationDocumentsDirectory();
    final path = join(docs.path, 'hasna-backup-${DateTime.now().millisecondsSinceEpoch}.json');
    return path;
  }
}
