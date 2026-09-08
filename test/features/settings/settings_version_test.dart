import 'package:dino_run_flame/app/app_providers.dart';
import 'package:dino_run_flame/core/config/app_environment.dart';
import 'package:dino_run_flame/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  testWidgets('settings screen displays Version 6.2 made by Jano and Chema', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final authRepository = FakeAuthRepository();
    addTearDown(authRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authRepositoryProvider.overrideWithValue(authRepository),
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
              contentVersion: 'v6-preview-1',
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final versionFinder = find.text('Version 6.2 made by Jano and Chema');
    await tester.scrollUntilVisible(versionFinder, 300);
    await tester.pumpAndSettle();

    expect(versionFinder, findsOneWidget);
    expect(find.text('★ ANOTHER RETRO RUNNER GAME ★'), findsOneWidget);
  });
}
