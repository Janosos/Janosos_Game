import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/app_providers.dart';
import '../../features/campaign/domain/campaign_repository.dart';
import '../../features/boss_rush/domain/boss_rush_repository.dart';
import '../../features/leaderboard/application/leaderboard_controller.dart';
import '../../features/progression/application/progression_controller.dart';
import '../../features/progression/data/local_progression_repository.dart';
import '../../features/progression/domain/progression_build_policy.dart';
import '../../features/progression/domain/progression_catalog.dart';
import '../../features/progression/domain/progression_models.dart';
import '../../features/settings/application/game_settings_controller.dart';
import '../../features/settings/application/hud_settings_controller.dart';
import '../domain/character_definition.dart';
import '../domain/character_id.dart';
import '../domain/run_configuration.dart';
import '../domain/run_result.dart';
import 'dino_run_app.dart';

class GameRouteScreen extends ConsumerStatefulWidget {
  const GameRouteScreen({
    this.campaignCharacter,
    this.bossRushCharacter,
    this.campaignLevel = 1,
    super.key,
  });

  final CharacterId? campaignCharacter;
  final CharacterId? bossRushCharacter;
  final int campaignLevel;

  @override
  ConsumerState<GameRouteScreen> createState() => _GameRouteScreenState();
}

class _GameRouteScreenState extends ConsumerState<GameRouteScreen> {
  Future<CampaignStageSession>? _campaignPreflight;
  Future<BossRushSession>? _bossRushPreflight;

  @override
  void initState() {
    super.initState();
    if (widget.campaignCharacter != null) {
      _campaignPreflight = _prepareCampaign(
        widget.campaignCharacter!,
        widget.campaignLevel,
      );
    }
    if (widget.bossRushCharacter != null) {
      _bossRushPreflight = ref
          .read(bossRushCoordinatorProvider)
          .prepare(widget.bossRushCharacter!);
    }
  }

  @override
  void didUpdateWidget(covariant GameRouteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campaignCharacter != widget.campaignCharacter ||
        oldWidget.campaignLevel != widget.campaignLevel) {
      _campaignPreflight = widget.campaignCharacter == null
          ? null
          : _prepareCampaign(widget.campaignCharacter!, widget.campaignLevel);
    }
    if (oldWidget.bossRushCharacter != widget.bossRushCharacter) {
      _bossRushPreflight = widget.bossRushCharacter == null
          ? null
          : ref
                .read(bossRushCoordinatorProvider)
                .prepare(widget.bossRushCharacter!);
    }
  }

  Future<CampaignStageSession> _prepareCampaign(
    CharacterId character,
    int level,
  ) async {
    final coordinator = ref.read(campaignStageCoordinatorProvider);
    final session = await coordinator.prepareStage(
      character,
      requestedLevel: level,
    );
    await coordinator.markPlaying(session);
    return session;
  }

  @override
  Widget build(BuildContext context) {
    final bossRush = _bossRushPreflight;
    if (bossRush != null) {
      return FutureBuilder<BossRushSession>(
        future: bossRush,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _PreflightFailure(
              onRetry: () {
                setState(() {
                  _bossRushPreflight = ref
                      .read(bossRushCoordinatorProvider)
                      .prepare(widget.bossRushCharacter!);
                });
              },
            );
          }
          final session = snapshot.data;
          if (session == null) return const _PreflightLoading();
          return _buildBossRush(context, session);
        },
      );
    }
    final campaign = _campaignPreflight;
    if (campaign == null) return _buildStandard(context);
    return FutureBuilder<CampaignStageSession>(
      future: campaign,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _PreflightFailure(
            onRetry: () {
              setState(() {
                _campaignPreflight = _prepareCampaign(
                  widget.campaignCharacter!,
                  widget.campaignLevel,
                );
              });
            },
          );
        }
        final session = snapshot.data;
        if (session == null) return const _PreflightLoading();
        return _buildCampaign(context, session);
      },
    );
  }

  Widget _buildBossRush(BuildContext context, BossRushSession session) {
    final preferences = ref.watch(sharedPreferencesProvider);
    final coordinator = ref.watch(bossRushCoordinatorProvider);
    final legacyHighScore = preferences.getInt('high_score') ?? 0;
    final configuration = _withGameSettings(context, session.configuration);
    return Scaffold(
      body: Stack(
        children: [
          DinoRunApp(
            initialHighScore: legacyHighScore,
            audioEnabled: configuration.audioEnabled,
            musicEnabled: configuration.musicEnabled,
            sfxEnabled: configuration.sfxEnabled,
            hudSettings: ref.watch(hudSettingsControllerProvider),
            configurationForCharacter: (_) => configuration,
            onRunFinished: (result) async {
              final message = await coordinator.sealAndSynchronize(
                session,
                result,
              );
              ref.invalidate(progressionControllerProvider);
              ref.invalidate(leaderboardControllerProvider);
              return message;
            },
            onCampaignExit: () => context.go('/campaign'),
          ),
          _RetroBackButton(onPressed: () => _confirmBossRushExit(context, session)),
          const _RetroAudioToggleButton(),
          _RunBanner(
            label: switch (session.eligibility) {
              BossRushEligibility.practice => 'BOSS RUSH · PRÁCTICA',
              _ => 'BOSS RUSH · 10 JEFES',
            },
            topMargin: 56,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBossRushExit(
    BuildContext context,
    BossRushSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Terminar Boss Rush?'),
        content: const Text(
          '¿Deseas volver al menú de campaña?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('SEGUIR JUGANDO'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('TERMINAR'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(bossRushCoordinatorProvider).abandon(session);
    if (context.mounted) context.go('/campaign');
  }

  Widget _buildStandard(BuildContext context) {
    final preferences = ref.watch(sharedPreferencesProvider);
    final environment = ref.watch(appEnvironmentProvider);
    final recorder = ref.watch(runResultRecorderProvider);
    final legacyHighScore = preferences.getInt('high_score') ?? 0;
    final gameSettings = ref.watch(gameSettingsControllerProvider);
    final reduceMotion =
        gameSettings.reduceMotion || MediaQuery.disableAnimationsOf(context);
    final localStore = ref.watch(localGameStateStoreProvider);
    return Scaffold(
      body: Stack(
        children: [
          DinoRunApp(
            initialHighScore: legacyHighScore,
            audioEnabled: gameSettings.audioEnabled,
            musicEnabled: gameSettings.musicEnabled,
            sfxEnabled: gameSettings.sfxEnabled,
            hudSettings: ref.watch(hudSettingsControllerProvider),
            onHighScoreChanged: (score) =>
                preferences.setInt('high_score', score),
            configurationForCharacter: (CharacterId characterId) {
              final definition = characterId.definition;
              final state = localStore.currentState;
              final progress = state.character(characterId);
              final speedBp = localEffectiveBasisPoints(progress, 'speed');
              final vitalityRank =
                  (progress.statRanks['vitality'] ?? 0).clamp(0, 3);
              final fortuneBp = localEffectiveBasisPoints(progress, 'fortune');
              final build = AuthorizedBuild(
                speedBasisPoints: speedBp,
                jumpBasisPoints: 0,
                damageBasisPoints: 0,
                vitalityBasisPoints: vitalityRank * 1000,
                fortuneBasisPoints: fortuneBp,
                maxLives: definition.baseLives + vitalityRank,
                activeSkillId: progress.activeSkillId,
                defaultActiveId: definition.defaultActive?.name,
                passiveSkillIds: progress.passiveSkillIds,
                skinId: progress.equippedPaletteId,
              );
              final stats = ProgressionBuildPolicy.statsFor(
                characterId: characterId,
                mode: RunMode.standard,
                build: build,
              );
              final equippedPalette = ProgressionCatalog.preview(
                characterId,
                environment.contentVersion,
              ).palettes
                  .where((candidate) => candidate.id == progress.equippedPaletteId)
                  .map((candidate) => candidate.transform)
                  .firstOrNull;
              return RunConfiguration(
                characterId: characterId,
                mode: RunMode.standard,
                stats: stats,
                loadout: RunLoadout(activeAbility: definition.defaultActive),
                level: 1,
                contentVersion: environment.contentVersion,
                protocolVersion: 1,
                seed: DateTime.now().microsecondsSinceEpoch & 0x7fffffff,
                palette: equippedPalette ?? PaletteTransform.identity,
                legacyHighScore: legacyHighScore,
                audioEnabled: gameSettings.audioEnabled,
                musicEnabled: gameSettings.musicEnabled,
                sfxEnabled: gameSettings.sfxEnabled,
                reduceMotion: reduceMotion,
              );
            },
            onRunFinished: (result) async {
              if (environment.usesLocalBackend) {
                await recorder.save(
                  result,
                  validationStatus: 'limited',
                  isSynced: true,
                );
              } else {
                await recorder.sealPending(result);
              }
              final fortunePoints = localEffectiveBasisPoints(
                localStore.currentState.character(result.characterId),
                'fortune',
              );
              final fortuneMultiplier = 1.0 + fortunePoints / 10000.0;
              final baseCoins = max(1, result.score ~/ 10);
              final coinsEarned = (baseCoins * fortuneMultiplier).round();
              await localStore.mutate((state) {
                state.character(result.characterId).bankedCurrency +=
                    coinsEarned;
              });
              await ref.read(progressionRepositoryProvider).creditCurrency(
                characterId: result.characterId,
                amount: coinsEarned,
              );
              await preferences.setString(
                'selected_character',
                result.characterId.serialized,
              );
              ref.invalidate(progressionControllerProvider);
              ref.invalidate(leaderboardControllerProvider);
              return 'Puntuación guardada (+🪙 $coinsEarned)';
            },
          ),
          _RetroBackButton(onPressed: () => context.go('/home')),
          const _RetroAudioToggleButton(),
          const _RunBanner(
            label: 'MODO CLÁSICO',
          ),
        ],
      ),
    );
  }

  Widget _buildCampaign(BuildContext context, CampaignStageSession session) {
    final preferences = ref.watch(sharedPreferencesProvider);
    final resultCoordinator = ref.watch(campaignResultCoordinatorProvider);
    final legacyHighScore = preferences.getInt('high_score') ?? 0;
    final configuration = _withGameSettings(context, session.configuration);
    return Scaffold(
      body: Stack(
        children: [
          DinoRunApp(
            initialHighScore: legacyHighScore,
            audioEnabled: configuration.audioEnabled,
            musicEnabled: configuration.musicEnabled,
            sfxEnabled: configuration.sfxEnabled,
            hudSettings: ref.watch(hudSettingsControllerProvider),
            configurationForCharacter: (_) => configuration,
            onRunFinished: (result) async {
              final character = session.configuration.characterId.serialized;
              await preferences.setString('selected_character', character);
              if (result.outcome == RunOutcome.victory) {
                final beatenLevel = session.configuration.level;
                final currentUnlocked =
                    preferences.getInt(
                      'campaign_max_unlocked_level_$character',
                    ) ??
                    1;
                final nextUnlocked = max(
                  currentUnlocked,
                  beatenLevel + 1,
                ).clamp(1, 10);
                await preferences.setInt(
                  'campaign_max_unlocked_level_$character',
                  nextUnlocked,
                );
                await preferences.setInt(
                  'campaign_max_unlocked_level',
                  nextUnlocked,
                );
                if (beatenLevel == 10) {
                  await preferences.setBool(
                    'campaign_completed_$character',
                    true,
                  );
                  await preferences.setBool('campaign_completed', true);
                }
              }
              final message = await resultCoordinator.sealAndSynchronize(
                session,
                result,
              );
              ref.invalidate(progressionControllerProvider);
              ref.invalidate(leaderboardControllerProvider);
              return message;
            },
            onCampaignExit: () => context.go('/campaign'),
          ),
          _RetroBackButton(onPressed: () => _confirmAbandon(context, session)),
          const _RetroAudioToggleButton(),
          _CampaignPreflightBanner(session: session),
        ],
      ),
    );
  }

  RunConfiguration _withGameSettings(
    BuildContext context,
    RunConfiguration configuration,
  ) {
    final settings = ref.watch(gameSettingsControllerProvider);
    return configuration.copyWith(
      audioEnabled: settings.audioEnabled,
      musicEnabled: settings.musicEnabled,
      sfxEnabled: settings.sfxEnabled,
      reduceMotion:
          settings.reduceMotion || MediaQuery.disableAnimationsOf(context),
    );
  }

  Future<void> _confirmAbandon(
    BuildContext context,
    CampaignStageSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Abandonar Nivel?'),
        content: Text(
          'Nivel ${session.configuration.level}/10.\n¿Deseas volver al mapa de campaña?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('SEGUIR JUGANDO'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ABANDONAR Y VOLVER'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(campaignStageCoordinatorProvider).abandon(session);
    if (context.mounted) context.go('/campaign');
  }
}

class _CampaignPreflightBanner extends StatefulWidget {
  const _CampaignPreflightBanner({required this.session});

  final CampaignStageSession session;

  @override
  State<_CampaignPreflightBanner> createState() =>
      _CampaignPreflightBannerState();
}

class _CampaignPreflightBannerState extends State<_CampaignPreflightBanner> {
  bool _visible = true;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(const Duration(milliseconds: 3800), () {
      if (mounted) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final color = switch (session.eligibility) {
      CampaignEligibility.verifiedOnline => const Color(0xFF0B6B47),
      CampaignEligibility.eligibleOffline => const Color(0xFF765600),
      CampaignEligibility.local => const Color(0xFF315C78),
      CampaignEligibility.practice => const Color(0xFF6A2431),
    };
    final expiry = session.expiresAt;
    final detail = session.canEarnRewards
        ? 'Recompensas habilitadas · resultado sellado y sincronizable${expiry == null ? '' : ' · vence ${TimeOfDay.fromDateTime(expiry.toLocal()).format(context)}'}'
        : 'Sin moneda, maestría, recompensa única ni ranking';
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          child: IgnorePointer(
            ignoring: !_visible,
            child: GestureDetector(
              onTap: () {
                if (_visible) setState(() => _visible = false);
              },
              child: Semantics(
                liveRegion: true,
                label:
                    'Preflight de campaña: ${session.eligibility.label}. $detail',
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = MediaQuery.of(context).size.height < 500;
                    return Container(
                      margin: EdgeInsets.fromLTRB(
                        isCompact ? 54 : 48,
                        isCompact ? 8 : 64,
                        isCompact ? 54 : 48,
                        0,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 10 : 14,
                        vertical: isCompact ? 4 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(
                          isCompact ? 12 : 18,
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: isCompact ? 1.5 : 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'CAMPAÑA · NIVEL ${session.configuration.level}/10',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 11 : 13,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RunBanner extends StatefulWidget {
  const _RunBanner({required this.label, this.topMargin = 10});

  final String label;
  final double topMargin;

  @override
  State<_RunBanner> createState() => _RunBannerState();
}

class _RunBannerState extends State<_RunBanner> {
  bool _visible = true;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(const Duration(milliseconds: 3800), () {
      if (mounted) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 500;
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          child: IgnorePointer(
            ignoring: !_visible,
            child: Container(
              margin: EdgeInsets.only(
                top: isCompact && widget.topMargin > 16 ? 8 : widget.topMargin,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 14,
                vertical: isCompact ? 4 : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(isCompact ? 14 : 24),
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 11 : 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RetroBackButton extends StatelessWidget {
  const _RetroBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 500;
    final size = isCompact ? 38.0 : 44.0;

    return Positioned(
      top: isCompact ? 6 : 10,
      left: isCompact ? 6 : 10,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF141923).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF00E5FF),
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/back_button_retro.png',
                filterQuality: FilterQuality.none,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RetroAudioToggleButton extends ConsumerWidget {
  const _RetroAudioToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = MediaQuery.of(context).size.height < 500;
    final size = isCompact ? 38.0 : 44.0;
    final gameSettings = ref.watch(gameSettingsControllerProvider);
    final isMusicEnabled = gameSettings.musicEnabled;

    return Positioned(
      top: isCompact ? 6 : 10,
      right: isCompact ? 6 : 10,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ref
                  .read(gameSettingsControllerProvider.notifier)
                  .setMusicEnabled(!isMusicEnabled);
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF141923).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isMusicEnabled
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFFFF5252),
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                isMusicEnabled
                    ? 'assets/images/music_on_retro.png'
                    : 'assets/images/music_off_retro.png',
                filterQuality: FilterQuality.none,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreflightLoading extends StatelessWidget {
  const _PreflightLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070D16),
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1B2D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00F5FF), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F5FF).withValues(alpha: 0.35),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '★ JANOSOS ARCADE ★',
                style: GoogleFonts.pressStart2p(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'PREPARANDO ZONA DE COMBATE...',
                style: GoogleFonts.pressStart2p(
                  fontSize: 8.5,
                  color: const Color(0xFF00F5FF),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    backgroundColor: Color(0xFF070D16),
                    color: Color(0xFF00F5FF),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'CONSEJO: USA GOLPE JEFE CUANDO EL BOSS ESTÉ CERCA',
                style: GoogleFonts.vt323(
                  fontSize: 15,
                  color: const Color(0xFF8CA0BA),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreflightFailure extends StatelessWidget {
  const _PreflightFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'No se pudo iniciar el nivel',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Por favor comprueba tu conexión y vuelve a intentarlo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('REINTENTAR'),
              ),
              TextButton(
                onPressed: () => context.go('/campaign'),
                child: const Text('VOLVER AL MAPA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
