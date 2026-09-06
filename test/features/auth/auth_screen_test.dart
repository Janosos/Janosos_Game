import 'package:dino_run_flame/app/app_providers.dart';
import 'package:dino_run_flame/core/config/app_environment.dart';
import 'package:dino_run_flame/features/auth/presentation/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  testWidgets(
    'in local mode does not show Google/Apple OAuth buttons and shows 1-tap guest option',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authRepository = FakeAuthRepository();
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
                contentVersion: 'v6-preview-1',
              ),
            ),
            authRepositoryProvider.overrideWithValue(authRepository),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // On welcome screen, verify local mode branding
      expect(find.text('MODO LOCAL'), findsOneWidget);
      expect(find.text('CUENTA LOCAL'), findsOneWidget);

      // Navigate to form view
      await tester.tap(find.text('INICIAR'));
      await tester.pumpAndSettle();

      // Verify Google and Apple buttons are NOT shown in local mode
      expect(find.text('Continuar con Google'), findsNothing);
      expect(find.text('Continuar con Apple'), findsNothing);

      // Verify 1-tap guest button is available in the form view
      final guestButton = find.text('Jugar como Invitado (Sin Registro)');
      expect(guestButton, findsOneWidget);

      // Tap 1-tap guest button and verify session becomes authenticated
      await tester.tap(guestButton);
      await tester.pumpAndSettle();
      expect(authRepository.currentSession.isAuthenticated, isTrue);
      expect(authRepository.currentSession.user?.isGuest, isTrue);
    },
  );

  testWidgets(
    'in supabase mode shows Google and Apple OAuth buttons in form view',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authRepository = FakeAuthRepository();
      addTearDown(authRepository.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appEnvironmentProvider.overrideWithValue(
              AppEnvironment(
                backendMode: BackendMode.supabase,
                supabaseUrl: 'https://example.supabase.co',
                supabasePublishableKey: 'test-key',
                authRedirectUri: Uri(
                  scheme: 'io.janosos.game',
                  host: 'auth',
                  path: '/callback',
                ),
                contentVersion: 'v6-preview-1',
              ),
            ),
            authRepositoryProvider.overrideWithValue(authRepository),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to form view
      await tester.tap(find.text('INICIAR'));
      await tester.pumpAndSettle();

      // Verify Google and Apple buttons are displayed in supabase mode
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Continuar con Apple'), findsOneWidget);
      expect(find.text('Jugar como Invitado (Sin Registro)'), findsNothing);
    },
  );
}
