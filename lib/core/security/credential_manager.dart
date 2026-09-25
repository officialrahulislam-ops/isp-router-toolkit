import 'package:flutter/foundation.dart';
import '../constants.dart';
import 'secure_storage_service.dart';

/// Manages the technician's configurable list of common admin passwords
/// (spec section 7). Backed by encrypted storage; nothing here is ever
/// written to plain SharedPreferences, logs, or sent off-device.
class CredentialManager extends ChangeNotifier {
  CredentialManager._internal();
  static final CredentialManager instance = CredentialManager._internal();

  List<String> _credentials = [];
  bool _loaded = false;

  List<String> get credentials => List.unmodifiable(_credentials);

  Future<void> load() async {
    if (_loaded) return;
    final stored = await SecureStorageService.instance
        .readJson<List<dynamic>>(AppConstants.storageKeyCredentialList, (d) => d as List<dynamic>);

    if (stored == null) {
      // First run: seed with a minimal default, NOT the technician's full
      // real-world list — the admin should deliberately enter/import that
      // list on first setup, rather than ship it baked into the app.
      _credentials = List.of(AppConstants.defaultSeedCredentials);
      await _persist();
    } else {
      _credentials = stored.cast<String>();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> addCredential(String password) async {
    if (password.isEmpty || _credentials.contains(password)) return;
    _credentials.add(password);
    await _persist();
    notifyListeners();
  }

  Future<void> removeCredential(String password) async {
    _credentials.remove(password);
    await _persist();
    notifyListeners();
  }

  Future<void> reorder(List<String> newOrder) async {
    _credentials = List.of(newOrder);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() =>
      SecureStorageService.instance.writeJson(AppConstants.storageKeyCredentialList, _credentials);
}
