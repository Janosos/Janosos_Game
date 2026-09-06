import 'dart:convert';

/// Configuración personalizable para los botones y controles en pantalla (HUD).
/// Se guarda localmente y permite ajustar escala, opacidad y posición de los botones.
class HudSettings {
  const HudSettings({
    this.dpadEnabled = true,
    this.dpadScale = 1.0,
    this.dpadOpacity = 1.0,
    this.dpadInvertSide = false,
    this.abilityScale = 1.0,
    this.abilityOpacity = 1.0,
    this.bossActionScale = 1.0,
    this.bossActionOpacity = 1.0,
    this.swapActionButtons = false,
  });

  /// Si los botones izquierdo/derecho (D-Pad) están habilitados en pantalla táctil
  final bool dpadEnabled;

  /// Escala de la cruceta direccional (0.7 a 1.4)
  final double dpadScale;

  /// Opacidad de la cruceta direccional (0.3 a 1.0)
  final double dpadOpacity;

  /// Si es true, el D-Pad se posiciona a la derecha en lugar de a la izquierda
  final bool dpadInvertSide;

  /// Escala del botón de habilidad del personaje (0.7 a 1.4)
  final double abilityScale;

  /// Opacidad del botón de habilidad (0.3 a 1.0)
  final double abilityOpacity;

  /// Escala del botón de ataque a jefes (0.7 a 1.4)
  final double bossActionScale;

  /// Opacidad del botón de ataque a jefes (0.3 a 1.0)
  final double bossActionOpacity;

  /// Intercambiar la posición relativa del botón de habilidad y del botón de jefe
  final bool swapActionButtons;

  static const defaults = HudSettings();

  HudSettings copyWith({
    bool? dpadEnabled,
    double? dpadScale,
    double? dpadOpacity,
    bool? dpadInvertSide,
    double? abilityScale,
    double? abilityOpacity,
    double? bossActionScale,
    double? bossActionOpacity,
    bool? swapActionButtons,
  }) {
    return HudSettings(
      dpadEnabled: dpadEnabled ?? this.dpadEnabled,
      dpadScale: (dpadScale ?? this.dpadScale).clamp(0.7, 1.4),
      dpadOpacity: (dpadOpacity ?? this.dpadOpacity).clamp(0.3, 1.0),
      dpadInvertSide: dpadInvertSide ?? this.dpadInvertSide,
      abilityScale: (abilityScale ?? this.abilityScale).clamp(0.7, 1.4),
      abilityOpacity: (abilityOpacity ?? this.abilityOpacity).clamp(0.3, 1.0),
      bossActionScale: (bossActionScale ?? this.bossActionScale).clamp(0.7, 1.4),
      bossActionOpacity:
          (bossActionOpacity ?? this.bossActionOpacity).clamp(0.3, 1.0),
      swapActionButtons: swapActionButtons ?? this.swapActionButtons,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dpadEnabled': dpadEnabled,
      'dpadScale': dpadScale,
      'dpadOpacity': dpadOpacity,
      'dpadInvertSide': dpadInvertSide,
      'abilityScale': abilityScale,
      'abilityOpacity': abilityOpacity,
      'bossActionScale': bossActionScale,
      'bossActionOpacity': bossActionOpacity,
      'swapActionButtons': swapActionButtons,
    };
  }

  factory HudSettings.fromMap(Map<String, dynamic> map) {
    return HudSettings(
      dpadEnabled: map['dpadEnabled'] as bool? ?? true,
      dpadScale: ((map['dpadScale'] as num?)?.toDouble() ?? 1.0).clamp(0.7, 1.4),
      dpadOpacity:
          ((map['dpadOpacity'] as num?)?.toDouble() ?? 1.0).clamp(0.3, 1.0),
      dpadInvertSide: map['dpadInvertSide'] as bool? ?? false,
      abilityScale:
          ((map['abilityScale'] as num?)?.toDouble() ?? 1.0).clamp(0.7, 1.4),
      abilityOpacity:
          ((map['abilityOpacity'] as num?)?.toDouble() ?? 1.0).clamp(0.3, 1.0),
      bossActionScale:
          ((map['bossActionScale'] as num?)?.toDouble() ?? 1.0).clamp(0.7, 1.4),
      bossActionOpacity:
          ((map['bossActionOpacity'] as num?)?.toDouble() ?? 1.0).clamp(
            0.3,
            1.0,
          ),
      swapActionButtons: map['swapActionButtons'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory HudSettings.fromJson(String source) {
    try {
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      return HudSettings.fromMap(decoded);
    } catch (_) {
      return HudSettings.defaults;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HudSettings &&
        other.dpadEnabled == dpadEnabled &&
        other.dpadScale == dpadScale &&
        other.dpadOpacity == dpadOpacity &&
        other.dpadInvertSide == dpadInvertSide &&
        other.abilityScale == abilityScale &&
        other.abilityOpacity == abilityOpacity &&
        other.bossActionScale == bossActionScale &&
        other.bossActionOpacity == bossActionOpacity &&
        other.swapActionButtons == swapActionButtons;
  }

  @override
  int get hashCode => Object.hash(
    dpadEnabled,
    dpadScale,
    dpadOpacity,
    dpadInvertSide,
    abilityScale,
    abilityOpacity,
    bossActionScale,
    bossActionOpacity,
    swapActionButtons,
  );
}
