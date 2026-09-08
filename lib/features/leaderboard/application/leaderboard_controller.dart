import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../domain/leaderboard_models.dart';

class LeaderboardViewState {
  const LeaderboardViewState({
    required this.selectedCategory,
    required this.endlessEntries,
    required this.bossRushEntries,
    this.errorMessage,
  });

  final LeaderboardCategory selectedCategory;
  final List<EndlessLeaderboardEntry> endlessEntries;
  final List<BossRushLeaderboardEntry> bossRushEntries;
  final String? errorMessage;

  LeaderboardViewState copyWith({
    LeaderboardCategory? selectedCategory,
    List<EndlessLeaderboardEntry>? endlessEntries,
    List<BossRushLeaderboardEntry>? bossRushEntries,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LeaderboardViewState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      endlessEntries: endlessEntries ?? this.endlessEntries,
      bossRushEntries: bossRushEntries ?? this.bossRushEntries,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final leaderboardControllerProvider =
    AsyncNotifierProvider<LeaderboardController, LeaderboardViewState>(
      LeaderboardController.new,
    );

class LeaderboardController extends AsyncNotifier<LeaderboardViewState> {
  @override
  Future<LeaderboardViewState> build() async {
    ref.watch(authControllerProvider.select((auth) => auth.session.user?.id));
    return _load(LeaderboardCategory.endless);
  }

  Future<void> selectCategory(LeaderboardCategory category) async {
    final current = state.value;
    if (current != null && current.selectedCategory == category) return;
    state = AsyncData(
      current?.copyWith(selectedCategory: category) ??
          LeaderboardViewState(
            selectedCategory: category,
            endlessEntries: const [],
            bossRushEntries: const [],
          ),
    );
  }

  Future<void> refresh() async {
    final current = state.value;
    final category = current?.selectedCategory ?? LeaderboardCategory.endless;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(category));
  }

  Future<LeaderboardViewState> _load(LeaderboardCategory category) async {
    final repository = ref.read(leaderboardRepositoryProvider);
    final endless = await repository.fetchEndlessLeaderboard();
    final bossRush = await repository.fetchBossRushLeaderboard();
    return LeaderboardViewState(
      selectedCategory: category,
      endlessEntries: endless,
      bossRushEntries: bossRush,
    );
  }
}
