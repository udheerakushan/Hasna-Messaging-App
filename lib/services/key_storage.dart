import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyStorage {
  static const _storage = FlutterSecureStorage();
  static const _privateKeyKey = 'hasna_private';
  static const _publicKeyKey = 'hasna_public';
  static const _displayNameKey = 'hasna_name';
  static const _profileImageKey = 'hasna_image';
  static const _contactCodeKey = 'hasna_contact_code';

  static Future<void> init() async {
    // no-op in this simple implementation
  }

  static String _randomNumeric(int len) {
    final rnd = DateTime.now().microsecond;
    final buf = StringBuffer();
    for (var i = 0; i < len; i++) {
      buf.write(((rnd + i * 37) % 10).toString());
    }
    return buf.toString();
  }

  static Future<bool> hasKeyPair() async {
    final priv = await _storage.read(key: _privateKeyKey);
    final pub = await _storage.read(key: _publicKeyKey);
    return priv != null && pub != null;
  }

  static Future<Map<String, String>> createKeyPairAndProfile({String? displayName}) async {
    // Generate an X25519 keypair
    final algorithm = X25519();
    final keyPair = await algorithm.newKeyPair();
    final private = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    final privB64 = base64UrlEncode(private);
    final pubB64 = base64UrlEncode(publicKey.bytes);

    final hasnaNumber = _randomNumeric(9);
    final contactCode = 'HASNA-$hasnaNumber-$pubB64';

    await _storage.write(key: _privateKeyKey, value: privB64);
    await _storage.write(key: _publicKeyKey, value: pubB64);
    await _storage.write(key: _displayNameKey, value: displayName ?? 'Hasna User');
    await _storage.write(key: _contactCodeKey, value: contactCode);

    return {
      'private': privB64,
      'public': pubB64,
      'displayName': displayName ?? 'Hasna User',
      'contact_code': contactCode,
      'number': hasnaNumber,
    };
  }

  static Future<Map<String, String>> getProfile() async {
    final priv = await _storage.read(key: _privateKeyKey) ?? '';
    final pub = await _storage.read(key: _publicKeyKey) ?? '';
    final name = await _storage.read(key: _displayNameKey) ?? 'Hasna User';
    final code = await _storage.read(key: _contactCodeKey) ?? '';
    return {
      'private': priv,
      'public': pub,
      'name': name,
      'contact_code': code,
    };
  }

  static Future<String?> getPublicKeyFor(String peerId) async {
    if (peerId == '1') {
      // official help bot public key placeholder (app-bundled)
      return 'HASNA_HELP_PUBLIC_KEY_PLACEHOLDER';
    }
    return null;
  }

  static Future<void> updateDisplayName(String name) async {
    await _storage.write(key: _displayNameKey, value: name);
  }

  static Future<void> saveProfileImage(String path) async {
    await _storage.write(key: _profileImageKey, value: path);
  }
}
