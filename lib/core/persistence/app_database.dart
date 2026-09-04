import 'package:drift/drift.dart';

import 'database_connection.dart';

part 'app_database.g.dart';

class UserNamespaces extends Table {
  TextColumn get userId => text()();
  TextColumn get protectedScope => text()();
  BoolColumn get protectedStorageAvailable => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastActivatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

class CachedProfiles extends Table {
  TextColumn get userId => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text()();
  BoolColumn get emailVerified => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

class OutboxItems extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get commandType => text()();
  TextColumn get idempotencyKey => text()();
  TextColumn get projectionId => text().nullable()();
  BlobColumn get encryptedPayload => blob()();
  BlobColumn get nonce => blob()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  IntColumn get byteSize => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get nextAttemptAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  TextColumn get lastErrorCode => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {userId, commandType, idempotencyKey},
  ];
}

class ResultProjections extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get characterId => text()();
  TextColumn get mode => text()();
  TextColumn get outcome => text()();
  TextColumn get validationStatus => text()();
  TextColumn get contentVersion =>
      text().withDefault(const Constant('unknown'))();
  IntColumn get score => integer()();
  IntColumn get durationMs => integer()();
  IntColumn get levelReached => integer()();
  DateTimeColumn get endedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LegacyScoreStates extends Table {
  TextColumn get source => text()();
  IntColumn get score => integer()();
  TextColumn get label =>
      text().withDefault(const Constant('Récord local heredado'))();
  BoolColumn get isUploaded => boolean().withDefault(const Constant(false))();
  DateTimeColumn get discoveredAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {source};
}

@DriftDatabase(
  tables: [
    UserNamespaces,
    CachedProfiles,
    OutboxItems,
    ResultProjections,
    LegacyScoreStates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openAppDatabaseConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(
          resultProjections,
          resultProjections.contentVersion,
        );
      }
      if (from < 3) {
        await migrator.addColumn(outboxItems, outboxItems.projectionId);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> activateNamespace({
    required String userId,
    required bool protectedStorageAvailable,
  }) async {
    final now = DateTime.now().toUtc();
    await into(userNamespaces).insert(
      UserNamespacesCompanion.insert(
        userId: userId,
        protectedScope: 'user.$userId',
        protectedStorageAvailable: protectedStorageAvailable,
        createdAt: now,
        lastActivatedAt: now,
      ),
      onConflict: DoUpdate(
        (_) => UserNamespacesCompanion(
          protectedStorageAvailable: Value(protectedStorageAvailable),
          lastActivatedAt: Value(now),
        ),
        target: [userNamespaces.userId],
      ),
    );
  }

  Future<void> cacheProfile({
    required String userId,
    required String email,
    required String displayName,
    required bool emailVerified,
  }) {
    return into(cachedProfiles).insertOnConflictUpdate(
      CachedProfilesCompanion.insert(
        userId: userId,
        email: email,
        displayName: displayName,
        emailVerified: emailVerified,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> preserveLegacyScore(int score) {
    return into(legacyScoreStates).insertOnConflictUpdate(
      LegacyScoreStatesCompanion.insert(
        source: 'shared_preferences.high_score',
        score: score,
        discoveredAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<LegacyScoreState?> legacyScore() {
    return (select(legacyScoreStates)
          ..where((row) => row.source.equals('shared_preferences.high_score')))
        .getSingleOrNull();
  }

  Future<void> wipeUserNamespace(String userId) async {
    await transaction(() async {
      await (delete(
        outboxItems,
      )..where((row) => row.userId.equals(userId))).go();
      await (delete(
        resultProjections,
      )..where((row) => row.userId.equals(userId))).go();
      await (delete(
        cachedProfiles,
      )..where((row) => row.userId.equals(userId))).go();
      await (delete(
        userNamespaces,
      )..where((row) => row.userId.equals(userId))).go();
    });
  }

  Future<int> outboxByteSize(String userId) async {
    final total = outboxItems.byteSize.sum();
    final query = selectOnly(outboxItems)
      ..addColumns([total])
      ..where(outboxItems.userId.equals(userId));
    return (await query.map((row) => row.read(total) ?? 0).getSingle());
  }

  Future<int> outboxCount(String userId) async {
    final count = outboxItems.id.count();
    final query = selectOnly(outboxItems)
      ..addColumns([count])
      ..where(outboxItems.userId.equals(userId));
    return (await query.map((row) => row.read(count) ?? 0).getSingle());
  }

  Future<void> insertBoundedOutbox({
    required String id,
    required String userId,
    required String commandType,
    required String idempotencyKey,
    required String? projectionId,
    required Uint8List encryptedPayload,
    required Uint8List nonce,
    required DateTime createdAt,
    required DateTime expiresAt,
    required int maxItems,
    required int maxBytes,
  }) {
    return transaction(() async {
      final itemSize = encryptedPayload.length + nonce.length;
      final existingCount = await outboxCount(userId);
      final existingBytes = await outboxByteSize(userId);
      if (existingCount >= maxItems || existingBytes + itemSize > maxBytes) {
        throw const OutboxCapacityException();
      }
      await into(outboxItems).insert(
        OutboxItemsCompanion.insert(
          id: id,
          userId: userId,
          commandType: commandType,
          idempotencyKey: idempotencyKey,
          projectionId: Value(projectionId),
          encryptedPayload: encryptedPayload,
          nonce: nonce,
          byteSize: itemSize,
          createdAt: createdAt.toUtc(),
          nextAttemptAt: createdAt.toUtc(),
          expiresAt: expiresAt.toUtc(),
        ),
      );
    });
  }

  Future<OutboxItem?> outboxItem(String id) {
    return (select(
      outboxItems,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  Future<List<OutboxItem>> dueOutboxItems({
    required String userId,
    required DateTime now,
    int limit = 20,
  }) {
    final query = select(outboxItems)
      ..where(
        (row) =>
            row.userId.equals(userId) &
            row.status.isIn(const ['pending', 'retrying']) &
            row.nextAttemptAt.isSmallerOrEqualValue(now.toUtc()) &
            row.expiresAt.isBiggerThanValue(now.toUtc()) &
            row.attemptCount.isSmallerThanValue(20),
      )
      ..orderBy([
        (row) => OrderingTerm.asc(row.nextAttemptAt),
        (row) => OrderingTerm.asc(row.createdAt),
        (row) => OrderingTerm.asc(row.id),
      ])
      ..limit(limit.clamp(1, 100));
    return query.get();
  }

  Future<void> updateOutboxAttempt({
    required String id,
    required String status,
    required int attemptCount,
    required DateTime nextAttemptAt,
    required String? errorCode,
  }) {
    return (update(outboxItems)..where((row) => row.id.equals(id))).write(
      OutboxItemsCompanion(
        status: Value(status),
        attemptCount: Value(attemptCount),
        nextAttemptAt: Value(nextAttemptAt.toUtc()),
        lastErrorCode: Value(errorCode),
      ),
    );
  }

  Future<void> markExpiredOutbox({
    required String userId,
    required DateTime now,
  }) {
    return (update(outboxItems)..where(
          (row) =>
              row.userId.equals(userId) &
              row.expiresAt.isSmallerOrEqualValue(now.toUtc()) &
              row.status.isNotIn(const ['accepted', 'rejected']),
        ))
        .write(
          OutboxItemsCompanion(
            status: const Value('rejected'),
            lastErrorCode: const Value('expired'),
            nextAttemptAt: Value(now.toUtc()),
          ),
        );
  }

  Future<void> deleteOutboxItem(String id) {
    return (delete(outboxItems)..where((row) => row.id.equals(id))).go();
  }

  Future<List<ResultProjection>> personalResultHistory({
    required String userId,
    required String characterId,
    required String mode,
    int limit = 100,
  }) {
    final query = select(resultProjections)
      ..where(
        (row) =>
            row.userId.equals(userId) &
            row.characterId.equals(characterId) &
            row.mode.equals(mode),
      )
      ..orderBy([
        (row) => OrderingTerm.desc(row.endedAt),
        (row) => OrderingTerm.desc(row.id),
      ])
      ..limit(limit.clamp(1, 100));
    return query.get();
  }

  Future<void> saveResultProjection({
    required String id,
    required String userId,
    required String characterId,
    required String mode,
    required String outcome,
    required String validationStatus,
    required String contentVersion,
    required int score,
    required int durationMs,
    required int levelReached,
    required DateTime endedAt,
    required bool isSynced,
  }) {
    return into(resultProjections).insertOnConflictUpdate(
      ResultProjectionsCompanion.insert(
        id: id,
        userId: userId,
        characterId: characterId,
        mode: mode,
        outcome: outcome,
        validationStatus: validationStatus,
        contentVersion: Value(contentVersion),
        score: score,
        durationMs: durationMs,
        levelReached: levelReached,
        endedAt: endedAt.toUtc(),
        isSynced: Value(isSynced),
      ),
    );
  }

  Future<void> addEncryptedOutboxFixture({
    required String id,
    required String userId,
    required String commandType,
    required String idempotencyKey,
    required Uint8List encryptedPayload,
    required Uint8List nonce,
    required DateTime expiresAt,
  }) {
    final now = DateTime.now().toUtc();
    return into(outboxItems).insert(
      OutboxItemsCompanion.insert(
        id: id,
        userId: userId,
        commandType: commandType,
        idempotencyKey: idempotencyKey,
        encryptedPayload: encryptedPayload,
        nonce: nonce,
        byteSize: encryptedPayload.length + nonce.length,
        createdAt: now,
        nextAttemptAt: now,
        expiresAt: expiresAt,
      ),
    );
  }
}

class OutboxCapacityException implements Exception {
  const OutboxCapacityException();
}
