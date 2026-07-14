*** Begin Patch
*** Update File: lib/services/crypto.dart
@@
   static Future<List<int>> encryptBackup(String myPrivateB64, String plaintext) async {
@@
     return out;
   }
 
   static Future<String> decryptBackup(String myPrivateB64, List<int> package) async {
@@
     } catch (e) {
       return '<<decryption error>>';
     }
   }
+
+  // Symmetric encryption helpers (useful for group keys)
+  static Future<Uint8List> encryptWithSymmetricKey(List<int> keyBytes, List<int> data) async {
+    final secretKey = SecretKey(keyBytes);
+    final nonce = Nonce(List<int>.generate(12, (_) => DateTime.now().microsecondsSinceEpoch.remainder(256)));
+    final secretBox = await _aead.encrypt(data, secretKey: secretKey, nonce: nonce.bytes);
+    final out = <int>[];
+    out.addAll(secretBox.nonce);
+    out.addAll(secretBox.cipherText);
+    out.addAll(secretBox.mac.bytes);
+    return Uint8List.fromList(out);
+  }
+
+  static Future<Uint8List?> decryptWithSymmetricKey(List<int> keyBytes, List<int> package) async {
+    try {
+      final data = package;
+      if (data.length < 12 + 16) return null;
+      final nonce = data.sublist(0, 12);
+      final macLen = 16;
+      final mac = data.sublist(data.length - macLen);
+      final cipher = data.sublist(12, data.length - macLen);
+      final secretKey = SecretKey(keyBytes);
+      final secretBox = SecretBox(cipher, nonce: nonce, mac: Mac(mac));
+      final clear = await _aead.decrypt(secretBox, secretKey: secretKey);
+      return Uint8List.fromList(clear);
+    } catch (e) {
+      return null;
+    }
+  }
*** End Patch
