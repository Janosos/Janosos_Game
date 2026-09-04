import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:uuid/uuid.dart';

import '../../features/auth/domain/auth_repository.dart';
import '../errors/app_failure.dart';
import '../persistence/app_database.dart';
import '../security/protected_store.dart';

class DecryptedOutboxCommand {
  const DecryptedOutboxCommand({
    required this.id,
    required this.commandType,
    required this.idempotencyKey,
    required this.payload,
    required this.attemptCount,
    required this.expiresAt,
    this.projectionId,
  });

  final String id;
  final String commandType;
  final String idempotencyKey;
  final Map<String, Object?> payload;
  final int attemptCount;
  final DateTime expiresAt;
  final String? projectionId;
}

class EncryptedOutbox {
  EncryptedOutbox({
    required AppDatabase database,
    required ProtectedStore protectedStore,
    required AuthRepository authRepository,
    AesGcm? cipher,
    Random? jitterRandom,
  }) : _database = database,
       _protectedStore = protectedStore,
       _authRepository = authRepository,
       _cipher = cipher ?? AesGcm.with256bits(),
       _jitterRandom = jitterRandom ?? Random.secure();

  static const maxItems = 100;
  static const maxBytes = 10 * 1024 * 1024;
  static const retention = Duration(days: 30);
  static const maxAutomaticAttempts = 20;
  static const maxRetryDelay = Duration(hours: 1);
  static const _uuid = Uuid();

  final AppDatabase _database;
  final ProtectedStore _protectedStore;
  final AuthRepository _authRepository;
  final AesGcm _cipher;
  final Random _jitterRandom;

  Future<String> enqueue({
    required String commandType,
    required String idempotencyKey,
    required Map<String, Object?> payload,
    String? projectionId,
    DateTime? now,
  }) async {
    final userId = _requireUser();
    _requireProtectedStore();
    if (!_safeIdentifier.hasMatch(commandType)) {
      throw const AppFailure(
        AppFailureCode.invalidInput,
        'El tipo de comando del outbox no es válido.',
      );
    }
    final createdAt = (now ?? DateTime.now()).toUtc();
    final key = await _loadKey(userId, createIfMissing: true);
    final clearText = utf8.encode(
      jsonEncode({'schema_version': 1, 'payload': payload}),
    );
    final aad = _aad(userId, commandType, idempotencyKey);
    final box = await _cipher.encrypt(clearText, secretKey: key, aad: aad);
    final encryptedPayload = Uint8List.fromList([
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
    final id = _uuid.v4();
    try {
      await _database.insertBoundedOutbox(
        id: id,
        userId: userId,
        commandType: commandType,
        idempotencyKey: idempotencyKey,
        projectionId: projectionId,
        encryptedPayload: encryptedPayload,
        nonce: Uint8List.fromList(box.nonce),
        createdAt: createdAt,
        expiresAt: createdAt.add(retention),
        maxItems: maxItems,
        maxBytes: maxBytes,
      );
    } on OutboxCapacityException {
      throw const AppFailure(
        AppFailureCode.conflict,
        'La cola segura alcanzó su límite. Sincroniza o descarta resultados antes de continuar.',
      );
    }
    return id;
  }

  Future<List<DecryptedOutboxCommand>> due({
    DateTime? now,
    int limit = 20,
  }) async {
    final userId = _requireUser();
    _requireProtectedStore();
    final currentTime = (now ?? DateTime.now()).toUtc();
    await _database.markExpiredOutbox(userId: userId, now: currentTime);
    final rows = await _database.dueOutboxItems(
      userId: userId,
      now: currentTime,
      limit: limit,
    );
    if (rows.isEmpty) {
      return const [];
    }
    final key = await _loadKey(userId, createIfMissing: false);
    return Future.wait([for (final row in rows) _decrypt(row, key, userId)]);
  }

  Future<void> recordTransientFailure({
    required String id,
    required String errorCode,
    DateTime? now,
  }) async {
    final row = await _database.outboxItem(id);
    if (row == null || row.userId != _requireUser()) {
      return;
    }
    final attempt = row.attemptCount + 1;
    final currentTime = (now ?? DateTime.now()).toUtc();
    final cappedSeconds = min(
      maxRetryDelay.inSeconds,
      2 * pow(2, max(0, attempt - 1)).toInt(),
    );
    final jitterSeconds = cappedSeconds <= 1
        ? cappedSeconds
        : _jitterRandom.nextInt(cappedSeconds + 1);
    await _database.updateOutboxAttempt(
      id: id,
      status: attempt >= maxAutomaticAttempts ? 'paused' : 'retrying',
      attemptCount: attempt,
      nextAttemptAt: currentTime.add(Duration(seconds: jitterSeconds)),
      errorCode: _normalizeErrorCode(errorCode),
    );
  }

  Future<void> rejectPermanently({
    required String id,
    required String errorCode,
    DateTime? now,
  }) async {
    final row = await _database.outboxItem(id);
    if (row == null || row.userId != _requireUser()) {
      return;
    }
    await _database.updateOutboxAttempt(
      id: id,
      status: 'rejected',
      attemptCount: row.attemptCount,
      nextAttemptAt: (now ?? DateTime.now()).toUtc(),
      errorCode: _normalizeErrorCode(errorCode),
    );
  }

  Future<void> retryNow(String id, {DateTime? now}) async {
    final row = await _database.outboxItem(id);
    if (row == null || row.userId != _requireUser()) {
      return;
    }
    await _database.updateOutboxAttempt(
      id: id,
      status: 'pending',
      attemptCount: 0,
      nextAttemptAt: (now ?? DateTime.now()).toUtc(),
      errorCode: null,
    );
  }

  Future<void> acknowledgeAccepted(String id) async {
    final row = await _database.outboxItem(id);
    if (row != null && row.userId == _requireUser()) {
      await _database.deleteOutboxItem(id);
    }
  }

  Future<void> acknowledgeRejected(String id) => acknowledgeAccepted(id);

  Future<DecryptedOutboxCommand> _decrypt(
    OutboxItem row,
    SecretKey key,
    String userId,
  ) async {
    final macLength = _cipher.macAlgorithm.macLength;
    if (row.encryptedPayload.length <= macLength) {
      throw const AppFailure(
        AppFailureCode.unavailable,
        'Un resultado pendiente está dañado y no puede sincronizarse.',
      );
    }
    final cipherText = row.encryptedPayload.sublist(
      0,
      row.encryptedPayload.length - macLength,
    );
    final mac = row.encryptedPayload.sublist(
      row.encryptedPayload.length - macLength,
    );
    try {
      final clearText = await _cipher.decrypt(
        SecretBox(cipherText, nonce: row.nonce, mac: Mac(mac)),
        secretKey: key,
        aad: _aad(userId, row.commandType, row.idempotencyKey),
      );
      final decoded = jsonDecode(utf8.decode(clearText));
      if (decoded is! Map<String, Object?> || decoded['schema_version'] != 1) {
        throw const FormatException('Unsupported outbox envelope.');
      }
      final payload = decoded['payload'];
      if (payload is! Map<String, Object?>) {
        throw const FormatException('Invalid outbox payload.');
      }
      return DecryptedOutboxCommand(
        id: row.id,
        commandType: row.commandType,
        idempotencyKey: row.idempotencyKey,
        payload: payload,
        attemptCount: row.attemptCount,
        expiresAt: row.expiresAt,
        projectionId: row.projectionId,
      );
    } on SecretBoxAuthenticationError catch (error) {
      throw AppFailure(
        AppFailureCode.unavailable,
        'La integridad de un resultado pendiente no pudo verificarse.',
        cause: error,
      );
    } on FormatException catch (error) {
      throw AppFailure(
        AppFailureCode.unavailable,
        'Un resultado pendiente usa un formato no compatible.',
        cause: error,
      );
    }
  }

  Future<SecretKey> _loadKey(
    String userId, {
    required bool createIfMissing,
  }) async {
    final keyName = 'user.$userId.outbox.key.v1';
    final encoded = await _protectedStore.read(keyName);
    if (encoded != null) {
      late final List<int> bytes;
      try {
        bytes = base64Url.decode(encoded);
      } on FormatException catch (error) {
        throw AppFailure(
          AppFailureCode.unavailable,
          'La clave segura del outbox no es válida.',
          cause: error,
        );
      }
      if (bytes.length != 32) {
        throw const AppFailure(
          AppFailureCode.unavailable,
          'La clave segura del outbox no es válida.',
        );
      }
      return SecretKey(bytes);
    }
    if (!createIfMissing) {
      throw const AppFailure(
        AppFailureCode.unavailable,
        'No se encontró la clave segura de los resultados pendientes.',
      );
    }
    final key = await _cipher.newSecretKey();
    final bytes = await key.extractBytes();
    await _protectedStore.write(keyName, base64UrlEncode(bytes));
    return key;
  }

  String _requireUser() {
    final userId = _authRepository.currentSession.user?.id;
    if (userId == null) {
      throw const AppFailure(
        AppFailureCode.unauthorized,
        'Inicia sesión para sincronizar resultados.',
      );
    }
    return userId;
  }

  void _requireProtectedStore() {
    if (!_protectedStore.availability.isAvailable) {
      throw AppFailure(
        AppFailureCode.unavailable,
        _protectedStore.availability.reason ??
            'El almacén protegido no está disponible. La partida será sólo de práctica.',
      );
    }
  }

  static List<int> _aad(
    String userId,
    String commandType,
    String idempotencyKey,
  ) => utf8.encode('janosos-v6|$userId|$commandType|$idempotencyKey');

  static String _normalizeErrorCode(String value) {
    final normalized = value.toLowerCase().replaceAll(
      RegExp('[^a-z0-9_]'),
      '_',
    );
    if (normalized.isEmpty) {
      return 'unknown_error';
    }
    return normalized.substring(0, min(48, normalized.length));
  }

  static final _safeIdentifier = RegExp(r'^[a-z][a-z0-9_-]{1,47}$');
}
