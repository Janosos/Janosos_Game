import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/widgets/character_sprite_preview.dart';
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

class _LeaderboardContent extends ConsumerStatefulWidget {
  const _LeaderboardContent({required this.state});

  final LeaderboardViewState state;

  @override
  ConsumerState<_LeaderboardContent> createState() => _LeaderboardContentState();
}

class _LeaderboardContentState extends ConsumerState<_LeaderboardContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = ref.read(leaderboardControllerProvider.notifier);
    final media = MediaQuery.sizeOf(context);
    final isCompactHeight = media.height < 520;
    final isGlobalTab = _tabController.index == 0;

    return DefaultTabController(
      length: 2,
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        color: RetroColors.cyan,
        backgroundColor: const Color(0xFF0C1420),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isCompactHeight ? 14 : 24,
                  isCompactHeight ? 8 : 18,
                  isCompactHeight ? 14 : 24,
                  isCompactHeight ? 6 : 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'LEADERBOARD POR PERSONAJE',
                        style: GoogleFonts.pressStart2p(
                          fontSize: isCompactHeight ? 12 : 15,
                          fontWeight: FontWeight.bold,
                          color: RetroColors.cyan,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: isCompactHeight ? 2 : 4),
                    Text(
                      'Compara resultados verificados o revisa tus últimas partidas.',
                      style: GoogleFonts.vt323(
                        fontSize: isCompactHeight ? 15 : 17,
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
                      SizedBox(height: isCompactHeight ? 6 : 10),
                      _MessageBanner(
                        icon: Icons.sync_problem_outlined,
                        message: state.errorMessage!,
                      ),
                    ],
                    if (state.availabilityMessage != null &&
                        state.errorMessage == null) ...[
                      SizedBox(height: isCompactHeight ? 6 : 10),
                      _InfoBanner(
                        icon: Icons.info_outline,
                        message: state.availabilityMessage!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _LeaderboardTabBarDelegate(
                tabBar: TabBar(
                  controller: _tabController,
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
                  tabs: const [
                    Tab(
                      icon: PixelIconAsset(
                        assetName: PixelIconAsset.trophy,
                        size: 18,
                      ),
                      text: 'Top global',
                    ),
                    Tab(
                      icon: PixelIconAsset(
                        assetName: PixelIconAsset.coin,
                        size: 18,
                      ),
                      text: 'Mi historial',
                    ),
                  ],
                ),
                height: isCompactHeight ? 56 : 64,
              ),
            ),
            if (isGlobalTab)
              ..._buildGlobalSlivers(
                context,
                state,
                controller,
                isCompactHeight,
              )
            else
              ..._buildHistorySlivers(context, state, isCompactHeight),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGlobalSlivers(
    BuildContext context,
    LeaderboardViewState state,
    LeaderboardController controller,
    bool isCompact,
  ) {
    final horizontalPadding = isCompact ? 14.0 : 24.0;
    if (state.globalEntries.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isCompact ? 16 : 28,
            ),
            child: _EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'Todavía no hay resultados verificados',
              message: state.availabilityMessage ??
                  'Sé la primera persona en completar una partida con este personaje.',
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: isCompact ? 10 : 16,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == state.globalEntries.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: FilledButton.tonalIcon(
                      onPressed: state.canLoadMore ? controller.loadMore : null,
                      icon: state.isLoadingMore
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: RetroColors.cyan,
                              ),
                            )
                          : const Icon(Icons.expand_more),
                      label: const Text('Cargar 25 más'),
                    ),
                  ),
                );
              }
              return _LeaderboardCard(entry: state.globalEntries[index]);
            },
            childCount:
                state.globalEntries.length + (state.nextCursor == null ? 0 : 1),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildHistorySlivers(
    BuildContext context,
    LeaderboardViewState state,
    bool isCompact,
  ) {
    final horizontalPadding = isCompact ? 14.0 : 24.0;
    if (state.personalHistory.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isCompact ? 16 : 28,
            ),
            child: const _EmptyState(
              icon: Icons.history_toggle_off_outlined,
              title: 'Sin partidas para este filtro',
              message:
                  'Tus resultados aparecerán aquí, incluidos los pendientes o rechazados.',
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: isCompact ? 10 : 16,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                _HistoryCard(entry: state.personalHistory[index]),
            childCount: state.personalHistory.length,
          ),
        ),
      ),
    ];
  }
}

class _LeaderboardTabBarDelegate extends SliverPersistentHeaderDelegate {
  _LeaderboardTabBarDelegate({
    required this.tabBar,
    required this.height,
  });

  final Widget tabBar;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFF070D16),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E354F), width: 1.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _LeaderboardTabBarDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.tabBar != tabBar;
  }
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
            width: isCompact ? 200 : 250,
            child: DropdownButtonFormField<CharacterId>(
              key: ValueKey(filter.characterId),
              initialValue: filter.characterId,
              isDense: true,
              dropdownColor: const Color(0xFF0F1724),
              decoration: InputDecoration(
                labelText: 'Personaje',
                labelStyle: GoogleFonts.vt323(fontSize: 16, color: RetroColors.cyan),
                prefixIcon: const Icon(Icons.person_outline, size: 18, color: RetroColors.cyan),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CharacterIcon(
                          assetName: character.definition.assetName,
                          size: isCompact ? 20 : 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          character.definition.displayName.toUpperCase(),
                          style: GoogleFonts.pressStart2p(
                            fontSize: isCompact ? 7.5 : 8.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C1929),
        border: Border.all(color: RetroColors.cyan, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, offset: Offset(2, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: RetroColors.cyan),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.vt323(fontSize: 16, color: RetroColors.textBright),
            ),
          ),
        ],
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
      ResultValidation.verified => RetroColors.green,
      ResultValidation.pending => RetroColors.gold,
      ResultValidation.limited => Colors.amber,
      ResultValidation.rejected => RetroColors.magenta,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RetroArcadeCard(
        borderColor: color.withValues(alpha: 0.7),
        accentHeaderColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${entry.outcome.label.toUpperCase()} · NIVEL ${entry.levelReached}/10',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                RetroBadge(
                  text: entry.validation.label,
                  color: color,
                  fontSize: 7.5,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const PixelIconAsset(assetName: PixelIconAsset.coin, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${entry.totalScore} PTS',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: RetroColors.gold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '· ${_formatDuration(entry.durationMs)} · ${_formatDate(entry.endedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.vt323(
                      fontSize: 16,
                      color: RetroColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              entry.validation.explanation,
              style: GoogleFonts.vt323(
                fontSize: 15,
                color: RetroColors.textBright,
                height: 1.15,
              ),
            ),
            if (entry.isLocalOnly) ...[
              const SizedBox(height: 8),
              const RetroBadge(
                text: 'SÓLO EN ESTE DISPOSITIVO',
                color: RetroColors.cyan,
                fontSize: 7,
                icon: Icon(
                  Icons.phone_android_outlined,
                  size: 11,
                  color: RetroColors.cyan,
                ),
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
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(icon, size: 52, color: RetroColors.textMuted),
              const SizedBox(height: 14),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.pressStart2p(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.vt323(
                  fontSize: 16,
                  color: RetroColors.textMuted,
                ),
              ),
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
            const Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: RetroColors.magenta,
            ),
            const SizedBox(height: 16),
            Text(
              'NO SE PUDO CARGAR EL LEADERBOARD',
              textAlign: TextAlign.center,
              style: GoogleFonts.pressStart2p(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: RetroColors.magenta,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            RetroArcadeButton(
              text: 'REINTENTAR',
              icon: Icons.refresh,
              primaryColor: RetroColors.cyan,
              fontSize: 8,
              onPressed: onRetry,
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
