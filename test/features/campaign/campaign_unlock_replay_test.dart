import 'dart:math';

import 'package:dino_run_flame/features/campaign/data/local_campaign_repository.dart';
import 'package:dino_run_flame/features/progression/data/local_game_state_store.dart';
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    auth = FakeAuthRepository.signedIn(userId: 'local-tester');
    store = LocalGameStateStore(preferences: preferences, authRepository: auth);
    campaign = LocalCampaignRepository(store: store, random: Random(42));
  });

  tearDown(() => auth.dispose());

  RunConfiguration configuration(CharacterId id, {int level = 1}) {
    final definition = id.definition;
    return RunConfiguration(
      characterId: id,
      mode: RunMode.progression,
      stats: RunStats.base(definition),
      loadout: RunLoadout(activeAbility: definition.defaultActive),
      level: level,
      contentVersion: 'v1',
      protocolVersion: 1,
      seed: 12345,
      experience: RunExperience.campaignStage,
    );
  }

  test(
    'clearing a boss permanently unlocks the next level and keeps previous replayable',
    () async {
      // 1. Initial state: Level 1 is allowed, Level 2 is locked.
      var session1 = await campaign.startStage(
        configuration: configuration(CharacterId.jano, level: 2),
        bankedCurrency: 0,
        temporaryCurrency: 0,
      );
      expect(
        session1.configuration.level,
        1,
        reason: 'Level 2 cannot be skipped initially',
      );

      // 2. Clear Level 1 with victory.
      final receipt1 = await campaign.finishStage({
        'stage_token': session1.stageToken,
        'idempotency_key': 'win-level-1',
        'outcome': 'victory',
        'score': 10000,
        'duration_ms': 50000,
      });
      expect(receipt1.accepted, isTrue);
      expect(receipt1.nextLevel, 2);

      // Verify stored progress has highestUnlockedLevel = 2.
      final snapshotAfterWin = await store.read(
        (s) => s.character(CharacterId.jano).highestUnlockedLevel,
      );
      expect(snapshotAfterWin, 2);

      // 3. Now Level 2 is unlocked! Starting at Level 2 should succeed.
      var session2 = await campaign.startStage(
        configuration: configuration(CharacterId.jano, level: 2),
        bankedCurrency: 0,
        temporaryCurrency: receipt1.temporaryCurrency,
      );
      expect(session2.configuration.level, 2);

      // 4. Defeat in Level 2.
      final receipt2 = await campaign.finishStage({
        'stage_token': session2.stageToken,
        'idempotency_key': 'loss-level-2',
        'outcome': 'defeat',
        'score': 3000,
        'duration_ms': 20000,
      });
      expect(receipt2.accepted, isTrue);

      // After defeat, active campaign is null, BUT highestUnlockedLevel MUST remain 2 permanently!
      final active = await campaign.loadActiveCampaign();
      expect(active, isNull);
      final snapshotAfterLoss = await store.read(
        (s) => s.character(CharacterId.jano).highestUnlockedLevel,
      );
      expect(
        snapshotAfterLoss,
        2,
        reason: 'Unlocked level must be permanently preserved despite defeat',
      );

      // 5. Player can start Level 2 directly again without having to replay Level 1!
      final session2Retry = await campaign.startStage(
        configuration: configuration(CharacterId.jano, level: 2),
        bankedCurrency: 0,
        temporaryCurrency: 0,
      );
      expect(session2Retry.configuration.level, 2);

      // 6. Player can also replay Level 1 at any time!
      final replaySession1 = await campaign.startStage(
        configuration: configuration(CharacterId.jano, level: 1),
        bankedCurrency: 0,
        temporaryCurrency: 0,
      );
      expect(replaySession1.configuration.level, 1);
    },
  );
}
