import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../dino_run_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScoreSystem extends TextComponent with HasGameRef<DinoRunGame> {
  double _score = 0;
  int _highScore = 0;
  late SharedPreferences _prefs;
  bool _isLoaded = false;

  @override
  Future<void> onLoad() async {
    position = Vector2(20, 20);
    textRenderer = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontFamily: 'Courier', 
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(blurRadius: 2, color: Colors.black, offset: Offset(2, 2)),
        ],
      ),
    );
    
    _prefs = await SharedPreferences.getInstance();
    _highScore = _prefs.getInt('high_score') ?? 0;
    _isLoaded = true;
    updateText();
  }

  @override
  void update(double dt) {
    if (!_isLoaded) return;
    
    // Increase score
    _score += dt * 10; 
    
    // Check if we beat the high score immediately for UI thrill
    if (_score.toInt() > _highScore) {
      _highScore = _score.toInt();
    }
    
    updateText();
  }

  void updateText() {
    String scoreStr = _score.toInt().toString().padLeft(5, '0');
    String highStr = _highScore.toString().padLeft(5, '0');
    text = 'HI $highStr  $scoreStr';
  }
  
  void saveHighScore() {
    if (_score.toInt() >= _highScore) {
       _prefs.setInt('high_score', _score.toInt());
    }
  }

  void reset() {
    // Save previous run if high score (just in case not saved yet)
    saveHighScore(); 
    _score = 0;
    // Reload high score to ensure we have the absolute latest
    _highScore = _prefs.getInt('high_score') ?? _highScore;
  }
  
  double get currentScore => _score;
  double get score => _score;
  
  set score(double value) {
    _score = value;
    updateText();
  }
}
