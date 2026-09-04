import 'package:shared_preferences/shared_preferences.dart';

import 'app_database.dart';

class LegacyScoreMigrator {
  const LegacyScoreMigrator({
    required AppDatabase database,
    required SharedPreferences preferences,
  }) : _database = database,
       _preferences = preferences;

  final AppDatabase _database;
  final SharedPreferences _preferences;

  Future<void> run() async {
    final legacyScore = _preferences.getInt('high_score');
    if (legacyScore == null || legacyScore < 0) {
      return;
    }
    await _database.preserveLegacyScore(legacyScore);
  }
}
