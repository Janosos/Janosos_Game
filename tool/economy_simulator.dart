import 'dart:convert';
import 'dart:io';

import 'package:dino_run_flame/features/progression/domain/economy_simulator.dart';

void main() {
  const simulator = EconomySimulator();
  final report = simulator.run();
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'population': report.population,
      'p10_hours': double.parse(report.p10Hours.toStringAsFixed(2)),
      'median_hours': double.parse(report.medianHours.toStringAsFixed(2)),
      'p90_hours': double.parse(report.p90Hours.toStringAsFixed(2)),
      'total_catalog_cost': report.totalCatalogCost,
      'mastery_xp_cap': report.masteryXpCap,
    }),
  );
}
