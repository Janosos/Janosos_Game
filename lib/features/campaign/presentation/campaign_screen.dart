import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/app_providers.dart';
import '../../../app/widgets/character_sprite_preview.dart';
import '../../../app/widgets/retro_pixel_widgets.dart';
import '../../../game/domain/character_definition.dart';
import '../../../game/domain/character_id.dart';
import '../../leaderboard/application/leaderboard_controller.dart';
import '../domain/campaign_content.dart';
import '../domain/campaign_repository.dart';

class CampaignScreen extends ConsumerStatefulWidget {
  const CampaignScreen({super.key});

  @override
  ConsumerState<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends ConsumerState<CampaignScreen> {
  CharacterId _selectedCharacter = CharacterId.jano;
  String? _syncMessage;
  late Future<CampaignProgress?> _progress;
  late Future<bool> _bossRushUnlocked;

  @override
  void initState() {
    super.initState();
    _progress = _loadProgress();
    _bossRushUnlocked = _loadBossRushEntitlement(_selectedCharacter);
    Future<void>.microtask(_synchronizePending);
  }

  Future<CampaignProgress?> _loadProgress() =>
      ref.read(campaignRepositoryProvider).loadActiveCampaign();

  int _getHighestUnlockedLevel(
    CharacterId character,
    CampaignProgress? progress,
  ) {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final characterUnlocked =
          prefs.getInt('campaign_max_unlocked_level_${character.serialized}') ??
          1;
      final globalUnlocked = prefs.getInt('campaign_max_unlocked_level') ?? 1;
      final activeLevel = progress?.currentLevel ?? 1;
      return max(
        max(characterUnlocked, globalUnlocked),
        activeLevel,
      ).clamp(1, 10);
    } catch (_) {
      return (progress?.currentLevel ?? 1).clamp(1, 10);
    }
  }

  bool _isCampaignCompleted(CharacterId character) {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      return (prefs.getBool('campaign_completed_${character.serialized}') ??
              false) ||
          (prefs.getBool('campaign_completed') ?? false);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _loadBossRushEntitlement(CharacterId character) async {
    final environment = ref.read(appEnvironmentProvider);
    final snapshot = await ref
        .read(progressionRepositoryProvider)
        .loadSnapshot(
          characterId: character,
          contentVersion: environment.contentVersion,
        );
    return snapshot.storeUnlocked;
  }

  Future<void> _synchronizePending() async {
    try {
      final campaignCount = await ref
          .read(campaignResultCoordinatorProvider)
          .synchronizePending();
      final bossRushCount = await ref
          .read(bossRushCoordinatorProvider)
          .synchronizePending();
      final count = campaignCount + bossRushCount;
      if (!mounted || count == 0) return;
      ref.invalidate(leaderboardControllerProvider);
      setState(() {
        _syncMessage = count == 1
            ? 'Se sincronizó 1 resultado pendiente.'
            : 'Se sincronizaron $count resultados pendientes.';
        _progress = _loadProgress();
        _bossRushUnlocked = _loadBossRushEntitlement(_selectedCharacter);
      });
    } on Object {
      // Offline or unavailable protected storage is an expected practice state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CampaignProgress?>(
      future: _progress,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildMap(context, snapshot.data);
      },
    );
  }

  Widget _buildMap(BuildContext context, CampaignProgress? progress) {
    final selectedCharacter = progress?.characterId ?? _selectedCharacter;
    final highestUnlocked = _getHighestUnlockedLevel(
      selectedCharacter,
      progress,
    );
    final campaignCompleted = _isCampaignCompleted(selectedCharacter);
    final isCompactHeight = MediaQuery.sizeOf(context).height < 500;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isCompactHeight ? 14 : 24,
            isCompactHeight ? 10 : 20,
            isCompactHeight ? 14 : 24,
            isCompactHeight ? 8 : 12,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'PROGRESIÓN MUNDIAL',
                    style: GoogleFonts.pressStart2p(
                      fontSize: isCompactHeight ? 12 : 15,
                      fontWeight: FontWeight.bold,
                      color: RetroColors.cyan,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Supera los 10 niveles y derrota a cada jefe para conquistar el arcade.',
                  style: GoogleFonts.vt323(
                    fontSize: isCompactHeight ? 15 : 17,
                    color: RetroColors.textMuted,
                  ),
                ),
                SizedBox(height: isCompactHeight ? 8 : 14),
                _CampaignNotice(progress: progress),
                SizedBox(height: isCompactHeight ? 8 : 12),
                FutureBuilder<bool>(
                  future: _bossRushUnlocked,
                  builder: (context, entitlement) => _BossRushCard(
                    unlocked: entitlement.data ?? false,
                    hasActiveCampaign: progress != null,
                    selectedCharacter: selectedCharacter,
                  ),
                ),
                if (_syncMessage != null) ...[
                  SizedBox(height: isCompactHeight ? 6 : 12),
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C1929),
                        border: Border.all(
                          color: RetroColors.cyan,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _syncMessage!,
                        style: GoogleFonts.vt323(
                          fontSize: 15,
                          color: RetroColors.cyan,
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: isCompactHeight ? 10 : 16),
                Semantics(
                  label: 'Personaje seleccionado para la campaña',
                  child: RetroArcadeCard(
                    borderColor: const Color(0xFF1E354F),
                    backgroundColor: const Color(0xFF0C1420),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: isCompactHeight ? 6 : 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sports_esports_outlined,
                          size: isCompactHeight ? 18 : 22,
                          color: RetroColors.cyan,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<CharacterId>(
                              value: selectedCharacter,
                              dropdownColor: const Color(0xFF0F1724),
                              isDense: true,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: RetroColors.cyan,
                              ),
                              items: [
                                for (final character in CharacterId.values)
                                  DropdownMenuItem(
                                    value: character,
                                    child: Row(
                                      children: [
                                        CharacterIcon(
                                          assetName:
                                              character.definition.assetName,
                                          size: isCompactHeight ? 20 : 24,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            character.definition.displayName
                                                .toUpperCase(),
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.pressStart2p(
                                              fontSize:
                                                  isCompactHeight ? 8 : 9,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                              onChanged: progress == null
                                  ? (character) {
                                      if (character != null) {
                                        setState(() {
                                          _selectedCharacter = character;
                                          _bossRushUnlocked =
                                              _loadBossRushEntitlement(
                                                character,
                                              );
                                        });
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        ),
                        if (progress != null) ...[
                          const SizedBox(width: 8),
                          const RetroBadge(
                            text: 'EN CURSO',
                            color: RetroColors.gold,
                            fontSize: 7,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isCompactHeight ? 14 : 24,
            8,
            isCompactHeight ? 14 : 24,
            24,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 430,
              mainAxisExtent: isCompactHeight ? 205 : 220,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: initialCampaignLevels.length,
            itemBuilder: (context, index) {
              final level = initialCampaignLevels[index];
              final isCompleted =
                  level.level < highestUnlocked ||
                  (level.level == 10 && campaignCompleted);
              final isAvailable =
                  level.level == highestUnlocked && !isCompleted;
              return _LevelCard(
                level: level,
                available: isAvailable,
                completed: isCompleted,
                selectedCharacter: selectedCharacter,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BossRushCard extends StatelessWidget {
  const _BossRushCard({
    required this.unlocked,
    required this.hasActiveCampaign,
    required this.selectedCharacter,
  });

  final bool unlocked;
  final bool hasActiveCampaign;
  final CharacterId selectedCharacter;

  @override
  Widget build(BuildContext context) {
    final description = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.local_fire_department, color: RetroColors.magenta),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MODO BOSS RUSH',
                style: GoogleFonts.pressStart2p(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: RetroColors.magenta,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Encadena los diez jefes consecutivos con una sola vida recuperable. '
                '${hasActiveCampaign
                    ? 'Termina primero la campaña activa.'
                    : unlocked
                    ? 'Modo desbloqueado para este personaje.'
                    : 'Requiere haber completado la campaña.'}',
                style: GoogleFonts.vt323(
                  fontSize: 16,
                  color: RetroColors.textBright,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final button = RetroArcadeButton(
      text: 'BOSS RUSH',
      fontSize: 9,
      primaryColor: RetroColors.magenta,
      icon: Icons.whatshot,
      onPressed: unlocked && !hasActiveCampaign
          ? () => context.go(
              '/game?experience=boss_rush&character=${selectedCharacter.serialized}',
            )
          : null,
    );

    final isCompactHeight = MediaQuery.sizeOf(context).height < 500;
    return RetroArcadeCard(
      borderColor: RetroColors.magenta.withValues(alpha: 0.8),
      backgroundColor: const Color(0xFF140B16),
      padding: EdgeInsets.symmetric(
        horizontal: isCompactHeight ? 12 : 16,
        vertical: isCompactHeight ? 8 : 16,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [description, const SizedBox(height: 12), button],
            );
          }
          return Row(
            children: [
              Expanded(child: description),
              const SizedBox(width: 16),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _CampaignNotice extends StatelessWidget {
  const _CampaignNotice({required this.progress});

  final CampaignProgress? progress;

  @override
  Widget build(BuildContext context) {
    return RetroArcadeCard(
      borderColor: progress == null
          ? const Color(0xFF1E354F)
          : RetroColors.gold,
      backgroundColor: const Color(0xFF0F1722),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PixelIconAsset(
            assetName: progress == null
                ? PixelIconAsset.gamepad
                : PixelIconAsset.coin,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              progress == null
                  ? 'Comienza en el nivel 1. Cada victoria desbloquea la siguiente etapa.'
                  : 'Campaña en curso · Nivel ${progress!.currentLevel}/10.',
              style: GoogleFonts.vt323(
                fontSize: 17,
                color: RetroColors.textBright,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.available,
    required this.completed,
    required this.selectedCharacter,
  });

  final CampaignLevelDefinition level;
  final bool available;
  final bool completed;
  final CharacterId selectedCharacter;

  @override
  Widget build(BuildContext context) {
    final borderColor = completed
        ? RetroColors.green.withValues(alpha: 0.6)
        : available
        ? RetroColors.cyan
        : const Color(0xFF1E354F);

    return RetroArcadeCard(
      borderColor: borderColor,
      accentHeaderColor: available
          ? RetroColors.cyan
          : completed
          ? RetroColors.green
          : null,
      glow: available,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RetroBadge(
                text: completed
                    ? 'LVL ${level.level} · COMPLETADO'
                    : 'LVL ${level.level}',
                color: completed
                    ? RetroColors.green
                    : available
                    ? RetroColors.cyan
                    : Colors.white54,
                fontSize: 8,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  level.scenario.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(
                completed
                    ? Icons.check_circle
                    : available
                    ? Icons.lock_open
                    : Icons.lock,
                color: completed
                    ? RetroColors.green
                    : available
                    ? RetroColors.cyan
                    : Colors.white38,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'JEFE',
            style: GoogleFonts.pressStart2p(
              fontSize: 8,
              color: RetroColors.magenta,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            level.boss,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            level.mechanic,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.vt323(
              fontSize: 15,
              color: RetroColors.textMuted,
              height: 1.15,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const PixelIconAsset(assetName: PixelIconAsset.coin, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${level.uniqueReward} · 1%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.vt323(
                    fontSize: 15,
                    color: RetroColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: RetroArcadeButton(
              text: completed
                  ? 'VOLVER A JUGAR'
                  : available
                  ? 'JUGAR NIVEL ${level.level}'
                  : 'BLOQUEADO',
              icon: completed
                  ? Icons.replay
                  : available
                  ? Icons.play_arrow
                  : null,
              fontSize: 8,
              primaryColor: completed
                  ? RetroColors.green
                  : available
                  ? RetroColors.cyan
                  : Colors.grey.shade800,
              textColor: completed || available ? Colors.black : Colors.white38,
              onPressed: completed || available
                  ? () => context.go(
                      '/game?experience=campaign&character=${selectedCharacter.serialized}&level=${level.level}',
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
