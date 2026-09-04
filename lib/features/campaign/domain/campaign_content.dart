class CampaignLevelDefinition {
  const CampaignLevelDefinition({
    required this.level,
    required this.scenario,
    required this.boss,
    required this.mechanic,
    required this.uniqueReward,
  });

  final int level;
  final String scenario;
  final String boss;
  final String mechanic;
  final String uniqueReward;
}

const initialCampaignLevels = <CampaignLevelDefinition>[
  CampaignLevelDefinition(
    level: 1,
    scenario: 'Sleepy Hollow',
    boss: 'Jinete sin Cabeza',
    mechanic: 'Cargas laterales y peligros espectrales',
    uniqueReward: 'Estela espectral',
  ),
  CampaignLevelDefinition(
    level: 2,
    scenario: 'Corte del Caos',
    boss: 'Reina de Corazones',
    mechanic: 'Cartas, plataformas móviles y cambios de tamaño',
    uniqueReward: 'Aura de cartas',
  ),
  CampaignLevelDefinition(
    level: 3,
    scenario: 'Londres Químico',
    boss: 'Señor Hyde',
    mechanic: 'Cambios de fuerza, velocidad y ondas de choque',
    uniqueReward: 'Suero de Hyde',
  ),
  CampaignLevelDefinition(
    level: 4,
    scenario: 'Ópera Subterránea',
    boss: 'El Fantasma',
    mechanic: 'Oscuridad, ecos y ataques guiados por sonido',
    uniqueReward: 'Máscara fantasma',
  ),
  CampaignLevelDefinition(
    level: 5,
    scenario: 'Palacio Invernal',
    boss: 'Reina de las Nieves',
    mechanic: 'Suelo resbaladizo y proyectiles de hielo',
    uniqueReward: 'Corazón de escarcha',
  ),
  CampaignLevelDefinition(
    level: 6,
    scenario: 'Castillo Transilvano',
    boss: 'Drácula',
    mechanic: 'Murciélagos, niebla, teletransporte y curación',
    uniqueReward: 'Capa carmesí',
  ),
  CampaignLevelDefinition(
    level: 7,
    scenario: 'Reino Esmeralda',
    boss: 'Bruja Malvada del Oeste',
    mechanic: 'Vuelo, ciclones y zonas tóxicas',
    uniqueReward: 'Zapatos plateados',
  ),
  CampaignLevelDefinition(
    level: 8,
    scenario: 'Laboratorio de Tormentas',
    boss: 'Criatura de Frankenstein',
    mechanic: 'Rayos, armadura rompible y embestidas',
    uniqueReward: 'Núcleo galvánico',
  ),
  CampaignLevelDefinition(
    level: 9,
    scenario: 'Puerto Abisal',
    boss: 'Davy Jones',
    mechanic: 'Mareas, cadenas y cubierta inclinada',
    uniqueReward: 'Brújula abisal',
  ),
  CampaignLevelDefinition(
    level: 10,
    scenario: 'Londres Mecánico',
    boss: 'Profesor Moriarty',
    mechanic: 'Trampas, señuelos y mecánicas combinadas',
    uniqueReward: 'Corona del estratega',
  ),
];
