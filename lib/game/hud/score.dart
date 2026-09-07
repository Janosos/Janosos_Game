import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../dino_run_game.dart';
import '../domain/character_id.dart';
import '../domain/level_runtime.dart';
import '../domain/run_configuration.dart';

class ScoreSystem extends TextComponent with HasGameReference<DinoRunGame> {
  ScoreSystem({int initialHighScore = 0}) : _highScore = initialHighScore;

  double _score = 0;
  int _highScore;
  int _lastEmittedScore = 0;

  void _updateLayout(Vector2 size) {
    final isCompact = size.y < 500;
    position = Vector2(isCompact ? 48 : 56, isCompact ? 8 : 16);
    textRenderer = TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: isCompact ? 14 : 22,
        fontFamily: 'Courier',
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1.5, 1.5)),
        ],
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    _updateLayout(game.size);
    updateText();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateLayout(size);
    updateText();
  }

  @override
  void update(double dt) {
    super.update(dt);
    var multiplier = 1.0;
    if (game.dino.characterId == CharacterId.nanic &&
        game.dino.isSuperCharged) {
      multiplier = 2;
    }
    if (game.runConfiguration.mode == RunMode.standard) {
      multiplier *= game.runConfiguration.stats.speedMultiplier;
    }
    advance(dt, multiplier: multiplier);
  }

  void advance(double dt, {double multiplier = 1}) {
    _score += dt * 10 * multiplier;
    final wholeScore = _score.toInt();
    if (wholeScore != _lastEmittedScore && isMounted) {
      _lastEmittedScore = wholeScore;
      game.scoreChanged(wholeScore);
    }
    updateText();
  }

  void updateText() {
    final scoreText = _score.toInt().toString().padLeft(5, '0');
    final highScoreText = _highScore.toString().padLeft(5, '0');
    final isCombat = isMounted && game.levelPhase == LevelPhase.bossCombat;
    final isCompact = isMounted && game.size.y < 500;
    if (isCombat || isCompact) {
      text = 'HI $highScoreText\nSC $scoreText';
    } else {
      text = 'HI $highScoreText  $scoreText';
    }
  }

  int completeRun() {
    final wholeScore = _score.toInt();
    if (wholeScore > _highScore) {
      _highScore = wholeScore;
      updateText();
    }
    return _highScore;
  }

  void reset({int? highScore}) {
    if (highScore != null && highScore > _highScore) {
      _highScore = highScore;
    }
    _score = 0;
    _lastEmittedScore = 0;
    updateText();
  }

  double get currentScore => _score;
  double get score => _score;
  int get highScore => _highScore;

  set score(double value) {
    _score = value < 0 ? 0 : value;
    final wholeScore = _score.toInt();
    if (wholeScore != _lastEmittedScore && isMounted) {
      _lastEmittedScore = wholeScore;
      game.scoreChanged(wholeScore);
    }
    updateText();
  }
}
