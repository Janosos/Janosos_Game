import 'dart:math';
import 'package:flame/components.dart';
import 'obstacle.dart';
import '../dino_run_game.dart';

class ObstacleManager extends Component with HasGameRef<DinoRunGame> {
  late Timer _timer;
  final Random _random = Random();

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
    final isDog = _random.nextBool();
    final obstacleName = isDog ? 'dog' : 'cat';
    
    final obstacle = Obstacle(obstacleName: obstacleName);
    add(obstacle); // Add to ObstacleManager's children, not gameRef
    
    // Randomize next spawn time
    double nextTime = 1.5 + _random.nextDouble() * 2.0;

    // Faster spawns if Nanic is Super Charged
    if (gameRef.dino.isSuperCharged) {
       nextTime = nextTime * 0.5; // Twice as fast (50% delay)
    }
    
    _timer.limit = nextTime;
  }
  
  void reset() {
    _timer.stop();
    // Remove all obstacle children
    removeAll(children);
    // Reset timer
    _timer.limit = 2;
    _timer.start();
  }
}
