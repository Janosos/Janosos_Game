import 'dart:math';
import 'package:flame/components.dart';
import 'obstacle.dart';
import '../dino_run_game.dart';

class ObstacleManager extends Component with HasGameReference<DinoRunGame> {
  late Timer _timer;
  Random _random = Random(0);
  bool _spawningEnabled = true;

  @override
  Future<void> onLoad() async {
    _timer = Timer(2, repeat: true, onTick: _spawnObstacle);
    _timer.start();
  }

  @override
  void update(double dt) {
    _timer.update(dt);
  }

  void _spawnObstacle() {
    if (!_spawningEnabled) return;
    final isDog = _random.nextBool();
    final obstacleName = isDog ? 'dog' : 'cat';

    final obstacle = Obstacle(obstacleName: obstacleName);
    add(obstacle);

    // Randomize next spawn time
    double nextTime = 1.5 + _random.nextDouble() * 2.0;

    // Faster spawns if Nanic is Super Charged
    if (game.dino.isSuperCharged) {
      nextTime = nextTime * 0.5; // Twice as fast (50% delay)
    }

    _timer.limit = nextTime;
  }

  void reset({int? seed}) {
    _timer.stop();
    // Remove all obstacle children
    removeAll(children);
    _random = Random(seed ?? 0);
    _spawningEnabled = true;
    // Reset timer
    _timer.limit = 2;
    _timer.start();
  }

  void pauseSpawning() {
    _spawningEnabled = false;
    _timer.stop();
    removeAll(children);
  }
}
