import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required SupabaseClient client,
    required Uri redirectUri,
    String googleWebClientId = '',
    String googleAppleClientId = '',
  }) : _client = client,
       _redirectUri = redirectUri,
       _googleWebClientId = googleWebClientId,
       _googleAppleClientId = googleAppleClientId,
       _session = _snapshotFromUser(client.auth.currentUser) {
    _subscription = _client.auth.onAuthStateChange.listen((state) {
      _session = _snapshotFromUser(state.session?.user);
      _sessionController.add(_session);
    });
  }

  static const _uuid = Uuid();

  final SupabaseClient _client;
  final Uri _redirectUri;
  final String _googleWebClientId;
  final String _googleAppleClientId;
  final StreamController<AuthSessionSnapshot> _sessionController =
      StreamController<AuthSessionSnapshot>.broadcast(sync: true);
  late final StreamSubscription<AuthState> _subscription;
  AuthSessionSnapshot _session;
  Future<void>? _googleInitialization;

  @override
  AuthSessionSnapshot get currentSession => _session;

  @override
  Stream<AuthSessionSnapshot> get sessionChanges => _sessionController.stream;

  @override
  Future<void> register(RegistrationRequest request) async {
    await _guard(() async {
      await _client.auth.signUp(
        email: request.email.trim().toLowerCase(),
        password: request.password,
        emailRedirectTo: _redirectUri.toString(),
        data: {'display_name': request.displayName.trim()},
      );
    });
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    return _guard(() async {
      await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
    });
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _guard(() {
      return _client.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
        redirectTo: _redirectUri.toString(),
      );
    });
  }

  @override
  Future<void> updatePassword(String password) {
    return _guard(() async {
      await _client.auth.updateUser(UserAttributes(password: password));
    });
  }

  @override
  Future<void> signInWithProvider(AuthProviderId provider) {
    return _guard(() async {
      if (_supportsNativeProviderFlow) {
        await _nativeProviderFlow(provider, linkIdentity: false);
        return;
      }
      final launched = await _client.auth.signInWithOAuth(
        _oauthProvider(provider),
        redirectTo: _redirectUri.toString(),
      );
      if (!launched) {
        throw const AppFailure(
          AppFailureCode.unavailable,
          'No se pudo abrir el proveedor de inicio de sesión.',
        );
      }
    });
  }

  @override
  Future<void> linkProvider(AuthProviderId provider) {
    return _guard(() async {
      if (_supportsNativeProviderFlow) {
        await _nativeProviderFlow(provider, linkIdentity: true);
        return;
      }
      final launched = await _client.auth.linkIdentity(
        _oauthProvider(provider),
        redirectTo: _redirectUri.toString(),
      );
      if (!launched) {
        throw const AppFailure(
          AppFailureCode.unavailable,
          'No se pudo abrir el proveedor para vincularlo.',
        );
      }
    });
  }

  @override
  Future<void> reauthenticate() => _guard(_client.auth.reauthenticate);

  @override
  Future<void> signOut() => _guard(_client.auth.signOut);

  @override
  Future<void> deleteAccount() {
    return _guard(() async {
      final response = await _client.functions.invoke(
        'delete-account',
        body: {'idempotency_key': _uuid.v4()},
      );
      if (response.status < 200 || response.status >= 300) {
        throw const AppFailure(
          AppFailureCode.unavailable,
          'No se pudo completar la eliminación de la cuenta.',
        );
      }
      await _client.auth.signOut(scope: SignOutScope.local);
    });
  }

  @override
  Future<void> dispose() async {
    await _subscription.cancel();
    await _sessionController.close();
  }

  bool get _supportsNativeProviderFlow {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<void> _nativeProviderFlow(
    AuthProviderId provider, {
    required bool linkIdentity,
  }) {
    return switch (provider) {
      AuthProviderId.google => _nativeGoogleFlow(linkIdentity: linkIdentity),
      AuthProviderId.apple => _nativeAppleFlow(linkIdentity: linkIdentity),
    };
  }

  Future<void> _nativeGoogleFlow({required bool linkIdentity}) async {
    if (_googleWebClientId.isEmpty ||
        ((defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS) &&
            _googleAppleClientId.isEmpty)) {
      throw const AppFailure(
        AppFailureCode.configuration,
        'Configura GOOGLE_WEB_CLIENT_ID y GOOGLE_APPLE_CLIENT_ID para usar Google.',
      );
    }

    final signIn = GoogleSignIn.instance;
    _googleInitialization ??= signIn.initialize(
      clientId:
          defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS
          ? _googleAppleClientId
          : null,
      serverClientId: _googleWebClientId,
    );
    await _googleInitialization;
    if (!signIn.supportsAuthenticate()) {
      throw const AppFailure(
        AppFailureCode.unavailable,
        'Google nativo no está disponible en esta plataforma.',
      );
    }

    final account = await signIn.authenticate();
    final authentication = account.authentication;
    final authorization = await account.authorizationClient
        .authorizationForScopes(const []);
    final idToken = authentication.idToken;
    if (idToken == null || authorization == null) {
      throw const AppFailure(
        AppFailureCode.unauthorized,
        'Google no entregó credenciales válidas. Revisa la configuración OAuth.',
      );
    }

    try {
      if (linkIdentity) {
        await _client.auth.linkIdentityWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: authorization.accessToken,
        );
      } else {
        await _client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: authorization.accessToken,
        );
      }
    } finally {
      // Provider credentials are deliberately not retained after the exchange.
      try {
        await signIn.signOut();
      } on Object catch (error, stackTrace) {
        developer.log(
          'Unable to clear the native Google session after token exchange',
          name: 'auth.google',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _nativeAppleFlow({required bool linkIdentity}) async {
    final rawNonce = _client.auth.generateRawNonce();
    final nonceDigest = await Sha256().hash(utf8.encode(rawNonce));
    final hashedNonce = nonceDigest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AppFailure(
        AppFailureCode.unauthorized,
        'Apple no entregó una credencial de identidad válida.',
      );
    }

    if (linkIdentity) {
      await _client.auth.linkIdentityWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } else {
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    }
  }

  static AuthSessionSnapshot _snapshotFromUser(User? user) {
    if (user == null) {
      return const AuthSessionSnapshot.signedOut();
    }
    final email = user.email ?? '';
    final metadataName = user.userMetadata?['display_name'] as String?;
    final profile = AuthUserProfile(
      id: user.id,
      email: email,
      displayName: metadataName?.trim().isNotEmpty == true
          ? metadataName!.trim()
          : email.split('@').first,
      isEmailVerified: user.emailConfirmedAt != null,
    );
    return profile.isEmailVerified
        ? AuthSessionSnapshot.authenticated(profile)
        : AuthSessionSnapshot.verificationRequired(profile);
  }

  static OAuthProvider _oauthProvider(AuthProviderId provider) {
    return switch (provider) {
      AuthProviderId.google => OAuthProvider.google,
      AuthProviderId.apple => OAuthProvider.apple,
    };
  }

  static Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on AppFailure {
      rethrow;
    } on AuthException catch (error) {
      throw AppFailure(
        AppFailureCode.unauthorized,
        _friendlyAuthMessage(error),
        cause: error,
      );
    } on FunctionException catch (error) {
      throw AppFailure(
        error.status == 403
            ? AppFailureCode.unauthorized
            : AppFailureCode.unavailable,
        _friendlyFunctionMessage(error),
        cause: error,
      );
    } on Object catch (error) {
      throw AppFailure(
        AppFailureCode.network,
        'No se pudo conectar. Revisa tu conexión e inténtalo de nuevo.',
        cause: error,
      );
    }
  }

  static String _friendlyAuthMessage(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (message.contains('already registered')) {
      return 'Ya existe una cuenta con ese correo.';
    }
    if (message.contains('email not confirmed')) {
      return 'Confirma tu correo antes de iniciar sesión.';
    }
    return 'No se pudo completar la autenticación.';
  }

  static String _friendlyFunctionMessage(FunctionException error) {
    final details = error.details;
    final code = details is Map ? details['code'] : null;
    if (code == 'recent_authentication_required') {
      return 'Por seguridad, cierra sesión, vuelve a iniciarla y repite la eliminación.';
    }
    if (code == 'previous_deletion_attempt_failed') {
      return 'El intento anterior no se completó. Espera un momento e inténtalo otra vez.';
    }
    return 'El servidor no pudo completar la operación.';
  }
}
