import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class CryptoService {
  static final _x25519 = X25519();
  static final _hkdf = Hkdf(hmac: Hmac.sha256());
  static final _aead = Chacha20.poly1305Aead();

  static Future<SecretKey> _sharedSecretKey(String myPrivateB64, String peerPublicB64) async {
    final myPrivate = base64Url.decode(myPrivateB64);
    final peerPublic = base64Url.decode(peerPublicB64);
    final myKeyPair = SimpleKeyPairData(myPrivate, type: KeyPairType.x25519);
    final peerPublicKey = SimplePublicKey(peerPublic, type: KeyPairType.x25519);
    final shared = await _x25519.sharedSecretKey(keyPair: myKeyPair, remotePublicKey: peerPublicKey);
    return shared;
  }

  static Future<SecretKey> _deriveAesKey(SecretKey sharedSecret, {List<int> info = const []}) async {
    final secretKey = await _hkdf.deriveKey(secretKey: sharedSecret, info: info, outputLength: 32);
    return secretKey;
  }

  static Future<String> encrypt(String peerPublicB64, String myPrivateB64, String plaintext) async {
    final shared = await _sharedSecretKey(myPrivateB64, peerPublicB64);
    final aeadKey = await _deriveAesKey(shared, info: utf8.encode('hasna-e2ee'));
    final nonce = Nonce(List<int>.generate(12, (_) => DateTime.now().microsecondsSinceEpoch.remainder(256)));
    final secretKeyBytes = await aeadKey.extractBytes();
    final secretKey = SecretKey(secretKeyBytes);
    final secretBox = await _aead.encrypt(utf8.encode(plaintext), secretKey: secretKey, nonce: nonce.bytes);
    final out = <int>[];
    out.addAll(secretBox.nonce);
    out.addAll(secretBox.cipherText);
    out.addAll(secretBox.mac.bytes);
    return base64UrlEncode(out);
  }

  static Future<String> decrypt(String peerPublicB64, String myPrivateB64, String packageB64) async {
    try {
      final data = base64Url.decode(packageB64);
      if (data.length < 12 + 16) return '<<invalid package>>';
      final nonce = data.sublist(0, 12);
      final macLen = 16;
      final mac = data.sublist(data.length - macLen);
      final cipher = data.sublist(12, data.length - macLen);
      final shared = await _sharedSecretKey(myPrivateB64, peerPublicB64);
      final aeadKey = await _deriveAesKey(shared, info: utf8.encode('hasna-e2ee'));
      final secretKeyBytes = await aeadKey.extractBytes();
      final secretKey = SecretKey(secretKeyBytes);
      final secretBox = SecretBox(cipher, nonce: nonce, mac: Mac(mac));
      final clear = await _aead.decrypt(secretBox, secretKey: secretKey);
      return utf8.decode(clear);
    } catch (e) {
      return '<<decryption error>>';
    }
  }

  // Encrypt arbitrary bytes for sending to a peer using X25519-derived key; returns base64 package
  static Future<String> encryptBytesForPeer(String peerPublicB64, String myPrivateB64, List<int> data) async {
    final shared = await _sharedSecretKey(myPrivateB64, peerPublicB64);
    final aeadKey = await _deriveAesKey(shared, info: utf8.encode('hasna-e2ee-bytes'));
    final nonce = Nonce(List<int>.generate(12, (_) => DateTime.now().microsecondsSinceEpoch.remainder(256)));
    final secretKeyBytes = await aeadKey.extractBytes();
    final secretKey = SecretKey(secretKeyBytes);
    final secretBox = await _aead.encrypt(data, secretKey: secretKey, nonce: nonce.bytes);
    final out = <int>[];
    out.addAll(secretBox.nonce);
    out.addAll(secretBox.cipherText);
    out.addAll(secretBox.mac.bytes);
    return base64UrlEncode(out);
  }

  static Future<Uint8List?> decryptBytesForPeer(String peerPublicB64, String myPrivateB64, String packageB64) async {
    try {
      final data = base64Url.decode(packageB64);
      if (data.length < 12 + 16) return null;
      final nonce = data.sublist(0, 12);
      final macLen = 16;
      final mac = data.sublist(data.length - macLen);
      final cipher = data.sublist(12, data.length - macLen);
      final shared = await _sharedSecretKey(myPrivateB64, peerPublicB64);
      final aeadKey = await _deriveAesKey(shared, info: utf8.encode('hasna-e2ee-bytes'));
      final secretKeyBytes = await aeadKey.extractBytes();
      final secretKey = SecretKey(secretKeyBytes);
      final secretBox = SecretBox(cipher, nonce: nonce, mac: Mac(mac));
      final clear = await _aead.decrypt(secretBox, secretKey: secretKey);
      return Uint8List.fromList(clear);
    } catch (e) {
      return null;
    }
  }

  // Backup encryption using user's private key as seed (local-only)
  static Future<List<int>> encryptBackup(String myPrivateB64, String plaintext) async {
    final bytes = base64Url.decode(myPrivateB64);
    final hkdf = Hkdf(hmac: Hmac.sha256());
    final sk = await hkdf.deriveKey(secretKey: SecretKey(bytes), info: utf8.encode('hasna-backup'), outputLength: 32);
    final nonce = Nonce(List<int>.generate(12, (_) => DateTime.now().microsecondsSinceEpoch.remainder(256)));
    final secretKeyBytes = await sk.extractBytes();
    final secretKey = SecretKey(secretKeyBytes);
    final secretBox = await _aead.encrypt(utf8.encode(plaintext), secretKey: secretKey, nonce: nonce.bytes);
    final out = <int>[];
    out.addAll(secretBox.nonce);
    out.addAll(secretBox.cipherText);
    out.addAll(secretBox.mac.bytes);
    return out;
  }

  static Future<String> decryptBackup(String myPrivateB64, List<int> package) async {
    try {
      final data = package;
      if (data.length < 12 + 16) return '<<invalid package>>';
      final nonce = data.sublist(0, 12);
      final macLen = 16;
      final mac = data.sublist(data.length - macLen);
      final cipher = data.sublist(12, data.length - macLen);
      final bytes = base64Url.decode(myPrivateB64);
      final hkdf = Hkdf(hmac: Hmac.sha256());
      final sk = await hkdf.deriveKey(secretKey: SecretKey(bytes), info: utf8.encode('hasna-backup'), outputLength: 32);
      final secretKeyBytes = await sk.extractBytes();
      final secretKey = SecretKey(secretKeyBytes);
      final secretBox = SecretBox(cipher, nonce: nonce, mac: Mac(mac));
      final clear = await _aead.decrypt(secretBox, secretKey: secretKey);
      return utf8.decode(clear);
    } catch (e) {
      return '<<decryption error>>';
    }
  }
}
