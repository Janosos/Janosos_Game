import 'package:dino_run_flame/app/app_providers.dart';
import 'package:dino_run_flame/core/config/app_environment.dart';
import 'package:dino_run_flame/features/progression/domain/progression_catalog.dart';
import 'package:dino_run_flame/features/progression/domain/progression_models.dart';
import 'package:dino_run_flame/features/progression/domain/progression_repository.dart';
import 'package:dino_run_flame/features/progression/presentation/progression_screen.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  testWidgets(
    'shows economy, exclusive skills, palettes, and purchase feedback',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final authRepository = FakeAuthRepository.signedIn(
        userId: 'user-progression',
        displayName: 'Progression Player',
      );
      addTearDown(authRepository.dispose);
      final repository = _FixtureProgressionRepository();

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
            progressionRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: Scaffold(body: ProgressionScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MONEDAS'), findsWidgets);
      expect(find.text('MAESTRÍA LVL 30'), findsOneWidget);
      expect(find.text('VELOCIDAD'), findsOneWidget);

      final firstUpgrade = find.text('150').first;
      await tester.ensureVisible(firstUpgrade);
      await tester.pumpAndSettle();
      await tester.tap(firstUpgrade);
      await tester.pumpAndSettle();
      expect(repository.upgradePurchases, 1);
      expect(find.textContaining('avanzó al rango 1'), findsOneWidget);

      await tester.tap(find.text('ASPECTOS').first);
      await tester.pumpAndSettle();
      expect(find.text('ORIGINAL'), findsOneWidget);
      expect(find.text('AURORA'), findsOneWidget);
      expect(find.text('ECLIPSE'), findsOneWidget);
      expect(find.text('★ ARCOÍRIS ★'), findsOneWidget);
    },
  );

  testWidgets(
    'adapts responsively to compact landscape phone screen without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(800, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authRepository = FakeAuthRepository.signedIn(
        userId: 'user-landscape',
        displayName: 'Landscape Player',
      );
      addTearDown(authRepository.dispose);
      final repository = _FixtureProgressionRepository();

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
            progressionRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: Scaffold(body: ProgressionScreen())),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no overflow occurred and elements are rendered properly
      expect(tester.takeException(), isNull);
      expect(find.text('MONEDAS'), findsWidgets);
      expect(find.text('MAESTRÍA LVL 30'), findsOneWidget);

      // Verify tabs are reachable and interactive in landscape
      expect(find.text('MEJORAS'), findsWidgets);
      expect(find.text('ASPECTOS'), findsWidgets);

      // Test tapping tabs
      await tester.tap(find.text('ASPECTOS').first);
      await tester.pumpAndSettle();
      expect(find.text('★ ARCOÍRIS ★'), findsOneWidget);
    },
  );
}

class _FixtureProgressionRepository implements ProgressionRepository {
  int upgradePurchases = 0;

  @override
  Future<ProgressionSnapshot> loadSnapshot({
    required CharacterId characterId,
    required String contentVersion,
  }) async {
    final preview = ProgressionCatalog.preview(characterId, contentVersion);
    return ProgressionSnapshot(
      characterId: preview.characterId,
      contentVersion: preview.contentVersion,
      contentDigest: preview.contentDigest,
      masteryXp: 46500,
      masteryLevel: 30,
      nextLevelXp: 46500,
      bankedCurrency: 100000,
      temporaryCurrency: 432,
      storeUnlocked: true,
      authorizedBuild: preview.authorizedBuild,
      stats: preview.stats,
      skills: preview.skills,
      palettes: preview.palettes,
    );
  }

  @override
  Future<void> purchaseUpgrade({
    required ProgressionSnapshot snapshot,
    required ProgressionStat stat,
  }) async {
    upgradePurchases += 1;
  }

  @override
  Future<void> purchaseSkill({
    required ProgressionSnapshot snapshot,
    required ProgressionSkill skill,
  }) async {}

  @override
  Future<void> purchasePalette({
    required ProgressionSnapshot snapshot,
    required PaletteVariant palette,
  }) async {}

  @override
  Future<void> equipLoadout({
    required ProgressionSnapshot snapshot,
    required LoadoutSelection selection,
  }) async {}

  @override
  Future<void> creditCurrency({
    required CharacterId characterId,
    required int amount,
  }) async {}
}
