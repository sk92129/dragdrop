// Kang Engineering Systems LLC, 2026, Copyright protection

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class SecureStorageKeys {
  static const String companyId = 'company_id';
}

class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  FlutterSecureStorage? _storage;

  static const _kAppHasRunBefore = 'app_has_run_before';

  bool get isInitialized => _storage != null;

  Future<void> cleanOrphanedDataOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRunBefore = prefs.getBool(_kAppHasRunBefore) ?? false;

    if (!hasRunBefore) {
      // SharedPreferences was wiped by uninstall (or this is a fresh install).
      // Clear any lingering Keychain entries from previous installations.
      await _requireStorage.deleteAll();

      // Mark the app as initialized
      await prefs.setBool(_kAppHasRunBefore, true);
    }
  }

  Future<void> initialize({FlutterSecureStorage? storage}) async {
    if (_storage != null) {
      return;
    }
    _storage = storage ?? const FlutterSecureStorage();
    await cleanOrphanedDataOnFirstLaunch();
  }

  FlutterSecureStorage get _requireStorage {
    final FlutterSecureStorage? storage = _storage;
    if (storage == null) {
      throw StateError(
        'SecureStorageService.initialize() must be called before use.',
      );
    }
    return storage;
  }

  Future<void> write(String key, String value) {
    return _requireStorage.write(key: key, value: value);
  }

  Future<String?> read(String key) {
    return _requireStorage.read(key: key);
  }

  Future<void> delete(String key) {
    return _requireStorage.delete(key: key);
  }

  Future<void> deleteAll() {
    return _requireStorage.deleteAll();
  }
}
