import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/app_providers.dart';
import '../../../app/widgets/character_sprite_preview.dart';
import '../../../app/widgets/retro_pixel_widgets.dart';
import '../../../game/domain/character_definition.dart';
import '../../auth/application/auth_controller.dart';
import '../application/leaderboard_controller.dart';
import '../domain/leaderboard_models.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestSessionProvider);
    if (isGuest) {
      return const _LeaderboardAuthRequiredView();
    }

    final asyncState = ref.watch(leaderboardControllerProvider);
    return asyncState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: RetroColors.cyan),
      ),
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
    final horizontalPadding = isCompactHeight ? 14.0 : 24.0;
    final isEndless = state.selectedCategory == LeaderboardCategory.endless;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      color: RetroColors.cyan,
      backgroundColor: const Color(0xFF0C1420),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isCompactHeight ? 10 : 20,
                horizontalPadding,
                isCompactHeight ? 8 : 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'RANKING ONLINE',
                      style: GoogleFonts.pressStart2p(
                        fontSize: isCompactHeight ? 12 : 16,
                        fontWeight: FontWeight.bold,
                        color: RetroColors.cyan,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: isCompactHeight ? 4 : 6),
                  Text(
                    'Los mejores récords globales en Modo Endless y Boss Rush.',
                    style: GoogleFonts.vt323(
                      fontSize: isCompactHeight ? 16 : 18,
                      color: RetroColors.textMuted,
                    ),
                  ),
                  SizedBox(height: isCompactHeight ? 10 : 16),
                  _CategorySelector(
                    selected: state.selectedCategory,
                    onSelected: controller.selectCategory,
                    isCompact: isCompactHeight,
                  ),
                ],
              ),
            ),
          ),
          if (isEndless)
            ..._buildEndlessSlivers(state.endlessEntries, horizontalPadding, isCompactHeight)
          else
            ..._buildBossRushSlivers(state.bossRushEntries, horizontalPadding, isCompactHeight),
        ],
      ),
    );
  }

  List<Widget> _buildEndlessSlivers(
    List<EndlessLeaderboardEntry> entries,
    double horizontalPadding,
    bool isCompact,
  ) {
    if (entries.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isCompact ? 20 : 36,
            ),
            child: const _EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'Sin récords en Modo Endless',
              message:
                  '¡Juega una partida en Modo Endless con tu cuenta iniciada para liderar el ranking!',
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: isCompact ? 8 : 14,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _EndlessCard(entry: entries[index]),
            childCount: entries.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildBossRushSlivers(
    List<BossRushLeaderboardEntry> entries,
    double horizontalPadding,
    bool isCompact,
  ) {
    if (entries.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isCompact ? 20 : 36,
            ),
            child: const _EmptyState(
              icon: Icons.military_tech_outlined,
              title: 'Sin victorias en Boss Rush todavía',
              message:
                  '¡Derrota a los 10 jefes consecutivos en Boss Rush para inscribir tu nombre en la gloria!',
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: isCompact ? 8 : 14,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _BossRushCard(entry: entries[index]),
            childCount: entries.length,
          ),
        ),
      ),
    ];
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selected,
    required this.onSelected,
    required this.isCompact,
  });

  final LeaderboardCategory selected;
  final ValueChanged<LeaderboardCategory> onSelected;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CategoryButton(
            title: 'MODO ENDLESS',
            icon: Icons.all_inclusive,
            isSelected: selected == LeaderboardCategory.endless,
            activeColor: RetroColors.cyan,
            onPressed: () => onSelected(LeaderboardCategory.endless),
            isCompact: isCompact,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CategoryButton(
            title: 'BOSS RUSH',
            icon: Icons.whatshot,
            isSelected: selected == LeaderboardCategory.bossRush,
            activeColor: RetroColors.magenta,
            onPressed: () => onSelected(LeaderboardCategory.bossRush),
            isCompact: isCompact,
          ),
        ),
      ],
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onPressed,
    required this.isCompact,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onPressed;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? activeColor : const Color(0xFF1E354F);
    final bgColor = isSelected
        ? activeColor.withValues(alpha: 0.15)
        : const Color(0xFF0C1420);

    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isCompact ? 8 : 12,
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isCompact ? 16 : 20,
              color: isSelected ? activeColor : RetroColors.textMuted,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.pressStart2p(
                  fontSize: isCompact ? 8.5 : 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? activeColor : RetroColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndlessCard extends StatelessWidget {
  const _EndlessCard({required this.entry});

  final EndlessLeaderboardEntry entry;

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
      padding: const EdgeInsets.only(bottom: 10),
      child: RetroArcadeCard(
        borderColor: borderColor,
        glow: isTop1,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Posición #
            SizedBox(
              width: 38,
              child: Center(
                child: isTop1
                    ? const PixelIconAsset(
                        assetName: PixelIconAsset.trophy,
                        size: 28,
                      )
                    : Text(
                        '#${entry.position}',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 11,
                          color: isTop3 ? RetroColors.cyan : Colors.white60,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),

            // Personaje avatar preview
            CharacterIcon(
              assetName: entry.characterId.definition.assetName,
              size: 36,
            ),
            const SizedBox(width: 12),

            // Jugador y Personaje utilizado
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        entry.characterId.definition.displayName.toUpperCase(),
                        style: GoogleFonts.pressStart2p(
                          fontSize: 7.5,
                          color: RetroColors.cyan,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.timer_outlined, size: 13, color: RetroColors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        _formatDuration(entry.durationMs),
                        style: GoogleFonts.vt323(
                          fontSize: 16,
                          color: RetroColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Puntuación
            Semantics(
              label: '${entry.score} puntos',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PixelIconAsset(
                    assetName: PixelIconAsset.coin,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.score}',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 12,
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

class _BossRushCard extends StatelessWidget {
  const _BossRushCard({required this.entry});

  final BossRushLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final isTop1 = entry.position == 1;
    final isTop3 = entry.position <= 3;
    final borderColor = isTop1
        ? RetroColors.gold
        : isTop3
            ? RetroColors.magenta
            : const Color(0xFF1E354F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RetroArcadeCard(
        borderColor: borderColor,
        glow: isTop1,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Posición #
            SizedBox(
              width: 38,
              child: Center(
                child: isTop1
                    ? const PixelIconAsset(
                        assetName: PixelIconAsset.trophy,
                        size: 28,
                      )
                    : Text(
                        '#${entry.position}',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 11,
                          color: isTop3 ? RetroColors.magenta : Colors.white60,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Nombre del jugador
            Expanded(
              child: Text(
                entry.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.pressStart2p(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Cantidad de veces completado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isTop1
                    ? RetroColors.gold.withValues(alpha: 0.2)
                    : const Color(0xFF1A1F2C),
                border: Border.all(
                  color: isTop1 ? RetroColors.gold : RetroColors.magenta,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 14,
                    color: isTop1 ? RetroColors.gold : RetroColors.magenta,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.completionsCount == 1
                        ? '1 VICTORIA'
                        : '${entry.completionsCount} VICTORIAS',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: isTop1 ? RetroColors.gold : RetroColors.magenta,
                      letterSpacing: 0.8,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: RetroColors.textMuted),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.pressStart2p(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: RetroColors.cyan,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.vt323(
              fontSize: 17,
              color: RetroColors.textMuted,
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

class _LeaderboardAuthRequiredView extends ConsumerWidget {
  const _LeaderboardAuthRequiredView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.sizeOf(context);
    final isCompactHeight = media.height < 520;
    final auth = ref.watch(authControllerProvider);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isCompactHeight ? 16 : 24,
          vertical: isCompactHeight ? 12 : 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: RetroArcadeCard(
            borderColor: RetroColors.cyan,
            glow: true,
            padding: EdgeInsets.all(isCompactHeight ? 18 : 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PixelIconAsset(
                  assetName: PixelIconAsset.trophy,
                  size: isCompactHeight ? 40 : 54,
                ),
                SizedBox(height: isCompactHeight ? 12 : 18),
                Text(
                  'INICIO DE SESIÓN REQUERIDO',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.pressStart2p(
                    fontSize: isCompactHeight ? 10.5 : 12.5,
                    fontWeight: FontWeight.bold,
                    color: RetroColors.cyan,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: isCompactHeight ? 10 : 16),
                Text(
                  'Para ver las puntuaciones y rankings/leaderboards se requiere inicio de sesión.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vt323(
                    fontSize: isCompactHeight ? 18 : 20,
                    color: RetroColors.textBright,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: isCompactHeight ? 6 : 10),
                Text(
                  'Inicia sesión con tu cuenta para desbloquear los rankings mundiales de Modo Endless y Boss Rush, y registrar tus marcas.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vt323(
                    fontSize: isCompactHeight ? 15 : 17,
                    color: RetroColors.textMuted,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: isCompactHeight ? 18 : 26),
                RetroArcadeButton(
                  text: 'INICIAR SESIÓN',
                  icon: Icons.login,
                  primaryColor: RetroColors.cyan,
                  fontSize: isCompactHeight ? 8.5 : 9.5,
                  isFullWidth: true,
                  onPressed: auth.isBusy
                      ? null
                      : () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .signOut();
                          if (context.mounted) {
                            context.go('/auth');
                          }
                        },
                ),
                SizedBox(height: isCompactHeight ? 8 : 12),
                RetroArcadeButton(
                  text: 'VOLVER AL INICIO',
                  icon: Icons.home_outlined,
                  primaryColor: RetroColors.textMuted,
                  fontSize: isCompactHeight ? 8 : 9,
                  isFullWidth: true,
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
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
