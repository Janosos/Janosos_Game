import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/widgets/retro_pixel_widgets.dart';
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
    final media = MediaQuery.sizeOf(context);
    final isCompactHeight = media.height < 520;

    final tabBar = TabBar(
      indicatorColor: RetroColors.cyan,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: GoogleFonts.pressStart2p(
        fontSize: isCompactHeight ? 8 : 9,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: GoogleFonts.pressStart2p(
        fontSize: isCompactHeight ? 8 : 9,
      ),
      labelColor: RetroColors.cyan,
      unselectedLabelColor: RetroColors.textMuted,
      tabs: [
        Tab(
          height: isCompactHeight ? 38 : 46,
          icon: PixelIconAsset(
            assetName: PixelIconAsset.trophy,
            size: isCompactHeight ? 16 : 20,
          ),
          text: 'Top global',
        ),
        Tab(
          height: isCompactHeight ? 38 : 46,
          icon: PixelIconAsset(
            assetName: PixelIconAsset.coin,
            size: isCompactHeight ? 16 : 20,
          ),
          text: 'Mi historial',
        ),
      ],
    );

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isCompactHeight ? 14 : 24,
                isCompactHeight ? 8 : 20,
                isCompactHeight ? 14 : 24,
                isCompactHeight ? 6 : 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Leaderboard por personaje',
                      style: isCompactHeight
                          ? Theme.of(context).textTheme.titleLarge
                          : Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  SizedBox(height: isCompactHeight ? 2 : 6),
                  Text(
                    'Compara resultados verificados o revisa tus últimas partidas.',
                    style: TextStyle(
                      fontSize: isCompactHeight ? 12 : 14,
                      color: RetroColors.textMuted,
                    ),
                  ),
                  SizedBox(height: isCompactHeight ? 8 : 14),
                  _Filters(
                    filter: state.filter,
                    onCharacterChanged: controller.selectCharacter,
                    onModeChanged: controller.selectMode,
                    isCompact: isCompactHeight,
                  ),
                  if (state.errorMessage != null) ...[
                    SizedBox(height: isCompactHeight ? 6 : 12),
                    _MessageBanner(
                      icon: Icons.sync_problem_outlined,
                      message: state.errorMessage!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _LeaderboardTabBarDelegate(tabBar),
          ),
        ],
        body: TabBarView(
          children: [
            _GlobalList(
              state: state,
              onRefresh: controller.refresh,
              onLoadMore: controller.loadMore,
              isCompact: isCompactHeight,
            ),
            _HistoryList(
              entries: state.personalHistory,
              onRefresh: controller.refresh,
              isCompact: isCompactHeight,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTabBarDelegate extends SliverPersistentHeaderDelegate {
  _LeaderboardTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF070D16),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E354F), width: 1.5),
        ),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_LeaderboardTabBarDelegate oldDelegate) => false;
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.filter,
    required this.onCharacterChanged,
    required this.onModeChanged,
    this.isCompact = false,
  });

  final LeaderboardFilter filter;
  final ValueChanged<CharacterId> onCharacterChanged;
  final ValueChanged<RunMode> onModeChanged;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return RetroArcadeCard(
      borderColor: const Color(0xFF1E354F),
      backgroundColor: const Color(0xFF0C1420),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 16,
        vertical: isCompact ? 6 : 12,
      ),
      child: Wrap(
        spacing: isCompact ? 10 : 16,
        runSpacing: isCompact ? 6 : 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: isCompact ? 190 : 230,
            child: DropdownButtonFormField<CharacterId>(
              key: ValueKey(filter.characterId),
              initialValue: filter.characterId,
              isDense: true,
              decoration: InputDecoration(
                labelText: 'Personaje',
                prefixIcon: const Icon(Icons.person_outline, size: 18),
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: isCompact ? 8 : 12,
                ),
              ),
              items: [
                for (final character in CharacterId.values)
                  DropdownMenuItem(
                    value: character,
                    child: Text(
                      character.definition.displayName,
                      style: GoogleFonts.vt323(fontSize: 18),
                    ),
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
            style: SegmentedButton.styleFrom(
              visualDensity: isCompact ? VisualDensity.compact : VisualDensity.standard,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 6 : 12,
                vertical: isCompact ? 4 : 8,
              ),
            ),
            segments: const [
              ButtonSegment(
                value: RunMode.progression,
                icon: Icon(Icons.map_outlined, size: 16),
                label: Text('Progresión'),
              ),
              ButtonSegment(
                value: RunMode.standard,
                icon: Icon(Icons.speed_outlined, size: 16),
                label: Text('Estándar'),
              ),
              ButtonSegment(
                value: RunMode.bossRush,
                icon: Icon(Icons.whatshot_outlined, size: 16),
                label: Text('Boss Rush'),
              ),
            ],
            selected: {filter.mode},
            onSelectionChanged: (selection) {
              onModeChanged(selection.single);
            },
          ),
          Chip(
            visualDensity: isCompact ? VisualDensity.compact : VisualDensity.standard,
            backgroundColor: const Color(0xFF132032),
            side: const BorderSide(color: Color(0xFF1E354F)),
            avatar: const Icon(Icons.layers_outlined, size: 16, color: RetroColors.cyan),
            label: Text(
              'Versión ${filter.contentVersion}',
              style: GoogleFonts.vt323(fontSize: 15, color: RetroColors.textBright),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalList extends StatelessWidget {
  const _GlobalList({
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    this.isCompact = false,
  });

  final LeaderboardViewState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final listPadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 14 : 24,
      vertical: isCompact ? 10 : 20,
    );

    if (state.globalEntries.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: listPadding,
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
        padding: listPadding,
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
    final isTop1 = entry.position == 1;
    final isTop3 = entry.position <= 3;
    final borderColor = isTop1
        ? RetroColors.gold
        : isTop3
        ? RetroColors.cyan
        : const Color(0xFF1E354F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RetroArcadeCard(
        borderColor: borderColor,
        glow: isTop1,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Center(
                child: isTop1
                    ? const PixelIconAsset(
                        assetName: PixelIconAsset.trophy,
                        size: 32,
                      )
                    : Text(
                        '#${entry.position}',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 12,
                          color: isTop3 ? RetroColors.cyan : Colors.white60,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayName,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${entry.completed ? 'Completada' : 'Fallida'} · '
                    'Nivel ${entry.levelReached}/10 · ${_formatDuration(entry.durationMs)}\n'
                    '${_formatDate(entry.endedAt)} · ${entry.contentVersion}',
                    style: GoogleFonts.vt323(
                      fontSize: 16,
                      color: RetroColors.textMuted,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              label: '${entry.totalScore} puntos',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PixelIconAsset(
                    assetName: PixelIconAsset.coin,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.totalScore}',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: RetroColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.entries,
    required this.onRefresh,
    this.isCompact = false,
  });

  final List<RunHistoryEntry> entries;
  final Future<void> Function() onRefresh;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final listPadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 14 : 24,
      vertical: isCompact ? 10 : 20,
    );

    if (entries.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: listPadding,
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
        padding: listPadding,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF160B11),
        border: Border.all(color: RetroColors.magenta, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, offset: Offset(2, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: RetroColors.magenta),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.vt323(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
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
