import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// NOTE: This is an improved placeholder encryption layer for demo/prototyping only.
/// It derives a symmetric key from the sender's private material and the peer public
/// material using SHA-256, then XORs the plaintext with a keystream. This is NOT a
/// production-grade authenticated encryption scheme. For production, replace with
/// X25519 + HKDF + ChaCha20-Poly1305 (or the Signal protocol).

class CryptoService {
  static Future<String> encrypt(String peerPublic, String myPrivate, String plaintext) async {
    // Derive a simple shared secret: sha256(private + peerPublic)
    final bytes = utf8.encode(myPrivate + peerPublic);
    final digest = sha256.convert(bytes).bytes;
    final keystream = _expandKeystream(digest, plaintext.length);
    final pt = utf8.encode(plaintext);
    final cipher = List<int>.generate(pt.length, (i) => pt[i] ^ keystream[i]);
    return base64UrlEncode(cipher);
  }

  static Future<String> decrypt(String peerPublic, String myPrivate, String ciphertext) async {
    try {
      final cipher = base64Url.decode(ciphertext);
      final bytes = utf8.encode(myPrivate + peerPublic);
      final digest = sha256.convert(bytes).bytes;
      final keystream = _expandKeystream(digest, cipher.length);
      final plain = List<int>.generate(cipher.length, (i) => cipher[i] ^ keystream[i]);
      return utf8.decode(plain);
    } catch (e) {
      return '<<decryption error>>';
    }
  }

  static List<int> _expandKeystream(List<int> seed, int len) {
    // Simple HKDF-like expansion using repeated SHA256 (NOT ideal but OK for demo)
    final out = <int>[];
    var counter = 0;
    while (out.length < len) {
      final chunk = sha256.convert([...seed, counter]).bytes;
      out.addAll(chunk);
      counter++;
    }
    return out.sublist(0, len);
  }
}
