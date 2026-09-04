import 'package:dino_run_flame/game/hud/score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('advances, completes, and resets a runtime-only score', () {
    final score = ScoreSystem(initialHighScore: 12);

    score.advance(2);

    expect(score.currentScore, 20);
    expect(score.completeRun(), 20);

    score.reset();

    expect(score.currentScore, 0);
    expect(score.highScore, 20);
  });

  test('does not replace a greater legacy high score', () {
    final score = ScoreSystem(initialHighScore: 100);

    score.advance(1);

    expect(score.completeRun(), 100);
  });
}
