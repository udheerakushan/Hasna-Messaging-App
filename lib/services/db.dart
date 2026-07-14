import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DBService {
  static Database? _db;

  static Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    final path = join(docs.path, 'hasna.db');
    _db = await openDatabase(path, version: 4, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE messages(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          peer_id TEXT,
          sender TEXT,
          content TEXT,
          type TEXT DEFAULT 'text',
          timestamp TEXT,
          status TEXT,
          reaction TEXT,
          forwarded_from TEXT,
          is_forwarded INTEGER DEFAULT 0
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
      await db.execute('''
        CREATE TABLE groups(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          members TEXT -- JSON array of peer_ids
        )
      ''');
    }, onUpgrade: (db, oldV, newV) async {
      if (oldV < 2) {
        try {
          await db.execute("ALTER TABLE messages ADD COLUMN type TEXT DEFAULT 'text'");
        } catch (_) {}
        try {
          await db.execute("ALTER TABLE messages ADD COLUMN reaction TEXT");
        } catch (_) {}
      }
      if (oldV < 3) {
        try {
          await db.execute("ALTER TABLE messages ADD COLUMN forwarded_from TEXT");
        } catch (_) {}
        try {
          await db.execute("ALTER TABLE messages ADD COLUMN is_forwarded INTEGER DEFAULT 0");
        } catch (_) {}
      }
      if (oldV < 4) {
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS groups(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              members TEXT
            )
          ''');
        } catch (_) {}
      }
    });
  }

  static Future<void> insertMessage(Map<String, dynamic> m) async {
    await _db?.insert('messages', m);
    // upsert conversation
    final peer = m['peer_id'];
    String name = m['peer_name'] ?? 'Unknown';
    // if group id, resolve name from groups table
    if (peer != null && peer.toString().startsWith('group:')) {
      final gid = peer.toString().split(':')[1];
      final res = await _db?.query('groups', where: 'id=?', whereArgs: [gid]);
      if (res != null && res.isNotEmpty) {
        name = res.first['name'] as String? ?? name;
      }
    }
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

  static Future<List<Map<String, dynamic>>> searchMessages(String query) async {
    final q = '%${query.replaceAll('%', '\%')}%';
    final res = await _db?.rawQuery('SELECT * FROM messages WHERE content LIKE ? ORDER BY id ASC', [q]);
    if (res == null) return [];
    return res.toList();
  }

  static Future<int> createGroup(String name, List<String> members) async {
    final membersJson = jsonEncode(members);
    final id = await _db?.insert('groups', {'name': name, 'members': membersJson});
    return id ?? 0;
  }

  static Future<List<Map<String, dynamic>>> getGroups() async {
    final res = await _db?.query('groups', orderBy: 'id DESC');
    if (res == null) return [];
    return res.map((r) => r).toList();
  }

  static Future<String> _getBackupFilePath() async {
    final docs = await getApplicationDocumentsDirectory();
    final path = join(docs.path, 'hasna-backup-${DateTime.now().millisecondsSinceEpoch}.json');
    return path;
  }
}
