import 'package:supabase_flutter/supabase_flutter.dart';

import 'protected_store.dart';

class ProtectedSessionStorage extends LocalStorage {
  ProtectedSessionStorage(this._store);

  static const _sessionKey = 'auth.session';
  final ProtectedStore _store;

  @override
  Future<void> initialize() async {
    final availability = await _store.initialize();
    if (!availability.isAvailable) {
      throw StateError(availability.reason ?? 'Secure storage unavailable.');
    }
  }

  @override
  Future<bool> hasAccessToken() async =>
      (await _store.read(_sessionKey)) != null;

  @override
  Future<String?> accessToken() => _store.read(_sessionKey);

  @override
  Future<void> removePersistedSession() => _store.delete(_sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _store.write(_sessionKey, persistSessionString);
}
