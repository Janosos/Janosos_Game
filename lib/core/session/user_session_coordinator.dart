import 'dart:async';
import 'dart:developer' as developer;

import '../../features/auth/domain/auth_models.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../persistence/app_database.dart';
import '../security/protected_store.dart';

class UserSessionCoordinator {
  UserSessionCoordinator({
    required AuthRepository authRepository,
    required AppDatabase database,
    required ProtectedStore protectedStore,
  }) : _authRepository = authRepository,
       _database = database,
       _protectedStore = protectedStore;

  final AuthRepository _authRepository;
  final AppDatabase _database;
  final ProtectedStore _protectedStore;
  StreamSubscription<AuthSessionSnapshot>? _subscription;
  String? _activeUserId;
  Future<void> _pendingTransition = Future.value();

  Future<void> start() async {
    await _apply(_authRepository.currentSession);
    _subscription = _authRepository.sessionChanges.listen((session) {
      _pendingTransition = _pendingTransition
          .then((_) => _apply(session))
          .catchError((Object error, StackTrace stackTrace) {
            developer.log(
              'Unable to apply an authentication namespace transition',
              name: 'session.coordinator',
              error: error,
              stackTrace: stackTrace,
            );
          });
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _pendingTransition;
  }

  Future<void> _apply(AuthSessionSnapshot session) async {
    final previousUserId = _activeUserId;
    final nextUser = session.user;
    if (previousUserId != null && previousUserId != nextUser?.id) {
      await _database.wipeUserNamespace(previousUserId);
      if (_protectedStore.availability.isAvailable) {
        await _protectedStore.deleteNamespace('user.$previousUserId');
      }
    }

    _activeUserId = nextUser?.id;
    if (nextUser == null) {
      return;
    }
    await _database.activateNamespace(
      userId: nextUser.id,
      protectedStorageAvailable: _protectedStore.availability.isAvailable,
    );
    await _database.cacheProfile(
      userId: nextUser.id,
      email: nextUser.email,
      displayName: nextUser.displayName,
      emailVerified: nextUser.isEmailVerified,
    );
  }
}
