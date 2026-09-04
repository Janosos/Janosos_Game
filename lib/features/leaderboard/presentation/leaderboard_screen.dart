import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/domain/character_definition.dart';
import '../../../game/domain/character_id.dart';
import '../../../game/domain/run_configuration.dart';
import '../application/leaderboard_controller.dart';
import '../domain/leaderboard_models.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(leaderboardControllerProvider);
    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _LoadFailure(
        onRetry: () => ref.invalidate(leaderboardControllerProvider),
      ),
      data: (state) => _LeaderboardContent(state: state),
    );
  }
}

class _LeaderboardContent extends ConsumerWidget {
  const _LeaderboardContent({required this.state});

  final LeaderboardViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(leaderboardControllerProvider.notifier);
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Leaderboard por personaje',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Compara resultados verificados o revisa tus últimas partidas.',
                ),
                const SizedBox(height: 16),
                _Filters(
                  filter: state.filter,
                  onCharacterChanged: controller.selectCharacter,
                  onModeChanged: controller.selectMode,
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _MessageBanner(
                    icon: Icons.sync_problem_outlined,
                    message: state.errorMessage!,
                  ),
                ],
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.public), text: 'Top global'),
              Tab(icon: Icon(Icons.history), text: 'Mi historial'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _GlobalList(
                  state: state,
                  onRefresh: controller.refresh,
                  onLoadMore: controller.loadMore,
                ),
                _HistoryList(
                  entries: state.personalHistory,
                  onRefresh: controller.refresh,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.filter,
    required this.onCharacterChanged,
    required this.onModeChanged,
  });

  final LeaderboardFilter filter;
  final ValueChanged<CharacterId> onCharacterChanged;
  final ValueChanged<RunMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 20,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<CharacterId>(
                key: ValueKey(filter.characterId),
                initialValue: filter.characterId,
                decoration: const InputDecoration(
                  labelText: 'Personaje',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final character in CharacterId.values)
                    DropdownMenuItem(
                      value: character,
                      child: Text(character.definition.displayName),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onCharacterChanged(value);
                  }
                },
              ),
            ),
            SegmentedButton<RunMode>(
              segments: const [
                ButtonSegment(
                  value: RunMode.progression,
                  icon: Icon(Icons.map_outlined),
                  label: Text('Progresión'),
                ),
                ButtonSegment(
                  value: RunMode.standard,
                  icon: Icon(Icons.speed_outlined),
                  label: Text('Estándar'),
                ),
                ButtonSegment(
                  value: RunMode.bossRush,
                  icon: Icon(Icons.whatshot_outlined),
                  label: Text('Boss Rush'),
                ),
              ],
              selected: {filter.mode},
              onSelectionChanged: (selection) {
                onModeChanged(selection.single);
              },
            ),
            Chip(
              avatar: const Icon(Icons.layers_outlined, size: 18),
              label: Text('Versión ${filter.contentVersion}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobalList extends StatelessWidget {
  const _GlobalList({
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
  });

  final LeaderboardViewState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.globalEntries.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            _EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'Todavía no hay resultados verificados',
              message:
                  state.availabilityMessage ??
                  'Sé la primera persona en completar una partida con este personaje.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        itemCount:
            state.globalEntries.length + (state.nextCursor == null ? 0 : 1),
        itemBuilder: (context, index) {
          if (index == state.globalEntries.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: FilledButton.tonalIcon(
                  onPressed: state.canLoadMore ? onLoadMore : null,
                  icon: state.isLoadingMore
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more),
                  label: const Text('Cargar 25 más'),
                ),
              ),
            );
          }
          return _LeaderboardCard(entry: state.globalEntries[index]);
        },
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final medal = switch (entry.position) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#${entry.position}',
    };
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: SizedBox(
          width: 48,
          child: Center(
            child: Text(medal, style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        title: Text(entry.displayName),
        subtitle: Text(
          '${entry.completed ? 'Completada' : 'Fallida'} · '
          'Nivel ${entry.levelReached}/10 · ${_formatDuration(entry.durationMs)}\n'
          '${_formatDate(entry.endedAt)} · ${entry.contentVersion}',
        ),
        isThreeLine: true,
        trailing: Semantics(
          label: '${entry.totalScore} puntos',
          child: Text(
            '${entry.totalScore}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.entries, required this.onRefresh});

  final List<RunHistoryEntry> entries;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            _EmptyState(
              icon: Icons.history_toggle_off_outlined,
              title: 'Sin partidas para este filtro',
              message:
                  'Tus resultados aparecerán aquí, incluidos los pendientes o rechazados.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        itemCount: entries.length,
        itemBuilder: (context, index) => _HistoryCard(entry: entries[index]),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final RunHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.validation) {
      ResultValidation.verified => Colors.green,
      ResultValidation.pending => Colors.orange,
      ResultValidation.limited => Colors.amber,
      ResultValidation.rejected => Colors.red,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${entry.outcome.label} · Nivel ${entry.levelReached}/10',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  side: BorderSide(color: color),
                  avatar: Icon(Icons.circle, size: 10, color: color),
                  label: Text(entry.validation.label),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${entry.totalScore} puntos · ${_formatDuration(entry.durationMs)} · '
              '${_formatDate(entry.endedAt)}',
            ),
            const SizedBox(height: 6),
            Text(
              entry.validation.explanation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (entry.isLocalOnly) ...[
              const SizedBox(height: 8),
              const Chip(
                avatar: Icon(Icons.phone_android_outlined, size: 18),
                label: Text('Sólo en este dispositivo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 56),
          child: Column(
            children: [
              Icon(icon, size: 64),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      leading: Icon(icon),
      content: Text(message),
      actions: const [SizedBox.shrink()],
    );
  }
}

class _LoadFailure extends ConsumerWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 64),
            const SizedBox(height: 16),
            const Text('No se pudo cargar el leaderboard.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  String two(int part) => part.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
