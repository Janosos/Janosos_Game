import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'app_theme.dart';

class JanososApp extends ConsumerWidget {
  const JanososApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Janosos V6',
      debugShowCheckedModeBanner: false,
      theme: buildJanososTheme(),
      routerConfig: router,
    );
  }
}
