import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/platform/pwa_install_service.dart';
import 'retro_pixel_widgets.dart';

/// Retro Arcade dialog that guides the user to install Janosos Game as a PWA
/// on iPhone (iOS Safari) or Android, and toggle true fullscreen mode.
class PwaInstallDialog extends StatelessWidget {
  const PwaInstallDialog({super.key});

  static Future<void> show(BuildContext context) async {
    // If on Android and native prompt is available, trigger it first
    if (PwaInstallService.isAndroidWeb) {
      final prompted = await PwaInstallService.promptInstall();
      if (prompted) {
        await PwaInstallService.enterFullscreen();
        return;
      }
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => const PwaInstallDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIos = PwaInstallService.isIosWeb;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1B2D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: RetroColors.cyan, width: 2),
            boxShadow: [
              BoxShadow(
                color: RetroColors.cyan.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.install_mobile, color: RetroColors.gold, size: 22),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isIos ? 'INSTALAR EN IPHONE' : 'INSTALAR COMO APP',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: RetroColors.gold,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Instala Janosos Game en tu dispositivo móvil para jugarlo en Pantalla Completa sin barras de navegación.',
                  style: GoogleFonts.vt323(
                    fontSize: 16,
                    color: RetroColors.textBright,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Pasos según sistema operativo
                if (isIos) ...[
                  _InstructionStep(
                    number: '1',
                    icon: Icons.ios_share,
                    title: 'Toca el botón Compartir',
                    description:
                        'En la barra inferior de Safari, presiona el icono de Compartir [ ↑ ].',
                  ),
                  const SizedBox(height: 10),
                  _InstructionStep(
                    number: '2',
                    icon: Icons.add_box_outlined,
                    title: 'Agregar a pantalla de inicio',
                    description:
                        'Baja en el menú y selecciona "Agregar a pantalla de inicio".',
                  ),
                  const SizedBox(height: 10),
                  _InstructionStep(
                    number: '3',
                    icon: Icons.fullscreen,
                    title: 'Ábrelo y juega en Full Screen',
                    description:
                        'Abre el icono desde tu pantalla para jugar en horizontal y pantalla completa.',
                  ),
                ] else ...[
                  _InstructionStep(
                    number: '1',
                    icon: Icons.more_vert,
                    title: 'Menú de opciones',
                    description:
                        'Toca los tres puntos ( ⋮ ) en la esquina del navegador Chrome o Edge.',
                  ),
                  const SizedBox(height: 10),
                  _InstructionStep(
                    number: '2',
                    icon: Icons.download_for_offline,
                    title: 'Instalar Aplicación',
                    description:
                        'Selecciona "Instalar aplicación" o "Agregar a la pantalla principal".',
                  ),
                  const SizedBox(height: 10),
                  _InstructionStep(
                    number: '3',
                    icon: Icons.smartphone,
                    title: 'Acceso directo arcade',
                    description:
                        '¡Listo! Se ejecutará como una app nativa en horizontal completa.',
                  ),
                ],

                const SizedBox(height: 18),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: RetroColors.textMuted),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          'CERRAR',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 8,
                            color: RetroColors.textBright,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await PwaInstallService.enterFullscreen();
                          if (context.mounted) Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: RetroColors.cyan,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.fullscreen, size: 16),
                        label: Text(
                          'PANTALLA COMPLETA',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF070D16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1E354F), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: RetroColors.cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: RetroColors.cyan, width: 1),
            ),
            child: Text(
              number,
              style: GoogleFonts.pressStart2p(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: RetroColors.cyan,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: RetroColors.gold, size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title.toUpperCase(),
                        style: GoogleFonts.pressStart2p(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.vt323(
                    fontSize: 15,
                    color: RetroColors.textMuted,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
