import 'dart:math';

import 'package:dino_run_flame/core/errors/app_failure.dart';
import 'package:dino_run_flame/features/boss_rush/data/local_boss_rush_repository.dart';
import 'package:dino_run_flame/features/campaign/data/local_campaign_repository.dart';
import 'package:dino_run_flame/features/campaign/domain/campaign_repository.dart';
import 'package:dino_run_flame/features/progression/data/local_game_state_store.dart';
import 'package:dino_run_flame/features/progression/data/local_progression_repository.dart';
import 'package:dino_run_flame/features/progression/domain/progression_models.dart';
import 'package:dino_run_flame/game/domain/character_definition.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:dino_run_flame/game/domain/run_configuration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  late SharedPreferences preferences;
  late FakeAuthRepository auth;
  late LocalGameStateStore store;
  late LocalCampaignRepository campaign;
  late LocalProgressionRepository progression;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    auth = FakeAuthRepository.signedIn(userId: 'local-a');
    store = LocalGameStateStore(preferences: preferences, authRepository: auth);
    campaign = LocalCampaignRepository(store: store, random: Random(9));
    progression = LocalProgressionRepository(store: store);
  });

  tearDown(() => auth.dispose());

  test(
    'Boss Rush stays locked until that character clears level ten',
    () async {
      final bossRush = LocalBossRushRepository(store: store, random: Random(1));
      await expectLater(
        bossRush.start(
          _configuration(CharacterId.jano, mode: RunMode.bossRush),
        ),
        throwsA(isA<Exception>()),
      );
    },
  );

  test(
    'ten local victories persist rewards and unlock purchases plus Boss Rush',
    () async {
      var session = await campaign.startStage(
        configuration: _configuration(CharacterId.jano, level: 10),
        bankedCurrency: 0,
        temporaryCurrency: 0,
      );
      expect(session.configuration.level, 1, reason: 'URL cannot skip levels');
      expect(session.canEarnRewards, isTrue);

      for (var level = 1; level <= 10; level++) {
        final payload = <String, Object?>{
          'stage_token': session.stageToken,
          'idempotency_key': 'stage-$level',
          'outcome': 'victory',
          'score': 10000,
          'duration_ms': 60000,
        };
        final receipt = await campaign.finishStage(payload);
        expect(receipt.accepted, isTrue);
        expect(receipt.ranked, isFalse);
        expect(receipt.readyToComplete, level == 10);

        if (level == 1) {
          final duplicate = await campaign.finishStage(payload);
          expect(duplicate.temporaryCurrency, receipt.temporaryCurrency);
          expect((await campaign.loadActiveCampaign())!.currentLevel, 2);
        }
        if (level < 10) {
          session = await campaign.startStage(
            configuration: _configuration(CharacterId.jano, level: level + 1),
            bankedCurrency: 0,
            temporaryCurrency: receipt.temporaryCurrency,
          );
          expect(session.configuration.level, level + 1);
        }
      }

      final completion = await campaign.completeCampaign({
        'campaign_id': session.campaignId,
        'idempotency_key': 'complete-jano',
      });
      expect(completion.accepted, isTrue);
      expect(completion.purchasePhaseUnlocked, isTrue);
      expect(completion.bankedCurrency, 10000);
      expect(await campaign.loadActiveCampaign(), isNull);

      var snapshot = await _snapshot(progression, CharacterId.jano);
      expect(snapshot.masteryXp, 1550);
      expect(snapshot.masteryLevel, 5);
      expect(snapshot.storeUnlocked, isTrue);
      expect(snapshot.bankedCurrency, 10000);

      final speed = snapshot.stats.firstWhere((stat) => stat.id == 'speed');
      await progression.purchaseUpgrade(snapshot: snapshot, stat: speed);
      snapshot = await _snapshot(progression, CharacterId.jano);
      final firstActive = snapshot.skills.firstWhere(
        (skill) => skill.slot == SkillSlot.active && skill.unlockLevel == 5,
      );
      await progression.purchaseSkill(snapshot: snapshot, skill: firstActive);
      snapshot = await _snapshot(progression, CharacterId.jano);
      final aurora = snapshot.palettes.firstWhere(
        (palette) => palette.id == 'jano_aurora',
      );
      await progression.purchasePalette(snapshot: snapshot, palette: aurora);
      snapshot = await _snapshot(progression, CharacterId.jano);
      await progression.equipLoadout(
        snapshot: snapshot,
        selection: LoadoutSelection(
          activeSkillId: firstActive.id,
          passiveSkillIds: const [],
          skinId: aurora.id,
        ),
      );

      final reloaded = LocalProgressionRepository(
        store: LocalGameStateStore(
          preferences: preferences,
          authRepository: auth,
        ),
      );
      snapshot = await _snapshot(reloaded, CharacterId.jano);
      expect(snapshot.bankedCurrency, 7800);
      expect(snapshot.stats.firstWhere((stat) => stat.id == 'speed').rank, 1);
      expect(snapshot.authorizedBuild.activeSkillId, firstActive.id);
      expect(snapshot.authorizedBuild.skinId, aurora.id);

      final bossRush = LocalBossRushRepository(
        store: store,
        random: Random(19),
      );
      final rush = await bossRush.start(
        _configuration(CharacterId.jano, mode: RunMode.bossRush),
      );
      final rushReceipt = await bossRush.finish({
        'attempt_token': rush.attemptToken,
        'idempotency_key': 'rush-1',
        'bosses_defeated': 3,
      });
      expect(rushReceipt.masteryXpGranted, 60);
      expect(rushReceipt.bossesDefeated, 3);
      expect((await _snapshot(progression, CharacterId.jano)).masteryXp, 1610);
    },
  );

  test(
    'defeat loses temporary currency but keeps permanent purchases',
    () async {
      await _completeCampaign(campaign, CharacterId.jano);
      final before = await _snapshot(progression, CharacterId.jano);
      expect(before.bankedCurrency, 10000);

      var session = await campaign.startStage(
        configuration: _configuration(CharacterId.jano),
        bankedCurrency: before.bankedCurrency,
        temporaryCurrency: 0,
      );
      await expectLater(
        progression.purchaseUpgrade(
          snapshot: before,
          stat: before.stats.firstWhere((stat) => stat.id == 'speed'),
        ),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.code,
            'code',
            AppFailureCode.conflict,
          ),
        ),
      );
      final victory = await campaign.finishStage({
        'stage_token': session.stageToken,
        'idempotency_key': 'repeat-win',
        'outcome': 'victory',
        'score': 5000,
        'duration_ms': 60000,
      });
      expect(victory.temporaryCurrency, 500);

      session = await campaign.startStage(
        configuration: _configuration(CharacterId.jano, level: 2),
        bankedCurrency: before.bankedCurrency,
        temporaryCurrency: victory.temporaryCurrency,
      );
      final defeat = await campaign.finishStage({
        'stage_token': session.stageToken,
        'idempotency_key': 'repeat-loss',
        'outcome': 'defeat',
        'score': 250,
        'duration_ms': 30000,
      });
      expect(defeat.currencyLost, 500);
      expect(await campaign.loadActiveCampaign(), isNull);
      final after = await _snapshot(progression, CharacterId.jano);
      expect(after.bankedCurrency, before.bankedCurrency);
      expect(after.temporaryCurrency, 0);
      expect(after.storeUnlocked, isTrue);
      expect(after.masteryXp, greaterThan(before.masteryXp));
    },
  );

  test('local progression is isolated by signed-in account', () async {
    await _completeCampaign(campaign, CharacterId.jano);
    expect(
      (await _snapshot(progression, CharacterId.jano)).storeUnlocked,
      isTrue,
    );

    final otherAuth = FakeAuthRepository.signedIn(userId: 'local-b');
    addTearDown(otherAuth.dispose);
    final otherProgression = LocalProgressionRepository(
      store: LocalGameStateStore(
        preferences: preferences,
        authRepository: otherAuth,
      ),
    );
    final other = await _snapshot(otherProgression, CharacterId.jano);
    expect(other.masteryXp, 0);
    expect(other.bankedCurrency, 0);
    expect(other.storeUnlocked, isFalse);
  });

  test('an active Boss Rush freezes the store and any second run', () async {
    await _completeCampaign(campaign, CharacterId.jano);
    final snapshot = await _snapshot(progression, CharacterId.jano);
    final bossRush = LocalBossRushRepository(store: store, random: Random(4));
    final session = await bossRush.start(
      _configuration(CharacterId.jano, mode: RunMode.bossRush),
    );

    await expectLater(
      progression.purchaseUpgrade(
        snapshot: snapshot,
        stat: snapshot.stats.firstWhere((stat) => stat.id == 'speed'),
      ),
      throwsA(isA<AppFailure>()),
    );
    await expectLater(
      bossRush.start(_configuration(CharacterId.jano, mode: RunMode.bossRush)),
      throwsA(isA<AppFailure>()),
    );
    await expectLater(
      campaign.startStage(
        configuration: _configuration(CharacterId.jano),
        bankedCurrency: snapshot.bankedCurrency,
        temporaryCurrency: 0,
      ),
      throwsA(isA<AppFailure>()),
    );

    await bossRush.abandon(session);
    expect(
      await campaign.startStage(
        configuration: _configuration(CharacterId.jano),
        bankedCurrency: snapshot.bankedCurrency,
        temporaryCurrency: 0,
      ),
      isA<CampaignStageSession>(),
    );
  });

  test('a level-ten crash window recovers and banks exactly once', () async {
    CampaignStageSession? session;
    for (var level = 1; level <= 10; level++) {
      session = await campaign.startStage(
        configuration: _configuration(CharacterId.jano, level: level),
        bankedCurrency: 0,
        temporaryCurrency: 0,
      );
      await campaign.finishStage({
        'stage_token': session.stageToken,
        'idempotency_key': 'recovery-$level',
        'outcome': 'victory',
        'score': 10000,
        'duration_ms': 60000,
      });
    }

    expect(await campaign.loadActiveCampaign(), isNull);
    expect(await campaign.loadActiveCampaign(), isNull);
    final recovered = await _snapshot(progression, CharacterId.jano);
    expect(recovered.storeUnlocked, isTrue);
    expect(recovered.bankedCurrency, 10000);
  });

  test('all seven characters can clear the complete local campaign', () async {
    for (final character in CharacterId.values) {
      await _completeCampaign(campaign, character);
      final snapshot = await _snapshot(progression, character);
      expect(snapshot.storeUnlocked, isTrue, reason: character.serialized);
      expect(snapshot.masteryXp, 1550, reason: character.serialized);
      expect(snapshot.bankedCurrency, 10000, reason: character.serialized);
    }
  });
}

Future<void> _completeCampaign(
  LocalCampaignRepository campaign,
  CharacterId characterId,
) async {
  CampaignStageSession? session;
  for (var level = 1; level <= 10; level++) {
    session = await campaign.startStage(
      configuration: _configuration(characterId, level: level),
      bankedCurrency: 0,
      temporaryCurrency: 0,
    );
    await campaign.finishStage({
      'stage_token': session.stageToken,
      'idempotency_key': '${characterId.serialized}-complete-$level',
      'outcome': 'victory',
      'score': 10000,
      'duration_ms': 60000,
    });
  }
  await campaign.completeCampaign({
    'campaign_id': session!.campaignId,
    'idempotency_key': '${characterId.serialized}-complete-campaign',
  });
}

Future<ProgressionSnapshot> _snapshot(
  LocalProgressionRepository repository,
  CharacterId characterId,
) => repository.loadSnapshot(
  characterId: characterId,
  contentVersion: 'v6-preview-1',
);

RunConfiguration _configuration(
  CharacterId characterId, {
  int level = 1,
  RunMode mode = RunMode.progression,
}) {
  final definition = characterId.definition;
  return RunConfiguration(
    characterId: characterId,
    mode: mode,
    stats: RunStats.base(definition),
    loadout: RunLoadout(activeAbility: definition.defaultActive),
    level: level,
    contentVersion: 'v6-preview-1',
    protocolVersion: 1,
    seed: level,
    experience: mode == RunMode.bossRush
        ? RunExperience.bossRush
        : RunExperience.campaignStage,
  );
}
