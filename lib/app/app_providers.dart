import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_environment.dart';
import '../core/persistence/app_database.dart';
import '../core/security/protected_store.dart';
import '../core/session/user_session_coordinator.dart';
import '../core/sync/encrypted_outbox.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/boss_rush/application/boss_rush_coordinator.dart';
import '../features/boss_rush/data/local_boss_rush_repository.dart';
import '../features/boss_rush/data/supabase_boss_rush_repository.dart';
import '../features/boss_rush/domain/boss_rush_repository.dart';
import '../features/campaign/application/run_result_recorder.dart';
import '../features/campaign/application/campaign_stage_coordinator.dart';
import '../features/campaign/application/campaign_result_coordinator.dart';
import '../features/campaign/data/local_campaign_repository.dart';
import '../features/campaign/data/supabase_campaign_repository.dart';
import '../features/campaign/domain/campaign_repository.dart';
import '../features/leaderboard/data/local_leaderboard_repository.dart';
import '../features/leaderboard/data/supabase_leaderboard_repository.dart';
import '../features/leaderboard/domain/leaderboard_repository.dart';
import '../features/progression/data/local_progression_repository.dart';
import '../features/progression/data/local_game_state_store.dart';
import '../features/progression/data/supabase_progression_repository.dart';
import '../features/progression/domain/progression_repository.dart';

final appEnvironmentProvider = Provider<AppEnvironment>((ref) {
  throw UnimplementedError('AppEnvironment must be provided by bootstrap.');
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be provided by bootstrap.');
});

final protectedStoreProvider = Provider<ProtectedStore>((ref) {
  throw UnimplementedError('ProtectedStore must be provided by bootstrap.');
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('AppDatabase must be provided by bootstrap.');
});

final userSessionCoordinatorProvider = Provider<UserSessionCoordinator>((ref) {
  throw UnimplementedError(
    'UserSessionCoordinator must be provided by bootstrap.',
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('AuthRepository must be provided by bootstrap.');
});

final localGameStateStoreProvider = Provider<LocalGameStateStore>((ref) {
  return LocalGameStateStore(
    preferences: ref.watch(sharedPreferencesProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.usesLocalBackend) {
    return LocalLeaderboardRepository(
      database: ref.watch(appDatabaseProvider),
      authRepository: ref.watch(authRepositoryProvider),
    );
  }
  return SupabaseLeaderboardRepository(
    client: Supabase.instance.client,
    database: ref.watch(appDatabaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

final runResultRecorderProvider = Provider<RunResultRecorder>((ref) {
  return RunResultRecorder(
    database: ref.watch(appDatabaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.usesLocalBackend) {
    return LocalCampaignRepository(
      store: ref.watch(localGameStateStoreProvider),
    );
  }
  return SupabaseCampaignRepository(
    client: Supabase.instance.client,
    protectedStore: ref.watch(protectedStoreProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

final campaignStageCoordinatorProvider = Provider<CampaignStageCoordinator>((
  ref,
) {
  return CampaignStageCoordinator(
    campaignRepository: ref.watch(campaignRepositoryProvider),
    progressionRepository: ref.watch(progressionRepositoryProvider),
    environment: ref.watch(appEnvironmentProvider),
  );
});

final campaignResultCoordinatorProvider = Provider<CampaignResultCoordinator>((
  ref,
) {
  return CampaignResultCoordinator(
    repository: ref.watch(campaignRepositoryProvider),
    outbox: ref.watch(encryptedOutboxProvider),
    recorder: ref.watch(runResultRecorderProvider),
  );
});

final bossRushRepositoryProvider = Provider<BossRushRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.usesLocalBackend) {
    return LocalBossRushRepository(
      store: ref.watch(localGameStateStoreProvider),
    );
  }
  return SupabaseBossRushRepository(client: Supabase.instance.client);
});

final bossRushCoordinatorProvider = Provider<BossRushCoordinator>((ref) {
  return BossRushCoordinator(
    repository: ref.watch(bossRushRepositoryProvider),
    progressionRepository: ref.watch(progressionRepositoryProvider),
    environment: ref.watch(appEnvironmentProvider),
    outbox: ref.watch(encryptedOutboxProvider),
    recorder: ref.watch(runResultRecorderProvider),
  );
});

final progressionRepositoryProvider = Provider<ProgressionRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.usesLocalBackend) {
    return LocalProgressionRepository(
      store: ref.watch(localGameStateStoreProvider),
    );
  }
  return SupabaseProgressionRepository(client: Supabase.instance.client);
});

final encryptedOutboxProvider = Provider<EncryptedOutbox>((ref) {
  return EncryptedOutbox(
    database: ref.watch(appDatabaseProvider),
    protectedStore: ref.watch(protectedStoreProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});
