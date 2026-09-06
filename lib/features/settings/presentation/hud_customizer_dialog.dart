import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/widgets/retro_pixel_widgets.dart';
import '../../../game/domain/hud_settings.dart';
import '../application/hud_settings_controller.dart';

/// Modal interactivo para personalizar el tamaño, opacidad y posición de los botones del juego
class HudCustomizerDialog extends ConsumerStatefulWidget {
  const HudCustomizerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const HudCustomizerDialog(),
    );
  }

  @override
  ConsumerState<HudCustomizerDialog> createState() =>
      _HudCustomizerDialogState();
}

class _HudCustomizerDialogState extends ConsumerState<HudCustomizerDialog> {
  late HudSettings _current;
  int _activeCategory = 0; // 0: D-Pad, 1: Habilidad, 2: Golpe Jefe

  @override
  void initState() {
    super.initState();
    _current = ref.read(hudSettingsControllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final isCompact = media.height < 520;

    return Dialog(
      backgroundColor: const Color(0xFF070D16),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 32,
        vertical: isCompact ? 12 : 24,
      ),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: RetroColors.cyan, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 780,
          maxHeight: media.height * 0.94,
        ),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.tune, color: RetroColors.cyan, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PERSONALIZAR BOTONES / HUD',
                      style: GoogleFonts.pressStart2p(
                        fontSize: isCompact ? 10 : 12,
                        color: RetroColors.cyan,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: RetroColors.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Contenedor de Vista Previa en Vivo (Simulador de Pantalla de Juego)
              _buildLivePreview(isCompact),
              const SizedBox(height: 12),

              // Pestañas selectoras de botones
              Row(
                children: [
                  _buildTabButton(0, 'CRUCETA IZQ/DER', RetroColors.cyan),
                  const SizedBox(width: 6),
                  _buildTabButton(1, 'HABILIDAD', RetroColors.gold),
                  const SizedBox(width: 6),
                  _buildTabButton(2, 'GOLPE JEFE', RetroColors.magenta),
                ],
              ),
              const SizedBox(height: 10),

              // Controles del botón seleccionado
              Expanded(
                child: SingleChildScrollView(
                  child: switch (_activeCategory) {
                    0 => _buildDpadControls(),
                    1 => _buildAbilityControls(),
                    _ => _buildBossActionControls(),
                  },
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFF1E354F)),
              const SizedBox(height: 12),

              // Botones de acción (Restablecer, Cancelar, Guardar)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _current = HudSettings.defaults;
                      });
                    },
                    icon: const Icon(
                      Icons.restore,
                      size: 16,
                      color: RetroColors.textMuted,
                    ),
                    label: Text(
                      'RESTABLECER',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 7.5,
                        color: RetroColors.textMuted,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'CANCELAR',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 8,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      RetroArcadeButton(
                        text: 'GUARDAR AJUSTES',
                        icon: Icons.check,
                        primaryColor: RetroColors.cyan,
                        fontSize: 8,
                        onPressed: () async {
                          await ref
                              .read(hudSettingsControllerProvider.notifier)
                              .updateSettings(_current);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF0C1929),
                                content: Text(
                                  'Ajustes de HUD guardados localmente.',
                                  style: GoogleFonts.vt323(
                                    fontSize: 18,
                                    color: RetroColors.cyan,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title, Color color) {
    final isSelected = _activeCategory == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeCategory = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : const Color(0xFF0C1420),
            border: Border.all(
              color: isSelected ? color : const Color(0xFF1E354F),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.pressStart2p(
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.white60,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreview(bool isCompact) {
    final dpadSize = 36.0 * _current.dpadScale;
    final abilitySize = 42.0 * _current.abilityScale;
    final bossSize = 42.0 * _current.bossActionScale;

    return Container(
      height: isCompact ? 90 : 130,
      decoration: BoxDecoration(
        color: const Color(0xFF03070E),
        border: Border.all(color: const Color(0xFF1E354F), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Fondo de rejilla arcade sutil
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: GridPaper(
                color: RetroColors.cyan,
                divisions: 2,
                subdivisions: 2,
              ),
            ),
          ),
          // Etiqueta de simulación de juego
          Positioned(
            top: 6,
            left: 10,
            child: Text(
              'VISTA PREVIA DE PANTALLA',
              style: GoogleFonts.pressStart2p(
                fontSize: 7,
                color: RetroColors.textMuted,
              ),
            ),
          ),

          // D-Pad preview
          if (_current.dpadEnabled)
            Positioned(
              left: _current.dpadInvertSide ? null : 14,
              right: _current.dpadInvertSide ? 14 : null,
              bottom: 8,
              child: Opacity(
                opacity: _current.dpadOpacity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/dpad_arrow_left.png',
                      width: dpadSize,
                      height: dpadSize,
                      filterQuality: FilterQuality.none,
                    ),
                    const SizedBox(width: 4),
                    Image.asset(
                      'assets/images/dpad_arrow_right.png',
                      width: dpadSize,
                      height: dpadSize,
                      filterQuality: FilterQuality.none,
                    ),
                  ],
                ),
              ),
            ),

          // Ability Button preview
          Positioned(
            right: 14,
            bottom: _current.swapActionButtons
                ? (bossSize + 14)
                : 8,
            child: Opacity(
              opacity: _current.abilityOpacity,
              child: Image.asset(
                'assets/images/ability_button.png',
                width: abilitySize,
                height: abilitySize,
                filterQuality: FilterQuality.none,
              ),
            ),
          ),

          // Boss Attack Button preview
          Positioned(
            right: 14,
            bottom: _current.swapActionButtons
                ? 8
                : (abilitySize + 14),
            child: Opacity(
              opacity: _current.bossActionOpacity,
              child: Container(
                width: bossSize,
                height: bossSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE86A17),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    'GOLPE\nJEFE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: (8 * _current.bossActionScale).clamp(6.0, 12.0),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDpadControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          value: _current.dpadEnabled,
          onChanged: (val) => setState(
            () => _current = _current.copyWith(dpadEnabled: val),
          ),
          activeThumbColor: RetroColors.cyan,
          title: Text(
            'HABILITAR CRUCETA EN PANTALLA',
            style: GoogleFonts.pressStart2p(fontSize: 8.5, color: Colors.white),
          ),
          subtitle: Text(
            'Muestra los botones izquierda y derecha en dispositivos táctiles.',
            style: GoogleFonts.vt323(
              fontSize: 15,
              color: RetroColors.textMuted,
            ),
          ),
        ),
        const Divider(height: 16, color: Color(0xFF1E354F)),
        _buildSlider(
          label: 'TAMAÑO / ESCALA',
          valueText: '${(_current.dpadScale * 100).toInt()}%',
          value: _current.dpadScale,
          min: 0.7,
          max: 1.4,
          color: RetroColors.cyan,
          onChanged: _current.dpadEnabled
              ? (val) => setState(
                  () => _current = _current.copyWith(dpadScale: val),
                )
              : null,
        ),
        const SizedBox(height: 10),
        _buildSlider(
          label: 'OPACIDAD / TRANSPARENCIA',
          valueText: '${(_current.dpadOpacity * 100).toInt()}%',
          value: _current.dpadOpacity,
          min: 0.3,
          max: 1.0,
          color: RetroColors.cyan,
          onChanged: _current.dpadEnabled
              ? (val) => setState(
                  () => _current = _current.copyWith(dpadOpacity: val),
                )
              : null,
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          value: _current.dpadInvertSide,
          onChanged: _current.dpadEnabled
              ? (val) => setState(
                  () => _current = _current.copyWith(dpadInvertSide: val),
                )
              : null,
          activeThumbColor: RetroColors.cyan,
          title: Text(
            'INVERTIR LADO (MOVER A LA DERECHA)',
            style: GoogleFonts.pressStart2p(
              fontSize: 8.5,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            'Coloca la cruceta direccional en el lado derecho de la pantalla.',
            style: GoogleFonts.vt323(
              fontSize: 15,
              color: RetroColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAbilityControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSlider(
          label: 'TAMAÑO / ESCALA DEL BOTÓN',
          valueText: '${(_current.abilityScale * 100).toInt()}%',
          value: _current.abilityScale,
          min: 0.7,
          max: 1.4,
          color: RetroColors.gold,
          onChanged: (val) => setState(
            () => _current = _current.copyWith(abilityScale: val),
          ),
        ),
        const SizedBox(height: 12),
        _buildSlider(
          label: 'OPACIDAD / TRANSPARENCIA',
          valueText: '${(_current.abilityOpacity * 100).toInt()}%',
          value: _current.abilityOpacity,
          min: 0.3,
          max: 1.0,
          color: RetroColors.gold,
          onChanged: (val) => setState(
            () => _current = _current.copyWith(abilityOpacity: val),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'El botón de habilidad activa los poderes especiales de cada héroe (Disparo, Intangibilidad, etc.).',
          style: GoogleFonts.vt323(
            fontSize: 15,
            color: RetroColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildBossActionControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSlider(
          label: 'TAMAÑO / ESCALA DEL BOTÓN',
          valueText: '${(_current.bossActionScale * 100).toInt()}%',
          value: _current.bossActionScale,
          min: 0.7,
          max: 1.4,
          color: RetroColors.magenta,
          onChanged: (val) => setState(
            () => _current = _current.copyWith(bossActionScale: val),
          ),
        ),
        const SizedBox(height: 12),
        _buildSlider(
          label: 'OPACIDAD / TRANSPARENCIA',
          valueText: '${(_current.bossActionOpacity * 100).toInt()}%',
          value: _current.bossActionOpacity,
          min: 0.3,
          max: 1.0,
          color: RetroColors.magenta,
          onChanged: (val) => setState(
            () => _current = _current.copyWith(bossActionOpacity: val),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: _current.swapActionButtons,
          onChanged: (val) => setState(
            () => _current = _current.copyWith(swapActionButtons: val),
          ),
          activeThumbColor: RetroColors.magenta,
          title: Text(
            'INTERCAMBIAR POSICIÓN',
            style: GoogleFonts.pressStart2p(
              fontSize: 8.5,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            'Coloca el botón de Golpe de Jefe abajo y el de Habilidad arriba.',
            style: GoogleFonts.vt323(
              fontSize: 15,
              color: RetroColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.pressStart2p(
                fontSize: 8,
                color: onChanged == null ? Colors.white38 : Colors.white,
              ),
            ),
            Text(
              valueText,
              style: GoogleFonts.pressStart2p(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: onChanged == null ? Colors.white38 : color,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: color,
          inactiveColor: const Color(0xFF1E354F),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
