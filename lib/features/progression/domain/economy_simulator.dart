import 'dart:math';

class EconomySimulationReport {
  const EconomySimulationReport({
    required this.population,
    required this.p10Hours,
    required this.medianHours,
    required this.p90Hours,
    required this.totalCatalogCost,
    required this.masteryXpCap,
  });

  final int population;
  final double p10Hours;
  final double medianHours;
  final double p90Hours;
  final int totalCatalogCost;
  final int masteryXpCap;
}

class EconomySimulator {
  const EconomySimulator({this.seed = 0x4a414e4f});

  final int seed;

  static const masteryXpCap = 46500;
  static const _clearMasteryXp = 1550;
  static const _defeatMasteryXp = 500;

  static const _catalog = <_Purchase>[
    _Purchase('speed_1', 150, 0),
    _Purchase('speed_2', 350, 0),
    _Purchase('speed_3', 650, 0),
    _Purchase('speed_4', 1050, 0),
    _Purchase('speed_5', 1550, 0),
    _Purchase('vitality_1', 1500, 0),
    _Purchase('vitality_2', 3500, 0),
    _Purchase('vitality_3', 6500, 0),
    _Purchase('active_1', 1200, 5),
    _Purchase('active_2', 3200, 14),
    _Purchase('passive_1', 1800, 8),
    _Purchase('passive_2', 4200, 20),
    _Purchase('palette_aurora', 800, 3),
    _Purchase('palette_eclipse', 1800, 10),
  ];

  static const _fortune = <_Purchase>[
    _Purchase('fortune_1', 200, 0, fortuneBasisPoints: 1000),
    _Purchase('fortune_2', 450, 0, fortuneBasisPoints: 1000),
    _Purchase('fortune_3', 800, 0, fortuneBasisPoints: 1000),
    _Purchase('fortune_4', 1250, 0, fortuneBasisPoints: 1000),
    _Purchase('fortune_5', 1800, 0, fortuneBasisPoints: 1000),
  ];

  static int get totalCatalogCost => [
    ..._catalog,
    ..._fortune,
  ].fold(0, (total, purchase) => total + purchase.cost);

  EconomySimulationReport run({int population = 2001}) {
    if (population < 101) {
      throw ArgumentError.value(population, 'population', 'Minimum is 101.');
    }
    final random = Random(seed);
    final completionHours = <double>[
      for (var index = 0; index < population; index++) _simulatePlayer(random),
    ]..sort();
    return EconomySimulationReport(
      population: population,
      p10Hours: _percentile(completionHours, 0.10),
      medianHours: _percentile(completionHours, 0.50),
      p90Hours: _percentile(completionHours, 0.90),
      totalCatalogCost: totalCatalogCost,
      masteryXpCap: masteryXpCap,
    );
  }

  double _simulatePlayer(Random random) {
    final performance = 0.85 + random.nextDouble() * 0.30;
    var masteryXp = 0;
    var balance = 0;
    var fortuneBasisPoints = 0;
    var hours = 0.0;
    final owned = <String>{};

    for (var attempt = 0; attempt < 200; attempt++) {
      final masteryLevel = _masteryLevel(masteryXp);
      final clearChance = min(0.90, 0.82 + masteryLevel * 0.003);
      final completed = random.nextDouble() <= clearChance;
      if (completed) {
        masteryXp = min(masteryXpCap, masteryXp + _clearMasteryXp);
        final scoreNoise = 0.90 + random.nextDouble() * 0.20;
        final baseCurrency = (1000 * performance * scoreNoise).round();
        balance += (baseCurrency * (10000 + fortuneBasisPoints) / 10000)
            .floor();
        hours += (35 + random.nextDouble() * 10) / 60;
      } else {
        masteryXp = min(masteryXpCap, masteryXp + _defeatMasteryXp);
        hours += (15 + random.nextDouble() * 15) / 60;
      }

      {
        final level = _masteryLevel(masteryXp);
        for (final purchase in _fortune) {
          if (!owned.contains(purchase.id) &&
              level >= purchase.unlockLevel &&
              balance >= purchase.cost) {
            balance -= purchase.cost;
            fortuneBasisPoints += purchase.fortuneBasisPoints;
            owned.add(purchase.id);
          }
        }
        var purchased = true;
        while (purchased) {
          purchased = false;
          for (final purchase in _catalog) {
            if (!owned.contains(purchase.id) &&
                level >= purchase.unlockLevel &&
                balance >= purchase.cost) {
              balance -= purchase.cost;
              owned.add(purchase.id);
              purchased = true;
            }
          }
        }
      }

      if (masteryXp >= masteryXpCap &&
          owned.length == _catalog.length + _fortune.length) {
        return hours;
      }
    }
    throw StateError('Economy simulation did not converge.');
  }

  static int _masteryLevel(int xp) {
    var level = 0;
    for (var candidate = 1; candidate <= 30; candidate++) {
      final threshold = 100 * candidate * (candidate + 1) ~/ 2;
      if (xp < threshold) break;
      level = candidate;
    }
    return level;
  }

  static double _percentile(List<double> values, double percentile) {
    final index = ((values.length - 1) * percentile).round();
    return values[index];
  }
}

class _Purchase {
  const _Purchase(
    this.id,
    this.cost,
    this.unlockLevel, {
    this.fortuneBasisPoints = 0,
  });

  final String id;
  final int cost;
  final int unlockLevel;
  final int fortuneBasisPoints;
}
