import 'character_id.dart';

enum CharacterCoreTrait {
  extraLife,
  regeneratingShield,
  doubleJump,
  glide,
  energyCharge,
}

enum ActiveAbilityId { pistolShot, intangibility, electricDischarge }

class CharacterDefinition {
  const CharacterDefinition({
    required this.id,
    required this.displayName,
    required this.description,
    required this.assetName,
    required this.coreTraits,
    required this.defaultActive,
    required this.baseLives,
  });

  final CharacterId id;
  final String displayName;
  final String description;
  final String assetName;
  final Set<CharacterCoreTrait> coreTraits;
  final ActiveAbilityId? defaultActive;
  final int baseLives;

  bool hasTrait(CharacterCoreTrait trait) => coreTraits.contains(trait);
}

const characterDefinitions = <CharacterId, CharacterDefinition>{
  CharacterId.jano: CharacterDefinition(
    id: CharacterId.jano,
    displayName: 'Jano',
    description:
        'Disparo Destructor: Dispara un proyectil recto que destruye '
        'obstáculos. (Cooldown: 10s)',
    assetName: 'jano_clean.png',
    coreTraits: <CharacterCoreTrait>{},
    defaultActive: ActiveAbilityId.pistolShot,
    baseLives: 1,
  ),
  CharacterId.parker: CharacterDefinition(
    id: CharacterId.parker,
    displayName: 'Parker',
    description:
        'Vida Extra: Tiene una vida adicional. El primer choque no lo mata.',
    assetName: 'parker_clean.png',
    coreTraits: <CharacterCoreTrait>{CharacterCoreTrait.extraLife},
    defaultActive: null,
    baseLives: 2,
  ),
  CharacterId.chema: CharacterDefinition(
    id: CharacterId.chema,
    displayName: 'Chema',
    description:
        'Escudo con Costo: Absorbe un golpe (regenera 15s). Penalización: '
        '-500 puntos al impactar.',
    assetName: 'chema_clean.png',
    coreTraits: <CharacterCoreTrait>{CharacterCoreTrait.regeneratingShield},
    defaultActive: null,
    baseLives: 1,
  ),
  CharacterId.conra: CharacterDefinition(
    id: CharacterId.conra,
    displayName: 'Conra',
    description:
        'Intangibilidad: se vuelve invisible por 3 seg. (Cooldown: 10s)',
    assetName: 'conra_clean.png',
    coreTraits: <CharacterCoreTrait>{},
    defaultActive: ActiveAbilityId.intangibility,
    baseLives: 1,
  ),
  CharacterId.shyno: CharacterDefinition(
    id: CharacterId.shyno,
    displayName: 'Shyno',
    description: 'Doble Salto: Permite realizar un segundo salto en el aire.',
    assetName: 'shyno_clean.png',
    coreTraits: <CharacterCoreTrait>{CharacterCoreTrait.doubleJump},
    defaultActive: null,
    baseLives: 1,
  ),
  CharacterId.nakama: CharacterDefinition(
    id: CharacterId.nakama,
    displayName: 'Nakama',
    description:
        'Planeo: Mantén presionado el salto para reducir la velocidad de '
        'caída.',
    assetName: 'nakama_clean.png',
    coreTraits: <CharacterCoreTrait>{CharacterCoreTrait.glide},
    defaultActive: null,
    baseLives: 1,
  ),
  CharacterId.nanic: CharacterDefinition(
    id: CharacterId.nanic,
    displayName: 'Nanic',
    description:
        'Recoge 5 orbes para cargar energía. Con energía llena: Velocidad+ y '
        'Puntos x2. Al usar la habilidad: vuelves a velocidad normal y '
        'activas un escudo eléctrico de 2s que destruye el próximo obstáculo.',
    assetName: 'nanic_clean.png',
    coreTraits: <CharacterCoreTrait>{CharacterCoreTrait.energyCharge},
    defaultActive: ActiveAbilityId.electricDischarge,
    baseLives: 1,
  ),
};

extension CharacterDefinitionLookup on CharacterId {
  CharacterDefinition get definition => characterDefinitions[this]!;
}
