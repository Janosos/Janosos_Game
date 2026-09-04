import 'dart:convert';
import 'dart:math';

import 'package:dino_run_flame/core/errors/app_failure.dart';
import 'package:dino_run_flame/core/persistence/app_database.dart';
import 'package:dino_run_flame/core/sync/encrypted_outbox.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/memory_protected_store.dart';

void main() {
  late AppDatabase database;
  late FakeAuthRepository authRepository;
  late MemoryProtectedStore protectedStore;
  late EncryptedOutbox outbox;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    authRepository = FakeAuthRepository.signedIn(userId: 'user-a');
    protectedStore = MemoryProtectedStore();
    outbox = EncryptedOutbox(
      database: database,
      protectedStore: protectedStore,
      authRepository: authRepository,
      jitterRandom: Random(7),
    );
  });

  tearDown(() async {
    await database.close();
    await authRepository.dispose();
  });

  test(
    'encrypts payload with account and command authenticated as AAD',
    () async {
      final id = await outbox.enqueue(
        commandType: 'finish-stage',
        idempotencyKey: 'idem-1',
        projectionId: 'projection-1',
        payload: {'stage_token': 'secret-token', 'score': 42},
        now: DateTime.utc(2026, 8, 31),
      );

      final stored = await database.outboxItem(id);
      expect(stored, isNotNull);
      expect(
        utf8.decode(stored!.encryptedPayload, allowMalformed: true),
        isNot(contains('secret-token')),
      );
      expect(protectedStore.values.keys.single, contains('user.user-a'));

      final commands = await outbox.due(now: DateTime.utc(2026, 8, 31));
      expect(commands, hasLength(1));
      expect(commands.single.payload['stage_token'], 'secret-token');
      expect(commands.single.projectionId, 'projection-1');
    },
  );

  test('tampering with ciphertext fails authenticated decryption', () async {
    final id = await outbox.enqueue(
      commandType: 'finish-stage',
      idempotencyKey: 'idem-2',
      payload: {'score': 42},
      now: DateTime.utc(2026, 8, 31),
    );
    final row = (await database.outboxItem(id))!;
    final tampered = Uint8List.fromList(row.encryptedPayload);
    tampered[0] ^= 1;
    await (database.update(database.outboxItems)
          ..where((item) => item.id.equals(id)))
        .write(OutboxItemsCompanion(encryptedPayload: Value(tampered)));

    await expectLater(
      outbox.due(now: DateTime.utc(2026, 8, 31)),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          AppFailureCode.unavailable,
        ),
      ),
    );
  });

  test('enforces the 100 item limit atomically', () async {
    for (var index = 0; index < EncryptedOutbox.maxItems; index++) {
      await outbox.enqueue(
        commandType: 'finish-stage',
        idempotencyKey: 'idem-$index',
        payload: {'score': index},
      );
    }

    await expectLater(
      outbox.enqueue(
        commandType: 'finish-stage',
        idempotencyKey: 'idem-overflow',
        payload: const {'score': 101},
      ),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          AppFailureCode.conflict,
        ),
      ),
    );
    expect(await database.outboxCount('user-a'), EncryptedOutbox.maxItems);
  });

  test(
    'pauses automatic retry at 20 attempts and supports explicit retry',
    () async {
      final now = DateTime.utc(2026, 8, 31);
      final id = await outbox.enqueue(
        commandType: 'finish-stage',
        idempotencyKey: 'idem-retry',
        payload: const {'score': 1},
        now: now,
      );

      for (
        var attempt = 0;
        attempt < EncryptedOutbox.maxAutomaticAttempts;
        attempt++
      ) {
        await outbox.recordTransientFailure(
          id: id,
          errorCode: 'network-timeout',
          now: now,
        );
      }
      var row = (await database.outboxItem(id))!;
      expect(row.status, 'paused');
      expect(row.attemptCount, EncryptedOutbox.maxAutomaticAttempts);
      expect(row.lastErrorCode, 'network_timeout');
      expect(
        row.nextAttemptAt.difference(now),
        lessThanOrEqualTo(const Duration(hours: 1)),
      );

      await outbox.retryNow(id, now: now);
      row = (await database.outboxItem(id))!;
      expect(row.status, 'pending');
      expect(row.attemptCount, 0);
      expect(row.lastErrorCode, isNull);
    },
  );

  test('expires old commands instead of silently retrying them', () async {
    final createdAt = DateTime.utc(2026, 7, 1);
    final id = await outbox.enqueue(
      commandType: 'finish-stage',
      idempotencyKey: 'idem-expired',
      payload: const {'score': 1},
      now: createdAt,
    );

    final due = await outbox.due(now: DateTime.utc(2026, 8, 31));
    final row = (await database.outboxItem(id))!;
    expect(due, isEmpty);
    expect(row.status, 'rejected');
    expect(row.lastErrorCode, 'expired');
  });

  test('fails closed when protected storage is unavailable', () async {
    final unavailable = EncryptedOutbox(
      database: database,
      protectedStore: MemoryProtectedStore(available: false),
      authRepository: authRepository,
    );

    await expectLater(
      unavailable.enqueue(
        commandType: 'finish-stage',
        idempotencyKey: 'idem-unavailable',
        payload: const {'score': 1},
      ),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          AppFailureCode.unavailable,
        ),
      ),
    );
    expect(await database.outboxCount('user-a'), 0);
  });

  test('does not replace a missing key for existing ciphertext', () async {
    await outbox.enqueue(
      commandType: 'finish-stage',
      idempotencyKey: 'idem-missing-key',
      payload: const {'score': 1},
      now: DateTime.utc(2026, 8, 31),
    );
    protectedStore.values.clear();

    await expectLater(
      outbox.due(now: DateTime.utc(2026, 8, 31)),
      throwsA(isA<AppFailure>()),
    );
    expect(protectedStore.values, isEmpty);
  });
}
