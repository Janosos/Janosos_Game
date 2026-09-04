import 'package:dino_run_flame/core/security/protected_store.dart';

class MemoryProtectedStore implements ProtectedStore {
  MemoryProtectedStore({bool available = true})
    : _availability = available
          ? const ProtectedStoreAvailability.available()
          : const ProtectedStoreAvailability.unavailable(
              'Unavailable in test.',
            );

  final Map<String, String> values = {};
  final ProtectedStoreAvailability _availability;

  @override
  ProtectedStoreAvailability get availability => _availability;

  @override
  Future<ProtectedStoreAvailability> initialize() async => _availability;

  @override
  Future<String?> read(String key) async {
    _requireAvailable();
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _requireAvailable();
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<void> deleteNamespace(String namespace) async {
    values.removeWhere((key, value) => key.startsWith('$namespace.'));
  }

  void _requireAvailable() {
    if (!_availability.isAvailable) {
      throw StateError(_availability.reason ?? 'Unavailable in test.');
    }
  }
}
