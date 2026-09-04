import 'dart:async';

import 'package:dino_run_flame/features/auth/domain/auth_models.dart';
import 'package:dino_run_flame/features/auth/domain/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthSessionSnapshot? session})
    : _session = session ?? const AuthSessionSnapshot.signedOut();

  factory FakeAuthRepository.signedIn({
    String userId = 'user-1',
    String email = 'player@example.com',
    String displayName = 'Player',
  }) {
    return FakeAuthRepository(
      session: AuthSessionSnapshot.authenticated(
        AuthUserProfile(
          id: userId,
          email: email,
          displayName: displayName,
          isEmailVerified: true,
        ),
      ),
    );
  }

  final StreamController<AuthSessionSnapshot> _controller =
      StreamController<AuthSessionSnapshot>.broadcast(sync: true);
  AuthSessionSnapshot _session;

  @override
  AuthSessionSnapshot get currentSession => _session;

  @override
  Stream<AuthSessionSnapshot> get sessionChanges => _controller.stream;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> dispose() => _controller.close();

  @override
  Future<void> linkProvider(AuthProviderId provider) async {}

  @override
  Future<void> reauthenticate() async {}

  @override
  Future<void> register(RegistrationRequest request) async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithProvider(AuthProviderId provider) async {}

  @override
  Future<void> signOut() async {
    _session = const AuthSessionSnapshot.signedOut();
    _controller.add(_session);
  }

  @override
  Future<void> updatePassword(String password) async {}
}
