import 'auth_models.dart';

abstract interface class AuthRepository {
  AuthSessionSnapshot get currentSession;

  Stream<AuthSessionSnapshot> get sessionChanges;

  Future<void> register(RegistrationRequest request);

  Future<void> signIn({required String email, required String password});

  Future<void> sendPasswordReset(String email);

  Future<void> updatePassword(String password);

  Future<void> signInWithProvider(AuthProviderId provider);

  Future<void> linkProvider(AuthProviderId provider);

  Future<void> reauthenticate();

  Future<void> signOut();

  Future<void> deleteAccount();

  Future<void> dispose();
}
