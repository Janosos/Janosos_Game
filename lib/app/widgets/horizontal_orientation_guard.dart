import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/platform/pwa_install_service.dart';
import 'retro_pixel_widgets.dart';

/// Ensures the game stays in horizontal / landscape orientation across all platforms.
/// If a mobile device or browser is held in portrait, presents a sleek arcade rotation prompt.
class HorizontalOrientationGuard extends StatefulWidget {
  const HorizontalOrientationGuard({super.key, required this.child});

  final Widget child;

  @override
  State<HorizontalOrientationGuard> createState() =>
      _HorizontalOrientationGuardState();
}

class _HorizontalOrientationGuardState
    extends State<HorizontalOrientationGuard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enforceLandscape();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enforceLandscape();
    }
  }

  void _enforceLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final isPortrait = media.height > media.width && media.width < 768;

    if (!isPortrait) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF070D16),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: RetroArcadeCard(
            borderColor: RetroColors.cyan,
            accentHeaderColor: RetroColors.gold,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.screen_rotation,
                  color: RetroColors.cyan,
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  'GIRA TU DISPOSITIVO',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: RetroColors.gold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Another retro runner game requiere orientación horizontal (Landscape) para jugar.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vt323(
                    fontSize: 17,
                    color: RetroColors.textBright,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 20),
                if (PwaInstallService.isWeb) ...[
                  RetroArcadeButton(
                    text: 'PANTALLA COMPLETA HORIZONTAL',
                    icon: Icons.fullscreen,
                    primaryColor: RetroColors.cyan,
                    textColor: Colors.black,
                    fontSize: 8,
                    isFullWidth: true,
                    onPressed: () => PwaInstallService.enterFullscreen(),
                  ),
                ] else ...[
                  Text(
                    '↻ Coloca tu pantalla de forma horizontal para continuar',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vt323(
                      fontSize: 15,
                      color: RetroColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
