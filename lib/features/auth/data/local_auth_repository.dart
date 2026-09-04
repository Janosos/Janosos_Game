import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository._(this._preferences, this._accounts, this._session);

  static const _accountsKey = 'v6.local_auth.accounts';
  static const _sessionKey = 'v6.local_auth.session_user_id';
  static const _gameStateKeyPrefix = 'janosos.v6.local_game_state.';
  static const _uuid = Uuid();

  final SharedPreferences _preferences;
  final List<_LocalAccount> _accounts;
  final StreamController<AuthSessionSnapshot> _sessionController =
      StreamController<AuthSessionSnapshot>.broadcast(sync: true);
  AuthSessionSnapshot _session;

  static Future<LocalAuthRepository> create(
    SharedPreferences preferences,
  ) async {
    final accounts = _decodeAccounts(preferences.getString(_accountsKey));
    final sessionUserId = preferences.getString(_sessionKey);
    final activeAccount = accounts
        .where((account) => account.id == sessionUserId)
        .firstOrNull;
    final session = activeAccount == null
        ? const AuthSessionSnapshot.signedOut()
        : AuthSessionSnapshot.authenticated(activeAccount.toProfile());
    return LocalAuthRepository._(preferences, accounts, session);
  }

  @override
  AuthSessionSnapshot get currentSession => _session;

  @override
  Stream<AuthSessionSnapshot> get sessionChanges => _sessionController.stream;

  @override
  Future<void> register(RegistrationRequest request) async {
    final email = _normalizeEmail(request.email);
    final displayName = request.displayName.trim();
    _validateEmail(email);
    _validatePassword(request.password);
    if (displayName.length < 2 || displayName.length > 24) {
      throw const AppFailure(
        AppFailureCode.invalidInput,
        'El nombre debe tener entre 2 y 24 caracteres.',
      );
    }
    if (_accounts.any((account) => account.email == email)) {
      throw const AppFailure(
        AppFailureCode.conflict,
        'Ya existe una cuenta con ese correo.',
      );
    }

    final salt = _uuid.v4();
    final account = _LocalAccount(
      id: _uuid.v4(),
      email: email,
      displayName: displayName,
      passwordSalt: salt,
      passwordHash: await _hashPassword(request.password, salt),
      passwordAlgorithm: _argon2AlgorithmName,
    );
    _accounts.add(account);
    await _persistAccounts();
    await _setSession(AuthSessionSnapshot.authenticated(account.toProfile()));
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final normalizedEmail = _normalizeEmail(email);
    final account = _accounts
        .where((candidate) => candidate.email == normalizedEmail)
        .firstOrNull;
    if (account == null || !await _matchesPassword(account, password)) {
      throw const AppFailure(
        AppFailureCode.unauthorized,
        'Correo o contraseña incorrectos.',
      );
    }
    if (account.passwordAlgorithm != _argon2AlgorithmName) {
      final salt = _uuid.v4();
      account
        ..passwordSalt = salt
        ..passwordHash = await _hashPassword(password, salt)
        ..passwordAlgorithm = _argon2AlgorithmName;
      await _persistAccounts();
    }
    await _setSession(AuthSessionSnapshot.authenticated(account.toProfile()));
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    _validateEmail(_normalizeEmail(email));
    // Local mode intentionally returns a neutral success response.
  }

  @override
  Future<void> updatePassword(String password) async {
    _validatePassword(password);
    final account = _requireCurrentAccount();
    final salt = _uuid.v4();
    account
      ..passwordSalt = salt
      ..passwordHash = await _hashPassword(password, salt)
      ..passwordAlgorithm = _argon2AlgorithmName;
    await _persistAccounts();
  }

  @override
  Future<void> signInWithProvider(AuthProviderId provider) async {
    throw const AppFailure(
      AppFailureCode.configuration,
      'Google y Apple requieren APP_BACKEND=supabase y credenciales OAuth.',
    );
  }

  @override
  Future<void> linkProvider(AuthProviderId provider) =>
      signInWithProvider(provider);

  @override
  Future<void> reauthenticate() async {
    _requireCurrentAccount();
  }

  @override
  Future<void> signOut() async {
    await _setSession(const AuthSessionSnapshot.signedOut());
  }

  @override
  Future<void> deleteAccount() async {
    final account = _requireCurrentAccount();
    _accounts.removeWhere((candidate) => candidate.id == account.id);
    await _persistAccounts();
    await _preferences.remove('$_gameStateKeyPrefix${account.id}');
    await _setSession(const AuthSessionSnapshot.signedOut());
  }

  @override
  Future<void> dispose() => _sessionController.close();

  _LocalAccount _requireCurrentAccount() {
    final userId = _session.user?.id;
    final account = _accounts
        .where((candidate) => candidate.id == userId)
        .firstOrNull;
    if (account == null) {
      throw const AppFailure(
        AppFailureCode.unauthorized,
        'Debes iniciar sesión para realizar esta acción.',
      );
    }
    return account;
  }

  Future<void> _setSession(AuthSessionSnapshot session) async {
    _session = session;
    final userId = session.user?.id;
    if (userId == null) {
      await _preferences.remove(_sessionKey);
    } else {
      await _preferences.setString(_sessionKey, userId);
    }
    _sessionController.add(session);
  }

  Future<void> _persistAccounts() {
    return _preferences.setString(
      _accountsKey,
      jsonEncode({
        'version': 1,
        'accounts': _accounts.map((account) => account.toJson()).toList(),
      }),
    );
  }

  static List<_LocalAccount> _decodeAccounts(String? source) {
    if (source == null || source.isEmpty) {
      return <_LocalAccount>[];
    }
    try {
      final document = jsonDecode(source) as Map<String, dynamic>;
      final accounts = document['accounts'] as List<dynamic>? ?? const [];
      return accounts
          .map((value) => _LocalAccount.fromJson(value as Map<String, dynamic>))
          .toList();
    } on Object catch (error) {
      throw AppFailure(
        AppFailureCode.configuration,
        'Los datos de la cuenta local están dañados. No se sobrescribieron.',
        cause: error,
      );
    }
  }

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  static void _validateEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 ||
        parts.first.isEmpty ||
        !parts.last.contains('.') ||
        email.length > 254) {
      throw const AppFailure(
        AppFailureCode.invalidInput,
        'Ingresa un correo válido.',
      );
    }
  }

  static void _validatePassword(String password) {
    if (password.length < 8 || password.length > 128) {
      throw const AppFailure(
        AppFailureCode.invalidInput,
        'La contraseña debe tener entre 8 y 128 caracteres.',
      );
    }
  }

  static const _argon2AlgorithmName = 'argon2id-v1';

  static Future<String> _hashPassword(String password, String salt) async {
    final algorithm = Argon2id(
      memory: 19 * 1024,
      parallelism: 1,
      iterations: 2,
      hashLength: 32,
    );
    final key = await algorithm.deriveKeyFromPassword(
      password: password,
      nonce: utf8.encode(salt),
    );
    return base64UrlEncode(await key.extractBytes());
  }

  static Future<bool> _matchesPassword(
    _LocalAccount account,
    String password,
  ) async {
    if (account.passwordAlgorithm == _argon2AlgorithmName) {
      return account.passwordHash ==
          await _hashPassword(password, account.passwordSalt);
    }
    if (account.passwordAlgorithm == 'sha256-v1') {
      final digest = await Sha256().hash(
        utf8.encode('${account.passwordSalt}:$password'),
      );
      return account.passwordHash == base64UrlEncode(digest.bytes);
    }
    return false;
  }
}

class _LocalAccount {
  _LocalAccount({
    required this.id,
    required this.email,
    required this.displayName,
    required this.passwordSalt,
    required this.passwordHash,
    required this.passwordAlgorithm,
  });

  factory _LocalAccount.fromJson(Map<String, dynamic> json) {
    return _LocalAccount(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      passwordSalt: json['password_salt'] as String,
      passwordHash: json['password_hash'] as String,
      passwordAlgorithm: json['password_algorithm'] as String? ?? 'sha256-v1',
    );
  }

  final String id;
  final String email;
  final String displayName;
  String passwordSalt;
  String passwordHash;
  String passwordAlgorithm;

  AuthUserProfile toProfile() {
    return AuthUserProfile(
      id: id,
      email: email,
      displayName: displayName,
      isEmailVerified: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'password_salt': passwordSalt,
      'password_hash': passwordHash,
      'password_algorithm': passwordAlgorithm,
    };
  }
}
