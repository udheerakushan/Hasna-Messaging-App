import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyStorage {
  static const _storage = FlutterSecureStorage();
  static const _privateKeyKey = 'hasna_private';
  static const _publicKeyKey = 'hasna_public';
  static const _displayNameKey = 'hasna_name';
  static const _profileImageKey = 'hasna_image';
  static const _contactCodeKey = 'hasna_contact_code';

  static Future<void> init() async {
    // no-op for now
  }

  static Future<bool> hasKeyPair() async {
    final priv = await _storage.read(key: _privateKeyKey);
    final pub = await _storage.read(key: _publicKeyKey);
    return priv != null && pub != null;
  }

  static String _randomNumeric(int len) {
    final rnd = Random.secure();
    return List.generate(len, (_) => rnd.nextInt(10).toString()).join();
  }

  static Future<Map<String, String>> createKeyPairAndProfile({String? displayName}) async {
    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    final private = base64UrlEncode(bytes);
    final public = sha256.convert(bytes).bytes; // mock public = sha256(priv)
    final pubB64 = base64UrlEncode(public);

    final hasnaNumber = _randomNumeric(9); // like phone number
    final contactCode = 'HASNA-$hasnaNumber-$pubB64';

    await _storage.write(key: _privateKeyKey, value: private);
    await _storage.write(key: _publicKeyKey, value: pubB64);
    await _storage.write(key: _displayNameKey, value: displayName ?? 'Hasna User');
    await _storage.write(key: _contactCodeKey, value: contactCode);

    return {
      'private': private,
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
    // For now only the official bot (id '1') has a known public key baked into the app.
    if (peerId == '1') {
      // a stable mock public key for Hasna Help
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
