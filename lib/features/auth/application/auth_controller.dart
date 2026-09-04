import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/auth_models.dart';

enum AuthOperation {
  idle,
  registering,
  signingIn,
  sendingReset,
  updatingPassword,
  openingProvider,
  linkingProvider,
  reauthenticating,
  signingOut,
  deletingAccount,
}

class AuthViewState {
  const AuthViewState({
    required this.session,
    this.operation = AuthOperation.idle,
    this.notice,
    this.error,
  });

  final AuthSessionSnapshot session;
  final AuthOperation operation;
  final String? notice;
  final String? error;

  bool get isBusy => operation != AuthOperation.idle;

  AuthViewState copyWith({
    AuthSessionSnapshot? session,
    AuthOperation? operation,
    String? notice,
    String? error,
    bool clearMessages = false,
  }) {
    return AuthViewState(
      session: session ?? this.session,
      operation: operation ?? this.operation,
      notice: clearMessages ? null : notice ?? this.notice,
      error: clearMessages ? null : error ?? this.error,
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthViewState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthViewState> {
  StreamSubscription<AuthSessionSnapshot>? _subscription;

  @override
  AuthViewState build() {
    final repository = ref.watch(authRepositoryProvider);
    _subscription?.cancel();
    _subscription = repository.sessionChanges.listen((session) {
      state = state.copyWith(session: session, clearMessages: true);
    });
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
    });
    return AuthViewState(session: repository.currentSession);
  }

  Future<bool> register(RegistrationRequest request) {
    return _run(
      AuthOperation.registering,
      () => ref.read(authRepositoryProvider).register(request),
    );
  }

  Future<bool> signIn({required String email, required String password}) {
    return _run(
      AuthOperation.signingIn,
      () => ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password),
    );
  }

  Future<bool> sendPasswordReset(String email) {
    return _run(
      AuthOperation.sendingReset,
      () => ref.read(authRepositoryProvider).sendPasswordReset(email),
      success: 'Si existe una cuenta, recibirás instrucciones para continuar.',
    );
  }

  Future<bool> updatePassword(String password) {
    return _run(
      AuthOperation.updatingPassword,
      () => ref.read(authRepositoryProvider).updatePassword(password),
      success: 'Contraseña actualizada.',
    );
  }

  Future<bool> signInWithProvider(AuthProviderId provider) {
    return _run(
      AuthOperation.openingProvider,
      () => ref.read(authRepositoryProvider).signInWithProvider(provider),
    );
  }

  Future<bool> linkProvider(AuthProviderId provider) {
    return _run(
      AuthOperation.linkingProvider,
      () => ref.read(authRepositoryProvider).linkProvider(provider),
    );
  }

  Future<bool> reauthenticate() {
    return _run(
      AuthOperation.reauthenticating,
      ref.read(authRepositoryProvider).reauthenticate,
      success: 'Solicitud de reautenticación enviada.',
    );
  }

  Future<bool> signOut() {
    return _run(
      AuthOperation.signingOut,
      ref.read(authRepositoryProvider).signOut,
    );
  }

  Future<bool> deleteAccount() {
    return _run(
      AuthOperation.deletingAccount,
      ref.read(authRepositoryProvider).deleteAccount,
    );
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }

  Future<bool> _run(
    AuthOperation operation,
    Future<void> Function() action, {
    String? success,
  }) async {
    if (state.isBusy) {
      return false;
    }
    state = state.copyWith(operation: operation, clearMessages: true);
    try {
      await action();
      state = state.copyWith(
        operation: AuthOperation.idle,
        notice: success,
        clearMessages: success == null,
      );
      return true;
    } on AppFailure catch (failure) {
      state = state.copyWith(
        operation: AuthOperation.idle,
        error: failure.message,
      );
      return false;
    } on Object {
      state = state.copyWith(
        operation: AuthOperation.idle,
        error: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      );
      return false;
    }
  }
}
