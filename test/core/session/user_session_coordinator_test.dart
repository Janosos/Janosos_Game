import 'dart:async';

import 'package:dino_run_flame/core/persistence/app_database.dart';
import 'package:dino_run_flame/core/security/protected_store.dart';
import 'package:dino_run_flame/core/session/user_session_coordinator.dart';
import 'package:dino_run_flame/features/auth/domain/auth_models.dart';
import 'package:dino_run_flame/features/auth/domain/auth_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late _FakeAuthRepository authRepository;
  late _RecordingProtectedStore protectedStore;
  late UserSessionCoordinator coordinator;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    authRepository = _FakeAuthRepository(_authenticated('user-a'));
    protectedStore = _RecordingProtectedStore();
    coordinator = UserSessionCoordinator(
      authRepository: authRepository,
      database: database,
      protectedStore: protectedStore,
    );
  });

  tearDown(() async {
    await coordinator.dispose();
    await authRepository.dispose();
    await database.close();
  });

  test(
    'account switching and logout wipe only the previous namespace',
    () async {
      await coordinator.start();
      expect(
        (await database.select(database.userNamespaces).getSingle()).userId,
        'user-a',
      );

      authRepository.emit(_authenticated('user-b'));
      await _settleTransitions();

      final afterSwitch = await database.select(database.userNamespaces).get();
      expect(afterSwitch.map((row) => row.userId), ['user-b']);
      expect(protectedStore.deletedNamespaces, ['user.user-a']);

      authRepository.emit(const AuthSessionSnapshot.signedOut());
      await _settleTransitions();

      expect(await database.select(database.userNamespaces).get(), isEmpty);
      expect(protectedStore.deletedNamespaces, ['user.user-a', 'user.user-b']);
    },
  );
}

AuthSessionSnapshot _authenticated(String id) {
  return AuthSessionSnapshot.authenticated(
    AuthUserProfile(
      id: id,
      email: '$id@example.com',
      displayName: id,
      isEmailVerified: true,
    ),
  );
}

Future<void> _settleTransitions() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._session);

  final StreamController<AuthSessionSnapshot> _controller =
      StreamController<AuthSessionSnapshot>.broadcast(sync: true);
  AuthSessionSnapshot _session;

  void emit(AuthSessionSnapshot session) {
    _session = session;
    _controller.add(session);
  }

  @override
  AuthSessionSnapshot get currentSession => _session;

  @override
  Stream<AuthSessionSnapshot> get sessionChanges => _controller.stream;

  @override
  Future<void> dispose() => _controller.close();

  @override
  Future<void> deleteAccount() => throw UnsupportedError('not used');

  @override
  Future<void> linkProvider(AuthProviderId provider) =>
      throw UnsupportedError('not used');

  @override
  Future<void> reauthenticate() => throw UnsupportedError('not used');

  @override
  Future<void> register(RegistrationRequest request) =>
      throw UnsupportedError('not used');

  @override
  Future<void> sendPasswordReset(String email) =>
      throw UnsupportedError('not used');

  @override
  Future<void> signIn({required String email, required String password}) =>
      throw UnsupportedError('not used');

  @override
  Future<void> signInWithProvider(AuthProviderId provider) =>
      throw UnsupportedError('not used');

  @override
  Future<void> signOut() => throw UnsupportedError('not used');

  @override
  Future<void> updatePassword(String password) =>
      throw UnsupportedError('not used');
}

class _RecordingProtectedStore implements ProtectedStore {
  final List<String> deletedNamespaces = [];

  @override
  ProtectedStoreAvailability get availability =>
      const ProtectedStoreAvailability.available();

  @override
  Future<ProtectedStoreAvailability> initialize() async => availability;

  @override
  Future<void> delete(String key) async {}

  @override
  Future<void> deleteNamespace(String namespace) async {
    deletedNamespaces.add(namespace);
  }

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}
}
