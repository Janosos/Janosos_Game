import 'package:dino_run_flame/app/app_providers.dart';
import 'package:dino_run_flame/core/config/app_environment.dart';
import 'package:dino_run_flame/features/leaderboard/domain/leaderboard_models.dart';
import 'package:dino_run_flame/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:dino_run_flame/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  testWidgets('shows verified global data and pending personal history', (
    tester,
  ) async {
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

    expect(find.text('Leaderboard por personaje'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('777'), findsOneWidget);

    await tester.tap(find.text('Mi historial'));
    await tester.pumpAndSettle();

    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Sólo en este dispositivo'), findsOneWidget);
    expect(find.textContaining('todavía no aparece'), findsOneWidget);
  });
}

class _FixtureLeaderboardRepository implements LeaderboardRepository {
  @override
  Future<LeaderboardPage> fetchGlobalPage({
    required LeaderboardFilter filter,
    LeaderboardCursor? after,
    int pageSize = 25,
  }) async {
    return LeaderboardPage(
      entries: [
        LeaderboardEntry(
          position: 1,
          id: 'entry-1',
          displayName: 'Alpha',
          characterId: filter.characterId,
          mode: filter.mode,
          contentVersion: filter.contentVersion,
          completed: true,
          levelReached: 10,
          totalScore: 777,
          durationMs: 65000,
          endedAt: DateTime.utc(2026, 8, 31),
        ),
      ],
      nextCursor: null,
    );
  }

  @override
  Future<List<RunHistoryEntry>> fetchPersonalHistory({
    required LeaderboardFilter filter,
    int limit = 100,
  }) async {
    return [
      RunHistoryEntry(
        id: 'pending-1',
        characterId: filter.characterId,
        mode: filter.mode,
        outcome: HistoryOutcome.defeat,
        validation: ResultValidation.pending,
        completed: false,
        levelReached: 1,
        totalScore: 123,
        durationMs: 9000,
        endedAt: DateTime.utc(2026, 8, 31),
        contentVersion: filter.contentVersion,
        isLocalOnly: true,
      ),
    ];
  }
}
