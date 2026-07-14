*** Begin Patch
*** Update File: lib/main.dart
@@
   Future<void> _sendImage() async {
     final picker = ImagePicker();
     final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
     if (picked == null) return;

     final bytes = await picked.readAsBytes();
-    final docs = await getApplicationDocumentsDirectory();
-    final file = File('${docs.path}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}');
-    await file.writeAsBytes(bytes);
-
-    // For demo, we store local file path. For real E2EE, encrypt bytes and send via P2P.
-    final msg = {
-      'peer_id': widget.peerId,
-      'sender': 'me',
-      'content': file.path,
-      'type': 'image',
-      'timestamp': DateTime.now().toIso8601String(),
-      'status': 'sent'
-    };
-
-    await DBService.insertMessage(msg);
-    setState(() => _messages.add(msg));
+    // Encrypt image bytes for peer (if peer public key exists) and store encrypted file
+    final me = await KeyStorage.getProfile();
+    final peerPublic = await KeyStorage.getPublicKeyFor(widget.peerId);
+    String encryptedB64;
+    if (peerPublic != null && peerPublic.isNotEmpty) {
+      encryptedB64 = await CryptoService.encryptBytesForPeer(peerPublic, me['private']!, bytes);
+    } else {
+      // fallback: store raw bytes base64 (not secure) — prefer contacting peer key first
+      encryptedB64 = base64UrlEncode(bytes);
+    }
+
+    final docs = await getApplicationDocumentsDirectory();
+    final fname = 'encimg_${DateTime.now().millisecondsSinceEpoch}.bin';
+    final file = File('${docs.path}/$fname');
+    await file.writeAsBytes(base64Url.decode(encryptedB64));
+
+    final msg = {
+      'peer_id': widget.peerId,
+      'sender': 'me',
+      'content': file.path,
+      'type': 'image_encrypted',
+      'timestamp': DateTime.now().toIso8601String(),
+      'status': 'sent'
+    };
+
+    await DBService.insertMessage(msg);
+    setState(() => _messages.add(msg));
   }
@@
-    if (m['type'] == 'image') {
-      final file = File(content);
-      messageBody = GestureDetector(
-        onLongPress: () => _addReaction(index),
-        child: Column(
-          crossAxisAlignment: CrossAxisAlignment.end,
-          children: [
-            Image.file(file, width: 200, height: 200, fit: BoxFit.cover),
-            const SizedBox(height: 6),
-            Row(
-              mainAxisSize: MainAxisSize.min,
-              children: [
-                Text(formattedTime, style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black54)),
-                const SizedBox(width: 6),
-                if (isMe) Icon(Icons.check, size: 12, color: Colors.white70),
-              ],
-            ),
-            if (m['reaction'] != null) Text(m['reaction'], style: const TextStyle(fontSize: 18))
-          ],
-        ),
-      );
+    if (m['type'] == 'image' || m['type'] == 'image_encrypted') {
+      final file = File(content);
+      Widget imageWidget = const SizedBox(width: 200, height: 200, child: Center(child: Text('Unable to load')));
+      try {
+        final bytes = await file.readAsBytes();
+        Uint8List? clear;
+        if (m['type'] == 'image_encrypted') {
+          final me = await KeyStorage.getProfile();
+          final peerPublic = await KeyStorage.getPublicKeyFor(widget.peerId);
+          if (peerPublic != null && peerPublic.isNotEmpty) {
+            // decrypt bytes using peer public (we assume stored encrypted by sender)
+            final b64 = base64UrlEncode(bytes);
+            final dec = await CryptoService.decryptBytesForPeer(peerPublic, me['private']!, b64);
+            if (dec != null) clear = dec;
+          } else {
+            // fallback: assume bytes are raw image
+            clear = bytes;
+          }
+        } else {
+          clear = bytes;
+        }
+        if (clear != null) imageWidget = Image.memory(clear, width: 200, height: 200, fit: BoxFit.cover);
+      } catch (_) {}
+
+      messageBody = GestureDetector(
+        onLongPress: () => _addReaction(index),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.end,
+          children: [
+            imageWidget,
+            const SizedBox(height: 6),
+            Row(
+              mainAxisSize: MainAxisSize.min,
+              children: [
+                Text(formattedTime, style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black54)),
+                const SizedBox(width: 6),
+                if (isMe) Icon(Icons.check, size: 12, color: Colors.white70),
+              ],
+            ),
+            if (m['reaction'] != null) Text(m['reaction'], style: const TextStyle(fontSize: 18))
+          ],
+        ),
+      );
     } else {
*** End Patch
