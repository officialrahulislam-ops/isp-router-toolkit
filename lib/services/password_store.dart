import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The technician's list of commonly used router admin passwords.
/// Stored encrypted (Android Keystore). Never logged, never sent anywhere.
class PasswordStore extends ChangeNotifier {
  static const String _key = 'router_password_list_v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  List<String> _items = [];
  bool _loaded = false;

  List<String> get items => List.unmodifiable(_items);
  bool get loaded => _loaded;

  Future<void> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null) {
        _items = (jsonDecode(raw) as List<dynamic>).cast<String>();
      }
    } catch (_) {
      _items = [];
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> addAll(List<String> passwords) async {
    for (final p in passwords) {
      if (p.isNotEmpty && !_items.contains(p)) _items.add(p);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String password) async {
    _items.remove(password);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() => _storage.write(key: _key, value: jsonEncode(_items));
}
