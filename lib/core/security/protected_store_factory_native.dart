import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'protected_store.dart';

ProtectedStore createProtectedStore() => NativeProtectedStore();

class NativeProtectedStore implements ProtectedStore {
  NativeProtectedStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _prefix = 'janosos.v6.';
  static const _probeKey = '${_prefix}availability_probe';

  final FlutterSecureStorage _storage;
  ProtectedStoreAvailability _availability =
      const ProtectedStoreAvailability.unavailable('Not initialized.');

  @override
  ProtectedStoreAvailability get availability => _availability;

  @override
  Future<ProtectedStoreAvailability> initialize() async {
    try {
      await _storage.write(key: _probeKey, value: 'ok');
      final value = await _storage.read(key: _probeKey);
      await _storage.delete(key: _probeKey);
      _availability = value == 'ok'
          ? const ProtectedStoreAvailability.available()
          : const ProtectedStoreAvailability.unavailable(
              'Secure storage verification failed.',
            );
    } on Object catch (error) {
      _availability = ProtectedStoreAvailability.unavailable(
        'Secure storage is unavailable: ${error.runtimeType}',
      );
    }
    return _availability;
  }

  @override
  Future<String?> read(String key) async {
    _requireAvailable();
    return _storage.read(key: '$_prefix$key');
  }

  @override
  Future<void> write(String key, String value) async {
    _requireAvailable();
    await _storage.write(key: '$_prefix$key', value: value);
  }

  @override
  Future<void> delete(String key) async {
    _requireAvailable();
    await _storage.delete(key: '$_prefix$key');
  }

  @override
  Future<void> deleteNamespace(String namespace) async {
    _requireAvailable();
    final values = await _storage.readAll();
    final namespacePrefix = '$_prefix$namespace.';
    for (final key in values.keys.where(
      (key) => key.startsWith(namespacePrefix),
    )) {
      await _storage.delete(key: key);
    }
  }

  void _requireAvailable() {
    if (!_availability.isAvailable) {
      throw StateError(_availability.reason ?? 'Secure storage unavailable.');
    }
  }
}
