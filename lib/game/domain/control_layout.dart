import 'character_definition.dart';

class ControlLayout {
  const ControlLayout({
    required this.hasJumpControl,
    required this.hasActiveAbilityControl,
    this.hasBossActionControl = false,
    this.jumpKeyboardBinding = 'Espacio',
    this.activeKeyboardBinding = 'A',
    this.bossKeyboardBinding = 'E',
    this.controllerJumpBinding = 'Botón sur',
    this.controllerActiveBinding = 'Botón oeste',
    this.controllerBossBinding = 'Botón este',
  });

  factory ControlLayout.forActiveAbility(
    ActiveAbilityId? activeAbility, {
    bool hasPurchasedActive = false,
    bool hasBossAction = false,
  }) {
    return ControlLayout(
      hasJumpControl: true,
      hasActiveAbilityControl: activeAbility != null || hasPurchasedActive,
      hasBossActionControl: hasBossAction,
    );
  }

  final bool hasJumpControl;
  final bool hasActiveAbilityControl;
  final bool hasBossActionControl;
  final String jumpKeyboardBinding;
  final String activeKeyboardBinding;
  final String bossKeyboardBinding;
  final String controllerJumpBinding;
  final String controllerActiveBinding;
  final String controllerBossBinding;
}
