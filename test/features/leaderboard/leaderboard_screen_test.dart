import 'package:dino_run_flame/app/app_providers.dart';
import 'package:dino_run_flame/core/config/app_environment.dart';
import 'package:dino_run_flame/features/auth/domain/auth_models.dart';
import 'package:dino_run_flame/features/leaderboard/domain/leaderboard_models.dart';
import 'package:dino_run_flame/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:dino_run_flame/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  testWidgets('shows auth required message when user is in guest mode', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository(
      session: const AuthSessionSnapshot.authenticated(
        AuthUserProfile(
          id: 'guest-user',
          email: 'guest@example.com',
          displayName: 'Guest',
          isEmailVerified: true,
          isGuest: true,
        ),
      ),
    );
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
        child: const MaterialApp(home: Scaffold(body: LeaderboardScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('INICIO DE SESIÓN REQUERIDO'), findsOneWidget);
    expect(
      find.textContaining('se requiere inicio de sesión'),
      findsOneWidget,
    );
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(find.text('VOLVER AL INICIO'), findsOneWidget);
  });

  testWidgets('shows endless and boss rush leaderboards', (tester) async {
    final authRepository = FakeAuthRepository.signedIn(
      userId: 'user-a',
      displayName: 'Alpha',
    );
    addTearDown(authRepository.dispose);
    final repository = _FixtureLeaderboardRepository();

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
          leaderboardRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: LeaderboardScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RANKING ONLINE'), findsOneWidget);
    expect(find.text('MODO ENDLESS'), findsOneWidget);
    expect(find.text('BOSS RUSH'), findsOneWidget);

    // Endless view checks
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('777'), findsOneWidget);
    expect(find.text('JANO'), findsOneWidget);

    // Switch to Boss Rush
    await tester.tap(find.text('BOSS RUSH'));
    await tester.pumpAndSettle();

    expect(find.text('5 VICTORIAS'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('renders responsively in landscape mobile without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authRepository = FakeAuthRepository.signedIn(
      userId: 'user-landscape-lead',
      displayName: 'Leader',
    );
    addTearDown(authRepository.dispose);
    final repository = _FixtureLeaderboardRepository();

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
          leaderboardRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: LeaderboardScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('RANKING ONLINE'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);

    await tester.tap(find.text('BOSS RUSH'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('5 VICTORIAS'), findsOneWidget);
  });
}

class _FixtureLeaderboardRepository implements LeaderboardRepository {
  @override
  Future<List<EndlessLeaderboardEntry>> fetchEndlessLeaderboard({
    int limit = 50,
  }) async {
    return [
      EndlessLeaderboardEntry(
        position: 1,
        userId: 'user-a',
        displayName: 'Alpha',
        characterId: CharacterId.jano,
        score: 777,
        durationMs: 65000,
        updatedAt: DateTime.utc(2026, 8, 31),
      ),
    ];
  }

  @override
  Future<List<BossRushLeaderboardEntry>> fetchBossRushLeaderboard({
    int limit = 50,
  }) async {
    return [
      BossRushLeaderboardEntry(
        position: 1,
        userId: 'user-a',
        displayName: 'Alpha',
        completionsCount: 5,
        updatedAt: DateTime.utc(2026, 8, 31),
      ),
    ];
  }

  @override
  Future<void> recordEndlessRun({
    required CharacterId characterId,
    required int score,
    required Duration duration,
  }) async {}

  @override
  Future<void> recordBossRushCompletion() async {}
}
