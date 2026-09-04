import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flame runtime does not import persistence or networking packages', () {
    const forbiddenImports = [
      'package:shared_preferences/',
      'package:supabase_flutter/',
      'package:drift/',
    ];
    final dartFiles = Directory('lib/game')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      for (final forbiddenImport in forbiddenImports) {
        expect(
          source,
          isNot(contains(forbiddenImport)),
          reason: '${file.path} must keep persistence outside Flame.',
        );
      }
    }
  });
}
