import 'dart:typed_data';

import 'package:dino_run_flame/core/persistence/app_database.dart';
import 'package:dino_run_flame/core/persistence/legacy_score_migrator.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test(
    'legacy score remains private, unattributed, and never uploaded',
    () async {
      SharedPreferences.setMockInitialValues({'high_score': 42});
      final preferences = await SharedPreferences.getInstance();

      await LegacyScoreMigrator(
        database: database,
        preferences: preferences,
      ).run();

      final legacy = await database.legacyScore();
      expect(legacy?.score, 42);
      expect(legacy?.label, 'Récord local heredado');
      expect(legacy?.isUploaded, isFalse);
      expect(preferences.getInt('high_score'), 42);
    },
  );

  test(
    'reactivating a namespace preserves its original creation time',
    () async {
      await database.activateNamespace(
        userId: 'user-a',
        protectedStorageAvailable: false,
      );
      final original = await database
          .select(database.userNamespaces)
          .getSingle();

      await database.activateNamespace(
        userId: 'user-a',
        protectedStorageAvailable: true,
      );
      final reactivated = await database
          .select(database.userNamespaces)
          .getSingle();

      expect(reactivated.createdAt, original.createdAt);
      expect(reactivated.protectedStorageAvailable, isTrue);
      expect(
        reactivated.lastActivatedAt.isBefore(original.lastActivatedAt),
        isFalse,
      );
    },
  );

  test('wiping one account leaves another namespace untouched', () async {
    for (final userId in ['user-a', 'user-b']) {
      await database.activateNamespace(
        userId: userId,
        protectedStorageAvailable: true,
      );
      await database.cacheProfile(
        userId: userId,
        email: '$userId@example.com',
        displayName: userId,
        emailVerified: true,
      );
    }

    await database.wipeUserNamespace('user-a');

    final namespaces = await database.select(database.userNamespaces).get();
    final profiles = await database.select(database.cachedProfiles).get();
    expect(namespaces.map((row) => row.userId), ['user-b']);
    expect(profiles.map((row) => row.userId), ['user-b']);
  });

  test('outbox idempotency key is unique per user and command', () async {
    Future<void> insert(String id) {
      return database.addEncryptedOutboxFixture(
        id: id,
        userId: 'user-a',
        commandType: 'finish-stage',
        idempotencyKey: 'same-command',
        encryptedPayload: Uint8List.fromList([1, 2, 3]),
        nonce: Uint8List.fromList([4, 5]),
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
      );
    }

    await insert('outbox-1');
    await expectLater(insert('outbox-2'), throwsA(isA<Exception>()));
    expect(await database.outboxByteSize('user-a'), 5);
  });
}
