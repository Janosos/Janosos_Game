enum CharacterId { jano, parker, chema, conra, shyno, nakama, nanic }

extension CharacterIdSerialization on CharacterId {
  String get serialized => name;

  static CharacterId parse(String value) {
    return CharacterId.values.firstWhere(
      (id) => id.serialized == value,
      orElse: () => throw FormatException('Unknown character id: $value'),
    );
  }
}
