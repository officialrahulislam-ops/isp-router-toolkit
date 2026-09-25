import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around flutter_secure_storage, configured for
/// Android Keystore-backed encryption at rest. This is the ONLY class
/// in the app allowed to touch raw secret bytes on disk — everything
/// else (credential list, PINs, per-session router passwords the admin
/// chooses to save) goes through here.
class SecureStorageService {
  SecureStorageService._internal();
  static final SecureStorageService instance = SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // uses Android Keystore-wrapped key
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<void> writeString(String key, String value) => _storage.write(key: key, value: value);

  Future<String?> readString(String key) => _storage.read(key: key);

  Future<void> writeJson(String key, Object value) =>
      _storage.write(key: key, value: jsonEncode(value));

  Future<T?> readJson<T>(String key, T Function(dynamic decoded) fromJson) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    return fromJson(jsonDecode(raw));
  }

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();
}
