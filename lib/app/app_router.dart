import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/campaign/presentation/campaign_screen.dart';
import '../features/characters/presentation/characters_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/leaderboard/presentation/leaderboard_screen.dart';
import '../features/progression/presentation/progression_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../game/domain/character_id.dart';
import '../game/presentation/game_route_screen.dart';
import 'app_providers.dart';
import 'app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final refresh = _AuthRouterRefresh(repository);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = repository.currentSession;
      final path = state.uri.path;
      final isAuthRoute = path == '/auth' || path == '/auth/callback';

      if (!session.isAuthenticated && !isAuthRoute) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/auth?from=$from';
      }
      if (session.isAuthenticated && isAuthRoute) {
        final encodedFrom = state.uri.queryParameters['from'];
        if (encodedFrom != null) {
          final from = Uri.decodeComponent(encodedFrom);
          if (from.startsWith('/') && !from.startsWith('/auth')) {
            return from;
          }
        }
        return '/home';
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.route_outlined, size: 64),
              const SizedBox(height: 16),
              const Text('No encontramos esta pantalla.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/home'),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => const AuthCallbackScreen(),
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) {
          final characterValue = state.uri.queryParameters['character'];
          CharacterId? campaignCharacter;
          CharacterId? bossRushCharacter;
          var campaignLevel = 1;
          final experience = state.uri.queryParameters['experience'];
          if ((experience == 'campaign' || experience == 'boss_rush') &&
              characterValue != null) {
            try {
              final parsed = CharacterIdSerialization.parse(characterValue);
              if (experience == 'campaign') {
                campaignCharacter = parsed;
              } else {
                bossRushCharacter = parsed;
              }
            } on FormatException {
              campaignCharacter = null;
            }
            campaignLevel =
                int.tryParse(state.uri.queryParameters['level'] ?? '') ?? 1;
          }
          return GameRouteScreen(
            campaignCharacter: campaignCharacter,
            bossRushCharacter: bossRushCharacter,
            campaignLevel: campaignLevel.clamp(1, 10),
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) =>
            JanososAppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/characters',
            builder: (context, state) => const CharactersScreen(),
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/campaign',
            builder: (context, state) => const CampaignScreen(),
          ),
          GoRoute(
            path: '/store',
            builder: (context, state) => const ProgressionScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(AuthRepository repository) {
    _subscription = repository.sessionChanges.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
