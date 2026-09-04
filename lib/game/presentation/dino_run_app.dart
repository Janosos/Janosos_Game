import 'dart:async';

import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import '../dino_run_game.dart';
import '../domain/character_id.dart';
import '../domain/gameplay_event.dart';
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
  });

  final int initialHighScore;
  final Future<void> Function(int score)? onHighScoreChanged;
  final RunConfiguration Function(CharacterId characterId)?
  configurationForCharacter;
  final Future<String> Function(RunResult result)? onRunFinished;
  final VoidCallback? onCampaignExit;

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
    );
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
              return Center(
                child: Semantics(
                  namesRoute: true,
                  liveRegion: true,
                  label: isVictory
                      ? 'Victoria contra $bossName'
                      : 'Partida terminada',
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    constraints: const BoxConstraints(maxWidth: 560),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isVictory ? Colors.amber : Colors.redAccent,
                        width: 3,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isVictory
                              ? '¡VICTORIA!'
                              : isAbandoned
                              ? 'CAMPAÑA ABANDONADA'
                              : 'AGOTASTE TUS VIDAS',
                          style: TextStyle(
                            color: isVictory ? Colors.amber : Colors.redAccent,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isCampaign
                              ? isVictory
                                    ? 'Nivel ${result?.levelReached ?? 1}/10 superado. La recompensa única tiene 1% de probabilidad y sólo el servidor confirma el resultado.'
                                    : isAbandoned
                                    ? 'La pausa o autorización excedió su límite. La campaña vuelve al nivel 1 y no publica ranking.'
                                    : 'La campaña vuelve al nivel 1. Conservas maestría, compras, moneda guardada, paletas y recompensas únicas.'
                              : isBossRush
                              ? isVictory
                                    ? 'Derrotaste los 10 jefes. La puntuación '
                                          'se publica sólo en Boss Rush; no se '
                                          'concede moneda de campaña.'
                                    : 'Derrotaste ${result?.levelReached ?? 0}/10 '
                                          'jefes. La cadena termina, pero todo '
                                          'tu progreso permanente se conserva.'
                              : 'Puntuación: ${result?.score ?? 0}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
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
                            if (game.runConfiguration.audioEnabled) {
                              FlameAudio.play('Select.wav');
                            }
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
                                ? 'VOLVER A PROGRESIÓN'
                                : 'REINICIAR',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
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
    _ResultSaveStatus.saving => 'Sellando resultado pendiente…',
    _ResultSaveStatus.saved =>
      'Resultado pendiente guardado. Revísalo en tu historial.',
    _ResultSaveStatus.failed =>
      'No se pudo guardar el resultado. No se publicará ni dará recompensas.',
  };
}

class JanososVersionLabel extends StatelessWidget {
  const JanososVersionLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Text(
        'V6 PREVIEW',
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
