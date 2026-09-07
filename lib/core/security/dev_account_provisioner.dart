import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/progression/data/local_game_state_store.dart';
import '../../game/domain/character_id.dart';

/// Hidden developer account credentials and progression provisioner.
///
/// If a user logs in with [devUsername] ('JanoDev') and [devPassword] ('1mp3ri0'),
/// this provisioner unlocks all 10 bosses, unlocks Boss Rush and store access,
/// and sets 99,999 coins for all characters.
class DevAccountProvisioner {
  const DevAccountProvisioner._();

  static const String devUsername = 'JanoDev';
  static const String devPassword = '1mp3ri0';
  static const String devUserId = 'dev-janodev-001';
  static const String devEmail = 'janodev@janosos.dev';
  static const String devDisplayName = 'JanoDev';
  static const int devCoins = 99999;
  static const int devUnlockedLevel = 10;

  /// Returns true if [input] matches the developer username or email.
  static bool isDevUsername(String? input) {
    if (input == null) return false;
    final normalized = input.trim().toLowerCase();
    return normalized == 'janodev' ||
        normalized == 'janodev@janosos.dev' ||
        normalized == 'janodev@janosos.com' ||
        normalized == 'janodev@dev.com';
  }

  /// Returns true if [input] matches the developer secret password.
  static bool isDevPassword(String? input) {
    if (input == null) return false;
    return input.trim() == devPassword;
  }

  /// Validates both username/email and password for the hidden developer account.
  static bool isDevCredentials(String? usernameOrEmail, String? password) {
    return isDevUsername(usernameOrEmail) && isDevPassword(password);
  }

  /// Provisions full developer state: 99,999 coins across all characters,
  /// all 10 bosses/levels unlocked, and Boss Rush available.
  static Future<void> provisionDevData({
    required SharedPreferences preferences,
    String userId = devUserId,
  }) async {
    // 1. Build LocalGameState for the developer account
    final state = LocalGameState.empty();
    for (final charId in CharacterId.values) {
      final progress = state.character(charId);
      progress.bankedCurrency = devCoins;
      progress.storeUnlocked = true;
      progress.highestUnlockedLevel = devUnlockedLevel;
      progress.defeatedBossLevels.addAll([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    }

    final encodedState = jsonEncode(state.toJson());
    await preferences.setString('janosos.v6.local_game_state.$userId', encodedState);
    // Also provision guest state in case local fallback is read
    await preferences.setString('janosos.v6.local_game_state.guest', encodedState);

    // 2. Provision SharedPreferences keys for Campaign and Boss Rush
    for (final char in CharacterId.values) {
      await preferences.setInt(
        'campaign_max_unlocked_level_${char.serialized}',
        devUnlockedLevel,
      );
      await preferences.setBool(
        'campaign_completed_${char.serialized}',
        true,
      );
    }
    await preferences.setInt('campaign_max_unlocked_level', devUnlockedLevel);
    await preferences.setBool('campaign_completed', true);
    await preferences.setBool('boss_rush_unlocked', true);
    await preferences.setInt('high_score', devCoins);
  }
}
