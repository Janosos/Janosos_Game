import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

QueryExecutor openAppDatabaseConnection() {
  return LazyDatabase(() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final databaseFile = File(
      path.join(supportDirectory.path, 'janosos_v6.sqlite'),
    );
    return NativeDatabase.createInBackground(databaseFile);
  });
}
