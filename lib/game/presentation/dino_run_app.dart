import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../audio/app_audio_manager.dart';

import '../dino_run_game.dart';
import '../domain/character_id.dart';
import '../domain/gameplay_event.dart';
import '../domain/hud_settings.dart';
import '../domain/run_configuration.dart';
import '../domain/run_result.dart';
import '../hud/character_selection_overlay.dart';
import '../hud/start_menu_overlay.dart';

class DinoRunApp extends StatefulWidget {
  const DinoRunApp({
    super.key,
    this.initialHighScore = 0,
    this.onHighScoreChanged,
    this.configurationForCharacter,
    this.onRunFinished,
    this.onCampaignExit,
    this.isMobileOrTablet,
    this.audioEnabled = true,
    this.musicEnabled = true,
    this.sfxEnabled = true,
    this.hudSettings = HudSettings.defaults,
  });

  final int initialHighScore;
  final Future<void> Function(int score)? onHighScoreChanged;
  final RunConfiguration Function(CharacterId characterId)?
  configurationForCharacter;
  final Future<String> Function(RunResult result)? onRunFinished;
  final VoidCallback? onCampaignExit;
  final bool? isMobileOrTablet;
  final bool audioEnabled;
  final bool musicEnabled;
  final bool sfxEnabled;
  final HudSettings hudSettings;

  @override
  State<DinoRunApp> createState() => _DinoRunAppState();
}

class _DinoRunAppState extends State<DinoRunApp> with WidgetsBindingObserver {
  late final DinoRunGame _game;
  late int _persistedHighScore;
  _ResultSaveStatus _resultSaveStatus = _ResultSaveStatus.none;
  bool _bossActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _persistedHighScore = widget.initialHighScore;
    _game = DinoRunGame(
      configuration: _configurationFor(CharacterId.jano),
      onEvent: _handleGameplayEvent,
      isMobileOrTablet: widget.isMobileOrTablet,
      hudSettings: widget.hudSettings,
    );
  }

  @override
  void didUpdateWidget(DinoRunApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.musicEnabled != widget.musicEnabled) {
      _game.setMusicEnabled(widget.musicEnabled);
    }
    if (oldWidget.sfxEnabled != widget.sfxEnabled) {
      _game.setSfxEnabled(widget.sfxEnabled);
    }
    if (oldWidget.audioEnabled != widget.audioEnabled) {
      _game.setAudioEnabled(widget.audioEnabled);
    }
    if (oldWidget.hudSettings != widget.hudSettings) {
      _game.setHudSettings(widget.hudSettings);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _game.resumeFromInterruption();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _game.pauseForInterruption();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleGameplayEvent(GameplayEvent event) {
    if (event is LevelPhaseChangedEvent) {
      final active = event.phase == 'bossCombat';
      if (mounted && active != _bossActive) {
        setState(() => _bossActive = active);
      }
    }
    if (event is! RunFinishedEvent) {
      return;
    }

    if (_bossActive) {
      setState(() => _bossActive = false);
    }

    final result = event.result;
    final score = result.score;
    if (score > _persistedHighScore) {
      _persistedHighScore = score;
      final persistence = widget.onHighScoreChanged;
      if (persistence != null) {
        unawaited(persistence(score));
      }
    }

    final resultPersistence = widget.onRunFinished;
    if (resultPersistence != null) {
      setState(() => _resultSaveStatus = _ResultSaveStatus.saving);
      unawaited(
        resultPersistence(result).then(
          (message) {
            if (mounted) {
              setState(() {
                _resultSaveStatus = _ResultSaveStatus.saved;
                _resultSaveMessage = message;
              });
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (mounted) {
              setState(() => _resultSaveStatus = _ResultSaveStatus.failed);
            }
          },
        ),
      );
    }
  }

  String? _resultSaveMessage;

  RunConfiguration _configurationFor(CharacterId characterId) {
    return widget.configurationForCharacter?.call(characterId) ??
        RunConfiguration.legacy(
          characterId: characterId,
          legacyHighScore: _persistedHighScore,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(
          game: _game,
          loadingBuilder: (BuildContext context) =>
              const _ArcadeGameLoadingOverlay(),
          overlayBuilderMap: {
            'StartMenu': (BuildContext context, DinoRunGame game) {
              return StartMenuOverlay(game: game);
            },
            'GameOverMenu': (BuildContext context, DinoRunGame game) {
              final result = game.lastRunResult;
              final isVictory = result?.outcome == RunOutcome.victory;
              final isAbandoned = result?.outcome == RunOutcome.abandoned;
              final isCampaign =
                  game.runConfiguration.experience ==
                  RunExperience.campaignStage;
              final isBossRush =
                  game.runConfiguration.experience == RunExperience.bossRush;
              final returnsToProgression = isCampaign || isBossRush;
              final bossName = game.currentLevelDefinition?.bossName ?? 'jefe';
              final score = result?.score ?? 0;
              final isNewHighScore =
                  !returnsToProgression &&
                  score >= _persistedHighScore &&
                  score > 0;
              return Center(
                child: Semantics(
                  namesRoute: true,
                  liveRegion: true,
                  label: isVictory
                      ? 'Victoria contra $bossName'
                      : 'Partida terminada',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: 560,
                      maxHeight: MediaQuery.sizeOf(context).height * 0.90,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isVictory || isNewHighScore
                            ? Colors.amber
                            : Colors.redAccent,
                        width: 3,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              returnsToProgression
                                  ? (isVictory
                                        ? '¡VICTORIA!'
                                        : isAbandoned
                                        ? 'CAMPAÑA ABANDONADA'
                                        : 'DERROTADO POR EL JEFE')
                                  : (isNewHighScore
                                        ? '★ ¡NUEVO RÉCORD! ★'
                                        : 'FIN DEL RECORRIDO'),
                              style: TextStyle(
                                color: isVictory || isNewHighScore
                                    ? Colors.amber
                                    : Colors.redAccent,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isCampaign
                                ? isVictory
                                      ? '¡Nivel ${result?.levelReached ?? 1}/10 Superado!\n¡Excelente carrera!'
                                      : isAbandoned
                                      ? 'Partida finalizada.\n¡Inténtalo de nuevo!'
                                      : 'Enfrentamiento: ${bossName.toUpperCase()}\nNivel ${result?.levelReached ?? 1} / 10\n¡Analiza sus patrones de ataque y reinténtalo!'
                                : isBossRush
                                ? isVictory
                                      ? '¡Victoria Total!\n¡Derrotaste a los 10 jefes!'
                                      : 'Derrotado por: ${bossName.toUpperCase()}\nJefes superados en esta racha: ${((result?.levelReached ?? 1) - 1).clamp(0, 10)} / 10'
                                : isNewHighScore
                                ? '¡NUEVO RÉCORD!\n$score PTS'
                                : 'Puntuación: $score PTS\nRécord: $_persistedHighScore PTS',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_resultSaveStatus != _ResultSaveStatus.none) ...[
                            Text(
                              _resultSaveMessage ?? _resultSaveStatus.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                          ],
                          ElevatedButton(
                            onPressed: () {
                              AppAudioManager.playSfx(
                                'Select.wav',
                                audioEnabled:
                                    game.runConfiguration.sfxEnabled &&
                                    game.runConfiguration.audioEnabled,
                              );
                              setState(() {
                                _resultSaveStatus = _ResultSaveStatus.none;
                                _resultSaveMessage = null;
                              });
                              if (returnsToProgression) {
                                widget.onCampaignExit?.call();
                              } else {
                                game.resetGame();
                              }
                            },
                            child: Text(
                              returnsToProgression
                                  ? (isVictory ? 'VOLVER A PROGRESIÓN' : 'REINTENTAR')
                                  : 'JUGAR DE NUEVO',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            'BossTutorial': (BuildContext context, DinoRunGame game) {
              return _BossHelpOverlay(game: game, isIntroduction: true);
            },
            'BossHelp': (BuildContext context, DinoRunGame game) {
              return _BossHelpOverlay(game: game, isIntroduction: false);
            },
            'CharacterSelection': (BuildContext context, DinoRunGame game) {
              return CharacterSelectionOverlay(
                game: game,
                configurationForCharacter: _configurationFor,
              );
            },
          },
        ),
        if (_bossActive)
          Positioned(
            right: 12,
            top: 12,
            child: SafeArea(
              child: IconButton.filledTonal(
                tooltip: 'Pausar y abrir ayuda del jefe',
                onPressed: _game.openBossHelp,
                icon: const Icon(Icons.help_outline),
              ),
            ),
          ),
        const Positioned(left: 5, bottom: 5, child: JanososVersionLabel()),
      ],
    );
  }
}

class _BossHelpOverlay extends StatelessWidget {
  const _BossHelpOverlay({required this.game, required this.isIntroduction});

  final DinoRunGame game;
  final bool isIntroduction;

  @override
  Widget build(BuildContext context) {
    final controls = game.runConfiguration.controlLayout;
    final definition = game.currentLevelDefinition;
    final bossName = definition?.bossName ?? 'Jefe';
    final mechanic =
        definition?.mechanic ?? 'Evita los ataques anunciados del jefe.';
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.86),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            namesRoute: true,
            label: 'Ayuda del combate contra $bossName',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Card(
                color: const Color(0xFF101827),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIntroduction
                            ? 'JEFE · ${bossName.toUpperCase()}'
                            : 'PAUSA · MECÁNICA DEL JEFE',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Colors.amber),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$mechanic. Cada ataque se anuncia con forma, texto y '
                        'movimiento. Usa GOLPE JEFE para dañarlo; ninguna '
                        'compra es necesaria.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ControlLine(
                        icon: Icons.keyboard_double_arrow_up,
                        label:
                            'Saltar · teclado ${controls.jumpKeyboardBinding} · control ${controls.controllerJumpBinding}',
                      ),
                      if (controls.hasActiveAbilityControl)
                        _ControlLine(
                          icon: Icons.auto_awesome,
                          label:
                              'Habilidad exclusiva · teclado ${controls.activeKeyboardBinding} · control ${controls.controllerActiveBinding}',
                        ),
                      _ControlLine(
                        icon: Icons.local_fire_department_outlined,
                        label:
                            'Golpe al jefe · teclado ${controls.bossKeyboardBinding} · control ${controls.controllerBossBinding}',
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          autofocus: true,
                          onPressed: isIntroduction
                              ? game.beginBossEncounter
                              : game.closeBossHelp,
                          icon: Icon(
                            isIntroduction ? Icons.play_arrow : Icons.undo,
                          ),
                          label: Text(
                            isIntroduction
                                ? 'COMENZAR COMBATE'
                                : 'VOLVER AL COMBATE',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlLine extends StatelessWidget {
  const _ControlLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.cyanAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ResultSaveStatus { none, saving, saved, failed }

extension on _ResultSaveStatus {
  String get message => switch (this) {
    _ResultSaveStatus.none => '',
    _ResultSaveStatus.saving => 'Guardando puntuación…',
    _ResultSaveStatus.saved => '¡Puntuación guardada!',
    _ResultSaveStatus.failed => 'Sin conexión para guardar puntuación.',
  };
}

class JanososVersionLabel extends StatelessWidget {
  const JanososVersionLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Text(
        'V6.2',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Courier',
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ArcadeGameLoadingOverlay extends StatelessWidget {
  const _ArcadeGameLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF070D16),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1B2D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00F5FF), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F5FF).withValues(alpha: 0.3),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '★ ANOTHER RETRO RUNNER GAME ★',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'INICIALIZANDO MOTOR ARCADE...',
              style: TextStyle(
                color: Color(0xFF00F5FF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  backgroundColor: Color(0xFF070D16),
                  color: Color(0xFF00F5FF),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
