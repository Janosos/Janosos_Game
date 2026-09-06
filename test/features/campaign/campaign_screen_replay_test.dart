import 'package:dino_run_flame/app/app_providers.dart';
import 'package:dino_run_flame/core/config/app_environment.dart';
import 'package:dino_run_flame/features/campaign/domain/campaign_repository.dart';
import 'package:dino_run_flame/features/campaign/presentation/campaign_screen.dart';
import 'package:dino_run_flame/features/progression/domain/progression_models.dart';
import 'package:dino_run_flame/features/progression/domain/progression_repository.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:dino_run_flame/game/domain/run_configuration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  testWidgets(
    'displays VOLVER A JUGAR on completed levels and JUGAR on the current unlocked level',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        'campaign_max_unlocked_level': 2,
        'campaign_max_unlocked_level_jano': 2,
      });
      final preferences = await SharedPreferences.getInstance();

      final authRepository = FakeAuthRepository.signedIn(
        userId: 'user-campaign',
        displayName: 'Campaign Player',
      );
      addTearDown(authRepository.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appEnvironmentProvider.overrideWithValue(
              AppEnvironment(
                backendMode: BackendMode.local,
                supabaseUrl: '',
                supabasePublishableKey: '',
                authRedirectUri: Uri(
                  scheme: 'io.janosos.game',
                  host: 'auth',
                  path: '/callback',
                ),
                contentVersion: 'v1',
              ),
            ),
            sharedPreferencesProvider.overrideWithValue(preferences),
            authRepositoryProvider.overrideWithValue(authRepository),
            campaignRepositoryProvider.overrideWithValue(
              _FakeEmptyCampaignRepository(),
            ),
            progressionRepositoryProvider.overrideWithValue(
              _FakeProgressionRepository(),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: CampaignScreen())),
        ),
      );

      await tester.pumpAndSettle();

      // Check level 1 has VOLVER A JUGAR button and COMPLETADO badge
      expect(find.text('VOLVER A JUGAR'), findsOneWidget);
      expect(find.text('LVL 1 · COMPLETADO'), findsOneWidget);

      // Check level 2 has JUGAR NIVEL 2 button
      expect(find.text('JUGAR NIVEL 2'), findsOneWidget);

      // Check remaining levels are BLOQUEADO
      expect(find.text('BLOQUEADO'), findsWidgets);
    },
  );
}

class _FakeEmptyCampaignRepository implements CampaignRepository {
  @override
  Future<void> abandonCampaign(CampaignStageSession session) async {}

  @override
  Future<void> clearPreparedStage() async {}

  @override
  Future<CampaignCompletionReceipt> completeCampaign(
    Map<String, Object?> payload,
  ) async => const CampaignCompletionReceipt(
    accepted: true,
    ranked: false,
    bankedCurrency: 0,
    purchasePhaseUnlocked: true,
  );

  @override
  Future<void> failCampaign(Map<String, Object?> payload) async {}

  @override
  Future<CampaignFinishReceipt> finishStage(
    Map<String, Object?> payload,
  ) async => const CampaignFinishReceipt(
    accepted: true,
    ranked: false,
    masteryXpGranted: 0,
    temporaryCurrency: 0,
    currencyLost: 0,
    uniqueDropGranted: false,
    nextLevel: 1,
    readyToComplete: false,
  );

  @override
  Future<CampaignProgress?> loadActiveCampaign() async => null;

  @override
  Future<CampaignStageSession?> loadPreparedStage(
    CharacterId characterId,
  ) async => null;

  @override
  Future<void> markStagePlaying(CampaignStageSession session) async {}

  @override
  Future<CampaignStageSession> startStage({
    required RunConfiguration configuration,
    required int bankedCurrency,
    required int temporaryCurrency,
  }) async => CampaignStageSession(
    eligibility: CampaignEligibility.local,
    configuration: configuration,
    bankedCurrency: 0,
    temporaryCurrency: 0,
  );
}

class _FakeProgressionRepository implements ProgressionRepository {
  @override
  Future<ProgressionSnapshot> loadSnapshot({
    required CharacterId characterId,
    required String contentVersion,
  }) async => ProgressionSnapshot(
    characterId: characterId,
    contentVersion: contentVersion,
    contentDigest: 'digest',
    masteryXp: 0,
    masteryLevel: 1,
    nextLevelXp: 100,
    bankedCurrency: 0,
    temporaryCurrency: 0,
    storeUnlocked: false,
    authorizedBuild: AuthorizedBuild(
      speedBasisPoints: 0,
      jumpBasisPoints: 0,
      damageBasisPoints: 0,
      vitalityBasisPoints: 0,
      fortuneBasisPoints: 0,
      maxLives: 3,
      activeSkillId: null,
      defaultActiveId: 'glide',
      passiveSkillIds: const [],
      skinId: 'jano_default',
    ),
    stats: const [],
    skills: const [],
    palettes: const [],
  );

  @override
  Future<void> purchasePalette({
    required ProgressionSnapshot snapshot,
    required PaletteVariant palette,
  }) async {}

  @override
  Future<void> purchaseSkill({
    required ProgressionSnapshot snapshot,
    required ProgressionSkill skill,
  }) async {}

  @override
  Future<void> purchaseUpgrade({
    required ProgressionSnapshot snapshot,
    required ProgressionStat stat,
  }) async {}

  @override
  Future<void> equipLoadout({
    required ProgressionSnapshot snapshot,
    required LoadoutSelection selection,
  }) async {}
}
