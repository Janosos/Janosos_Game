import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/widgets/retro_pixel_widgets.dart';
import '../../../game/domain/hud_settings.dart';
import '../application/hud_settings_controller.dart';

/// Modal interactivo optimizado para orientación horizontal (Landscape)
/// Permite personalizar tamaño, opacidad y posición de los controles táctiles del juego.
class HudCustomizerDialog extends ConsumerStatefulWidget {
  const HudCustomizerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
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

  Color get _activeColor => switch (_activeCategory) {
    0 => RetroColors.cyan,
    1 => RetroColors.gold,
    _ => RetroColors.magenta,
  };

  String get _activeCategoryTitle => switch (_activeCategory) {
    0 => 'CRUCETA (IZQ / DER)',
    1 => 'BOTÓN DE HABILIDAD',
    _ => 'BOTÓN GOLPE JEFE',
  };

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final dialogWidth = min(880.0, media.width * 0.96);
    final dialogHeight = min(460.0, media.height * 0.94);
    final isCompact = media.height < 420;

    return Dialog(
      backgroundColor: const Color(0xFF070D16),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 20,
        vertical: isCompact ? 6 : 14,
      ),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: RetroColors.cyan, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 8 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(isCompact),
              SizedBox(height: isCompact ? 6 : 10),

              // Contenido principal en 2 Columnas (Layout Horizontal)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Columna Izquierda: Simulador / Vista Previa 16:9
                    Expanded(
                      flex: 5,
                      child: _buildPreviewColumn(isCompact),
                    ),
                    const SizedBox(width: 10),

                    // Columna Derecha: Pestañas y Controles de Ajustes
                    Expanded(
                      flex: 6,
                      child: _buildControlsColumn(isCompact),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isCompact ? 6 : 8),
              const Divider(height: 1, color: Color(0xFF1E354F)),
              SizedBox(height: isCompact ? 6 : 8),

              // Barra de acciones inferior
              _buildBottomBar(isCompact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Row(
      children: [
        const Icon(Icons.tune, color: RetroColors.cyan, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  'PERSONALIZAR HUD & CONTROLES',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.pressStart2p(
                    fontSize: isCompact ? 9 : 10.5,
                    color: RetroColors.cyan,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: RetroColors.cyan.withValues(alpha: 0.15),
                  border: Border.all(color: RetroColors.cyan, width: 1),
                ),
                child: Text(
                  'MODO HORIZONTAL',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 6,
                    color: RetroColors.cyan,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: RetroColors.textMuted, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildPreviewColumn(bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF03070E),
        border: Border.all(color: const Color(0xFF1E354F), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de título de la vista previa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: const Color(0xFF0C1420),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'VISTA PREVIA',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 7,
                    color: Colors.white70,
                  ),
                ),
                Flexible(
                  child: Text(
                    'TOCA UN BOTÓN',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 6,
                      color: RetroColors.cyan,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pantalla 16:9 Simulada
          Expanded(
            child: ClipRect(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0F1A),
                      border: Border.all(
                        color: const Color(0xFF1E354F),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Cuadrícula arcade sutil
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

                        // Línea de suelo simulada
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 24,
                          child: Container(
                            height: 1.5,
                            color: const Color(0xFF1E354F),
                          ),
                        ),

                        // Silueta de personaje en el centro
                        Positioned(
                          left: 45,
                          bottom: 24,
                          child: Icon(
                            Icons.directions_run,
                            color: Colors.white24,
                            size: isCompact ? 28 : 36,
                          ),
                        ),

                        // Botón D-Pad en el simulador
                        if (_current.dpadEnabled) _buildPreviewDpad(),

                        // Botón de Habilidad en el simulador
                        _buildPreviewAbility(),

                        // Botón de Golpe de Jefe en el simulador
                        _buildPreviewBossAction(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Etiqueta de botón activo en edición
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            color: const Color(0xFF0C1420),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'EDITANDO: $_activeCategoryTitle',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 6.5,
                      fontWeight: FontWeight.bold,
                      color: _activeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewDpad() {
    final isSelected = _activeCategory == 0;
    final size = 26.0 * _current.dpadScale;

    return Positioned(
      left: _current.dpadInvertSide ? null : 10,
      right: _current.dpadInvertSide ? 10 : null,
      bottom: 6,
      child: GestureDetector(
        onTap: () => setState(() => _activeCategory = 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected
                ? RetroColors.cyan.withValues(alpha: 0.2)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? RetroColors.cyan : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Opacity(
            opacity: _current.dpadOpacity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/dpad_arrow_left.png',
                  width: size,
                  height: size,
                  filterQuality: FilterQuality.none,
                ),
                const SizedBox(width: 2),
                Image.asset(
                  'assets/images/dpad_arrow_right.png',
                  width: size,
                  height: size,
                  filterQuality: FilterQuality.none,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewAbility() {
    final isSelected = _activeCategory == 1;
    final size = 30.0 * _current.abilityScale;
    final bossSize = 30.0 * _current.bossActionScale;

    return Positioned(
      right: 10,
      bottom: _current.swapActionButtons ? (bossSize + 12) : 6,
      child: GestureDetector(
        onTap: () => setState(() => _activeCategory = 1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected
                ? RetroColors.gold.withValues(alpha: 0.2)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? RetroColors.gold : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Opacity(
            opacity: _current.abilityOpacity,
            child: Image.asset(
              'assets/images/ability_button.png',
              width: size,
              height: size,
              filterQuality: FilterQuality.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewBossAction() {
    final isSelected = _activeCategory == 2;
    final abilitySize = 30.0 * _current.abilityScale;
    final size = 30.0 * _current.bossActionScale;

    return Positioned(
      right: 10,
      bottom: _current.swapActionButtons ? 6 : (abilitySize + 12),
      child: GestureDetector(
        onTap: () => setState(() => _activeCategory = 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected
                ? RetroColors.magenta.withValues(alpha: 0.2)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? RetroColors.magenta : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Opacity(
            opacity: _current.bossActionOpacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE86A17),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  'GOLPE\nJEFE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (6 * _current.bossActionScale).clamp(5.0, 9.0),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsColumn(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selector de Pestañas
        Row(
          children: [
            _buildTabButton(0, 'CRUCETA', RetroColors.cyan),
            const SizedBox(width: 4),
            _buildTabButton(1, 'HABILIDAD', RetroColors.gold),
            const SizedBox(width: 4),
            _buildTabButton(2, 'GOLPE JEFE', RetroColors.magenta),
          ],
        ),
        SizedBox(height: isCompact ? 6 : 8),

        // Área de controles con scroll
        Expanded(
          child: Container(
            padding: EdgeInsets.all(isCompact ? 8 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A101A),
              border: Border.all(color: const Color(0xFF1E354F), width: 1),
            ),
            child: SingleChildScrollView(
              child: switch (_activeCategory) {
                0 => _buildDpadControls(isCompact),
                1 => _buildAbilityControls(isCompact),
                _ => _buildBossActionControls(isCompact),
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, String title, Color color) {
    final isSelected = _activeCategory == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeCategory = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.18)
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
                fontSize: 7,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.white60,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDpadControls(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRetroToggle(
          title: 'HABILITAR CRUCETA',
          subtitle: 'Muestra los botones táctiles de izquierda y derecha.',
          value: _current.dpadEnabled,
          activeColor: RetroColors.cyan,
          isCompact: isCompact,
          onChanged: (val) => setState(
            () => _current = _current.copyWith(dpadEnabled: val),
          ),
        ),
        const Divider(height: 12, color: Color(0xFF1E354F)),

        _buildSliderWithPresets(
          label: 'TAMAÑO / ESCALA',
          valueText: '${(_current.dpadScale * 100).toInt()}%',
          value: _current.dpadScale,
          min: 0.7,
          max: 1.4,
          color: RetroColors.cyan,
          presets: const {
            '80% CHICO': 0.8,
            '100% NORMAL': 1.0,
            '130% GRANDE': 1.3,
          },
          onChanged: _current.dpadEnabled
              ? (val) => setState(() => _current = _current.copyWith(dpadScale: val))
              : null,
        ),
        const SizedBox(height: 10),

        _buildSliderWithPresets(
          label: 'OPACIDAD / TRANSPARENCIA',
          valueText: '${(_current.dpadOpacity * 100).toInt()}%',
          value: _current.dpadOpacity,
          min: 0.3,
          max: 1.0,
          color: RetroColors.cyan,
          presets: const {
            '50% TRANSLÚCIDO': 0.5,
            '75% MEDIO': 0.75,
            '100% SÓLIDO': 1.0,
          },
          onChanged: _current.dpadEnabled
              ? (val) => setState(() => _current = _current.copyWith(dpadOpacity: val))
              : null,
        ),
        const SizedBox(height: 10),

        _buildRetroToggle(
          title: 'INVERTIR LADO',
          subtitle: 'Mueve la cruceta al lado derecho de la pantalla.',
          value: _current.dpadInvertSide,
          activeColor: RetroColors.cyan,
          isCompact: isCompact,
          onChanged: _current.dpadEnabled
              ? (val) => setState(() => _current = _current.copyWith(dpadInvertSide: val))
              : null,
        ),
      ],
    );
  }

  Widget _buildAbilityControls(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSliderWithPresets(
          label: 'TAMAÑO / ESCALA DEL BOTÓN',
          valueText: '${(_current.abilityScale * 100).toInt()}%',
          value: _current.abilityScale,
          min: 0.7,
          max: 1.4,
          color: RetroColors.gold,
          presets: const {
            '80% CHICO': 0.8,
            '100% NORMAL': 1.0,
            '130% GRANDE': 1.3,
          },
          onChanged: (val) => setState(
            () => _current = _current.copyWith(abilityScale: val),
          ),
        ),
        const SizedBox(height: 10),

        _buildSliderWithPresets(
          label: 'OPACIDAD / TRANSPARENCIA',
          valueText: '${(_current.abilityOpacity * 100).toInt()}%',
          value: _current.abilityOpacity,
          min: 0.3,
          max: 1.0,
          color: RetroColors.gold,
          presets: const {
            '50% TRANSLÚCIDO': 0.5,
            '75% MEDIO': 0.75,
            '100% SÓLIDO': 1.0,
          },
          onChanged: (val) => setState(
            () => _current = _current.copyWith(abilityOpacity: val),
          ),
        ),
        const SizedBox(height: 10),

        Text(
          'Activa la habilidad especial del héroe activo (Disparo, Intangibilidad, etc.).',
          style: GoogleFonts.vt323(fontSize: 14, color: RetroColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildBossActionControls(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSliderWithPresets(
          label: 'TAMAÑO / ESCALA DEL BOTÓN',
          valueText: '${(_current.bossActionScale * 100).toInt()}%',
          value: _current.bossActionScale,
          min: 0.7,
          max: 1.4,
          color: RetroColors.magenta,
          presets: const {
            '80% CHICO': 0.8,
            '100% NORMAL': 1.0,
            '130% GRANDE': 1.3,
          },
          onChanged: (val) => setState(
            () => _current = _current.copyWith(bossActionScale: val),
          ),
        ),
        const SizedBox(height: 10),

        _buildSliderWithPresets(
          label: 'OPACIDAD / TRANSPARENCIA',
          valueText: '${(_current.bossActionOpacity * 100).toInt()}%',
          value: _current.bossActionOpacity,
          min: 0.3,
          max: 1.0,
          color: RetroColors.magenta,
          presets: const {
            '50% TRANSLÚCIDO': 0.5,
            '75% MEDIO': 0.75,
            '100% SÓLIDO': 1.0,
          },
          onChanged: (val) => setState(
            () => _current = _current.copyWith(bossActionOpacity: val),
          ),
        ),
        const SizedBox(height: 10),

        _buildRetroToggle(
          title: 'INTERCAMBIAR ACCIONES',
          subtitle: 'Coloca Golpe de Jefe abajo y Habilidad arriba.',
          value: _current.swapActionButtons,
          activeColor: RetroColors.magenta,
          isCompact: isCompact,
          onChanged: (val) => setState(
            () => _current = _current.copyWith(swapActionButtons: val),
          ),
        ),
      ],
    );
  }

  Widget _buildRetroToggle({
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool>? onChanged,
    required bool isCompact,
  }) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.pressStart2p(
                      fontSize: isCompact ? 7 : 8,
                      color: onChanged == null ? Colors.white38 : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.vt323(
                      fontSize: 13.5,
                      color: RetroColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: value
                    ? activeColor.withValues(alpha: 0.22)
                    : const Color(0xFF0C1420),
                border: Border.all(
                  color: value ? activeColor : const Color(0xFF20354A),
                  width: 1.5,
                ),
              ),
              child: Text(
                value ? 'SÍ' : 'NO',
                style: GoogleFonts.pressStart2p(
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                  color: value ? activeColor : Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderWithPresets({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required Color color,
    required Map<String, double> presets,
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
                fontSize: 7.5,
                color: onChanged == null ? Colors.white38 : Colors.white,
              ),
            ),
            Text(
              valueText,
              style: GoogleFonts.pressStart2p(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: onChanged == null ? Colors.white38 : color,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            thumbColor: color,
            activeTrackColor: color,
            inactiveTrackColor: const Color(0xFF1E354F),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        // Chips de presets rápidos
        Row(
          children: [
            for (final entry in presets.entries) ...[
              InkWell(
                onTap: onChanged == null ? null : () => onChanged(entry.value),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: (value - entry.value).abs() < 0.04
                        ? color.withValues(alpha: 0.22)
                        : const Color(0xFF0D1624),
                    border: Border.all(
                      color: (value - entry.value).abs() < 0.04
                          ? color
                          : const Color(0xFF20354A),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    entry.key,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 6,
                      color: (value - entry.value).abs() < 0.04
                          ? color
                          : Colors.white70,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isCompact) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () {
            setState(() {
              _current = HudSettings.defaults;
            });
          },
          icon: const Icon(Icons.restore, size: 14, color: RetroColors.textMuted),
          label: Text(
            'RESTABLECER VALORES',
            style: GoogleFonts.pressStart2p(
              fontSize: isCompact ? 7 : 7.5,
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
                  fontSize: 7.5,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(width: 8),
            RetroArcadeButton(
              text: 'GUARDAR AJUSTES',
              icon: Icons.check,
              primaryColor: RetroColors.cyan,
              fontSize: 7.5,
              onPressed: () async {
                await ref
                    .read(hudSettingsControllerProvider.notifier)
                    .updateSettings(_current);
                if (mounted) {
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
    );
  }
}
