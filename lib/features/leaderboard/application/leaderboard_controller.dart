import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../game/domain/character_id.dart';
import '../../../game/domain/run_configuration.dart';
import '../../auth/application/auth_controller.dart';
import '../domain/leaderboard_models.dart';

class LeaderboardViewState {
  const LeaderboardViewState({
    required this.filter,
    required this.globalEntries,
    required this.personalHistory,
    required this.nextCursor,
    this.availabilityMessage,
    this.errorMessage,
    this.isLoadingMore = false,
  });

  final LeaderboardFilter filter;
  final List<LeaderboardEntry> globalEntries;
  final List<RunHistoryEntry> personalHistory;
  final LeaderboardCursor? nextCursor;
  final String? availabilityMessage;
  final String? errorMessage;
  final bool isLoadingMore;

  bool get canLoadMore => nextCursor != null && !isLoadingMore;

  LeaderboardViewState copyWith({
    List<LeaderboardEntry>? globalEntries,
    List<RunHistoryEntry>? personalHistory,
    LeaderboardCursor? nextCursor,
    String? availabilityMessage,
    String? errorMessage,
    bool? isLoadingMore,
    bool clearCursor = false,
    bool clearError = false,
  }) {
    return LeaderboardViewState(
      filter: filter,
      globalEntries: globalEntries ?? this.globalEntries,
      personalHistory: personalHistory ?? this.personalHistory,
      nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
      availabilityMessage: availabilityMessage ?? this.availabilityMessage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final leaderboardControllerProvider =
    AsyncNotifierProvider<LeaderboardController, LeaderboardViewState>(
      LeaderboardController.new,
    );

class LeaderboardController extends AsyncNotifier<LeaderboardViewState> {
  static const pageSize = 25;

  @override
  Future<LeaderboardViewState> build() async {
    ref.watch(authControllerProvider.select((auth) => auth.session.user?.id));
    final environment = ref.watch(appEnvironmentProvider);
    final filter = LeaderboardFilter(
      characterId: CharacterId.jano,
      mode: RunMode.progression,
      contentVersion: environment.contentVersion,
    );
    return _load(filter);
  }

  Future<void> selectCharacter(CharacterId characterId) async {
    final current = state.value;
    if (current == null || current.filter.characterId == characterId) {
      return;
    }
    await _replace(current.filter.copyWith(characterId: characterId));
  }

  Future<void> selectMode(RunMode mode) async {
    final current = state.value;
    if (current == null || current.filter.mode == mode) {
      return;
    }
    await _replace(current.filter.copyWith(mode: mode));
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }
    await _replace(current.filter);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.canLoadMore) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true, clearError: true));
    try {
      final page = await ref
          .read(leaderboardRepositoryProvider)
          .fetchGlobalPage(
            filter: current.filter,
            after: current.nextCursor,
            pageSize: pageSize,
          );
      state = AsyncData(
        current.copyWith(
          globalEntries: [...current.globalEntries, ...page.entries],
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          availabilityMessage: page.availabilityMessage,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } on Object catch (error, stackTrace) {
      state = AsyncData(
        current.copyWith(
          isLoadingMore: false,
          errorMessage: _friendlyError(error),
        ),
      );
      ref.read(leaderboardErrorLogProvider).call(error, stackTrace);
    }
  }

  Future<void> _replace(LeaderboardFilter filter) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(filter));
  }

  Future<LeaderboardViewState> _load(LeaderboardFilter filter) async {
    final repository = ref.read(leaderboardRepositoryProvider);
    final global = await repository.fetchGlobalPage(
      filter: filter,
      pageSize: pageSize,
    );
    final history = await repository.fetchPersonalHistory(filter: filter);
    return LeaderboardViewState(
      filter: filter,
      globalEntries: global.entries,
      personalHistory: history,
      nextCursor: global.nextCursor,
      availabilityMessage: global.availabilityMessage,
    );
  }

  static String _friendlyError(Object error) {
    if (error is AppFailure) {
      return error.message;
    }
    return 'No se pudo actualizar el leaderboard. Inténtalo de nuevo.';
  }
}

typedef LeaderboardErrorLogger = void Function(Object, StackTrace);

final leaderboardErrorLogProvider = Provider<LeaderboardErrorLogger>((ref) {
  return (error, stackTrace) {};
});
