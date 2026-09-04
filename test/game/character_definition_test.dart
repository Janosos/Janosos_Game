import 'package:dino_run_flame/game/domain/character_definition.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines every existing character with a stable serialized id', () {
    expect(characterDefinitions.keys, containsAll(CharacterId.values));
    expect(characterDefinitions, hasLength(7));

    expect(CharacterId.jano.serialized, 'jano');
    expect(CharacterIdSerialization.parse('nanic'), CharacterId.nanic);
    expect(
      () => CharacterIdSerialization.parse('unknown'),
      throwsFormatException,
    );
  });

  test('preserves the seven V5 character identities', () {
    expect(
      CharacterId.jano.definition.defaultActive,
      ActiveAbilityId.pistolShot,
    );
    expect(CharacterId.parker.definition.baseLives, 2);
    expect(
      CharacterId.chema.definition.coreTraits,
      contains(CharacterCoreTrait.regeneratingShield),
    );
    expect(
      CharacterId.conra.definition.defaultActive,
      ActiveAbilityId.intangibility,
    );
    expect(
      CharacterId.shyno.definition.coreTraits,
      contains(CharacterCoreTrait.doubleJump),
    );
    expect(
      CharacterId.nakama.definition.coreTraits,
      contains(CharacterCoreTrait.glide),
    );
    expect(
      CharacterId.nanic.definition.defaultActive,
      ActiveAbilityId.electricDischarge,
    );
    expect(
      CharacterId.nanic.definition.coreTraits,
      contains(CharacterCoreTrait.energyCharge),
    );
  });

  test('keeps sprite assets independent from display names', () {
    for (final entry in characterDefinitions.entries) {
      expect(entry.value.id, entry.key);
      expect(entry.value.assetName, endsWith('_clean.png'));
      expect(entry.value.displayName, isNotEmpty);
    }
  });
}
