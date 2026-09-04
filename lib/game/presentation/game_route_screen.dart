import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_providers.dart';
import '../../features/campaign/domain/campaign_repository.dart';
import '../../features/boss_rush/domain/boss_rush_repository.dart';
import '../../features/leaderboard/application/leaderboard_controller.dart';
import '../../features/settings/application/game_settings_controller.dart';
import '../domain/character_definition.dart';
import '../domain/character_id.dart';
import '../domain/run_configuration.dart';
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
            configurationForCharacter: (_) => configuration,
            onRunFinished: (result) async {
              final message = await coordinator.sealAndSynchronize(
                session,
                result,
              );
              ref.invalidate(leaderboardControllerProvider);
              return message;
            },
            onCampaignExit: () => context.go('/campaign'),
          ),
          _BackButton(onPressed: () => _confirmBossRushExit(context, session)),
          _RunBanner(
            label: switch (session.eligibility) {
              BossRushEligibility.verified =>
                'BOSS RUSH VERIFICADO · 10 JEFES · SIN MONEDA',
              BossRushEligibility.local =>
                'BOSS RUSH LOCAL · 10 JEFES · XP LOCAL · SIN MONEDA',
              BossRushEligibility.practice =>
                'BOSS RUSH DE PRÁCTICA · SIN RECOMPENSAS',
            },
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
          'La cadena actual terminará sin ranking ni recompensas. No perderás '
          'moneda, compras, paletas ni recompensas permanentes.',
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
    return Scaffold(
      body: Stack(
        children: [
          DinoRunApp(
            initialHighScore: legacyHighScore,
            onHighScoreChanged: (score) =>
                preferences.setInt('high_score', score),
            configurationForCharacter: (CharacterId characterId) {
              final definition = characterId.definition;
              return RunConfiguration(
                characterId: characterId,
                mode: RunMode.standard,
                stats: RunStats.base(definition),
                loadout: RunLoadout(activeAbility: definition.defaultActive),
                level: 1,
                contentVersion: environment.contentVersion,
                protocolVersion: 1,
                seed: DateTime.now().microsecondsSinceEpoch & 0x7fffffff,
                legacyHighScore: legacyHighScore,
                audioEnabled: gameSettings.audioEnabled,
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
              ref.invalidate(leaderboardControllerProvider);
              return environment.usesLocalBackend
                  ? 'Resultado local guardado. Revísalo en tu historial.'
                  : 'Resultado pendiente guardado. Revísalo en tu historial.';
            },
          ),
          _BackButton(onPressed: () => context.go('/home')),
          const _RunBanner(label: 'MODO ESTÁNDAR · PODER NORMALIZADO'),
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
            configurationForCharacter: (_) => configuration,
            onRunFinished: (result) async {
              final message = await resultCoordinator.sealAndSynchronize(
                session,
                result,
              );
              ref.invalidate(leaderboardControllerProvider);
              return message;
            },
            onCampaignExit: () => context.go('/campaign'),
          ),
          _BackButton(onPressed: () => _confirmAbandon(context, session)),
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
        title: const Text('¿Abandonar la campaña?'),
        content: Text(
          'Nivel ${session.configuration.level}/10 · ${session.configuration.stats.maxLives} vidas. '
          'Perderás ${session.temporaryCurrency} monedas en riesgo. '
          'Conservarás ${session.bankedCurrency} monedas guardadas, maestría, compras, paletas y recompensas únicas.',
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

class _CampaignPreflightBanner extends StatelessWidget {
  const _CampaignPreflightBanner({required this.session});

  final CampaignStageSession session;

  @override
  Widget build(BuildContext context) {
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
        child: Semantics(
          liveRegion: true,
          label: 'Preflight de campaña: ${session.eligibility.label}. $detail',
          child: Container(
            margin: const EdgeInsets.fromLTRB(64, 10, 64, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              'NIVEL ${session.configuration.level}/10 · ${session.eligibility.label.toUpperCase()}\n$detail',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RunBanner extends StatelessWidget {
  const _RunBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: IgnorePointer(
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton.filledTonal(
          tooltip: 'Volver al inicio',
          onPressed: onPressed,
          icon: const Icon(Icons.arrow_back),
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
      body: Center(
        child: Semantics(
          liveRegion: true,
          label: 'Preparando etapa de campaña',
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 18),
              Text('Verificando build, token y recompensas…'),
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
              const Icon(Icons.cloud_off_outlined, size: 64),
              const SizedBox(height: 16),
              const Text(
                'No se pudo preparar la etapa.',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Reintenta la verificación o vuelve al mapa. Nunca se habilitarán recompensas sin autorización válida.',
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
