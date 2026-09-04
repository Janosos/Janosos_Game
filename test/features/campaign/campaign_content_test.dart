import 'package:dino_run_flame/features/campaign/domain/campaign_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial campaign defines ten ordered bosses and unique rewards', () {
    expect(initialCampaignLevels, hasLength(10));
    expect(
      initialCampaignLevels.map((level) => level.level),
      orderedEquals(List.generate(10, (index) => index + 1)),
    );
    expect(
      initialCampaignLevels.map((level) => level.boss).toSet(),
      hasLength(10),
    );
    expect(
      initialCampaignLevels.map((level) => level.uniqueReward).toSet(),
      hasLength(10),
    );
  });
}
