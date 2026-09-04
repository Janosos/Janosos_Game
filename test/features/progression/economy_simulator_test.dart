import 'package:dino_run_flame/features/progression/domain/economy_simulator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canonical catalog totals 38,400 character currency', () {
    expect(EconomySimulator.totalCatalogCost, 38400);
  });

  test('deterministic median remains inside the 20–30 hour target', () {
    const simulator = EconomySimulator();
    final first = simulator.run();
    final second = simulator.run();

    expect(first.medianHours, inInclusiveRange(20, 30));
    expect(first.p10Hours, greaterThan(0));
    expect(first.p90Hours, lessThan(35));
    expect(second.p10Hours, first.p10Hours);
    expect(second.medianHours, first.medianHours);
    expect(second.p90Hours, first.p90Hours);
  });
}
