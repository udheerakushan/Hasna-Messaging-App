*** Begin Patch
*** Update File: lib/services/db.dart
@@
-    _db = await openDatabase(path, version: 4, onCreate: (db, v) async {
+    _db = await openDatabase(path, version: 5, onCreate: (db, v) async {
@@
-      await db.execute('''
-        CREATE TABLE groups(
-          id INTEGER PRIMARY KEY AUTOINCREMENT,
-          name TEXT,
-          members TEXT -- JSON array of peer_ids
-        )
-      ''');
+      await db.execute('''
+        CREATE TABLE groups(
+          id INTEGER PRIMARY KEY AUTOINCREMENT,
+          name TEXT,
+          members TEXT, -- JSON array of peer_ids
+          group_key TEXT -- base64 encoded symmetric group key (encrypted for local use)
+        )
+      ''');
@@
-      if (oldV < 4) {
+      if (oldV < 4) {
@@
-        try {
-          await db.execute('''
-            CREATE TABLE IF NOT EXISTS groups(
-              id INTEGER PRIMARY KEY AUTOINCREMENT,
-              name TEXT,
-              members TEXT
-            )
-          ''');
-        } catch (_) {}
+        try {
+          await db.execute('''
+            CREATE TABLE IF NOT EXISTS groups(
+              id INTEGER PRIMARY KEY AUTOINCREMENT,
+              name TEXT,
+              members TEXT,
+              group_key TEXT
+            )
+          ''');
+        } catch (_) {}
       }
     });
   }
*** End Patch
