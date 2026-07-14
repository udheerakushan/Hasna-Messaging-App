import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class CryptoService {
  static final _aead = AesGcm.with256bits();

  // Symmetric encryption helpers (useful for group keys)
  static Future<Uint8List> encryptWithSymmetricKey(
      List<int> keyBytes, List<int> data) async {
    final secretKey = SecretKey(keyBytes);
    final nonce =
        Nonce(List<int>.generate(12, (_) => DateTime.now().microsecond % 256));
    final secretBox =
        await _aead.encrypt(data, secretKey: secretKey, nonce: nonce);
    final out = <int>[];
    out.addAll(secretBox.nonce);
    out.addAll(secretBox.cipherText);
    out.addAll(secretBox.mac.bytes);
    return Uint8List.fromList(out);
  }

  static Future<Uint8List?> decryptWithSymmetricKey(
      List<int> keyBytes, List<int> package) async {
    try {
      final data = package;
      if (data.length < 12 + 16) return null;
      final nonce = data.sublist(0, 12);
      final macLen = 16;
      final mac = data.sublist(data.length - macLen);
      final cipher = data.sublist(12, data.length - macLen);
      final secretKey = SecretKey(keyBytes);
      final secretBox = SecretBox(cipher, nonce: nonce, mac: Mac(mac));
      final clear = await _aead.decrypt(secretBox, secretKey: secretKey);
      return Uint8List.fromList(clear);
    } catch (e) {
      return null;
    }
  }

  // Placeholder methods for encryptBackup and decryptBackup
  static Future<List<int>> encryptBackup(
      String myPrivateB64, String plaintext) async {
    // TODO: Implement backup encryption
    return [];
  }

  static Future<String> decryptBackup(
      String myPrivateB64, List<int> package) async {
    // TODO: Implement backup decryption
    return '<<decryption error>>';
  }
}
