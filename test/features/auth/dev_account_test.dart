import 'dart:convert';

import 'package:dino_run_flame/core/security/dev_account_provisioner.dart';
import 'package:dino_run_flame/features/auth/data/local_auth_repository.dart';
import 'package:dino_run_flame/features/progression/data/local_game_state_store.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DevAccountProvisioner', () {
    test('validates developer credentials accurately', () {
      expect(DevAccountProvisioner.isDevUsername('JanoDev'), isTrue);
      expect(DevAccountProvisioner.isDevUsername('janodev'), isTrue);
      expect(DevAccountProvisioner.isDevUsername('JANODEV'), isTrue);
      expect(DevAccountProvisioner.isDevUsername('janodev@janosos.dev'), isTrue);
      expect(DevAccountProvisioner.isDevUsername('random_user'), isFalse);
      expect(DevAccountProvisioner.isDevUsername(null), isFalse);

      expect(DevAccountProvisioner.isDevPassword('1mp3ri0'), isTrue);
      expect(DevAccountProvisioner.isDevPassword('wrongpass'), isFalse);
      expect(DevAccountProvisioner.isDevPassword(null), isFalse);

      expect(
        DevAccountProvisioner.isDevCredentials('JanoDev', '1mp3ri0'),
        isTrue,
      );
      expect(
        DevAccountProvisioner.isDevCredentials('janodev', '1mp3ri0'),
        isTrue,
      );
      expect(
        DevAccountProvisioner.isDevCredentials('JanoDev', 'wrongpass'),
        isFalse,
      );
      expect(
        DevAccountProvisioner.isDevCredentials('otherUser', '1mp3ri0'),
        isFalse,
      );
    });

    test('provisions full dev progression data for all characters', () async {
      final preferences = await SharedPreferences.getInstance();
      await DevAccountProvisioner.provisionDevData(preferences: preferences);

      // Verify SharedPreferences campaign keys
      for (final char in CharacterId.values) {
        expect(
          preferences.getInt('campaign_max_unlocked_level_${char.serialized}'),
          10,
        );
        expect(
          preferences.getBool('campaign_completed_${char.serialized}'),
          isTrue,
        );
      }
      expect(preferences.getInt('campaign_max_unlocked_level'), 10);
      expect(preferences.getBool('campaign_completed'), isTrue);
      expect(preferences.getBool('boss_rush_unlocked'), isTrue);
      expect(preferences.getInt('high_score'), 99999);

      // Verify LocalGameState json
      final rawState = preferences.getString(
        'janosos.v6.local_game_state.${DevAccountProvisioner.devUserId}',
      );
      expect(rawState, isNotNull);

      final state = LocalGameState.fromJson(
        jsonDecode(rawState!) as Map<String, Object?>,
      );

      for (final char in CharacterId.values) {
        final progress = state.character(char);
        expect(progress.bankedCurrency, 99999);
        expect(progress.storeUnlocked, isTrue);
        expect(progress.highestUnlockedLevel, 10);
        expect(
          progress.defeatedBossLevels,
          containsAll([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
        );
      }
    });

    test('signs in via LocalAuthRepository and provisions dev state', () async {
      final preferences = await SharedPreferences.getInstance();
      final repository = await LocalAuthRepository.create(preferences);

      await repository.signIn(email: 'JanoDev', password: '1mp3ri0');

      expect(repository.currentSession.isAuthenticated, isTrue);
      expect(
        repository.currentSession.user?.displayName,
        DevAccountProvisioner.devDisplayName,
      );
      expect(
        repository.currentSession.user?.id,
        DevAccountProvisioner.devUserId,
      );

      // Verify store can read 99999 coins for all characters
      final store = LocalGameStateStore(
        preferences: preferences,
        authRepository: repository,
      );
      final gameState = store.currentState;
      for (final char in CharacterId.values) {
        final charProgress = gameState.character(char);
        expect(charProgress.bankedCurrency, 99999);
        expect(charProgress.highestUnlockedLevel, 10);
        expect(
          charProgress.defeatedBossLevels,
          containsAll([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
        );
      }
    });
  });
}
