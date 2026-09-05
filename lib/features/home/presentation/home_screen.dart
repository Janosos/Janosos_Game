import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/app_providers.dart';
import '../../../app/widgets/retro_pixel_widgets.dart';
import '../../auth/application/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final environment = ref.watch(appEnvironmentProvider);
    final user = auth.session.user;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return ListView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      children: [
        // Banner retro arcade de título
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12),
            child: Image.asset(
              'assets/images/title_retro.png',
              height: isMobile ? 54 : 72,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, _, _) => Text(
                '★ JANOSOS ARCADE ★',
                style: GoogleFonts.pressStart2p(
                  fontSize: isMobile ? 15 : 20,
                  color: RetroColors.cyan,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Saludo con tipografía retro
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'JUGADOR: ${(user?.displayName ?? 'INVITADO').toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.pressStart2p(
                        fontSize: isMobile ? 11 : 13,
                        fontWeight: FontWeight.bold,
                        color: RetroColors.cyan,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.isGuest == true
                        ? 'PARTIDA LOCAL • ESTE DISPOSITIVO'
                        : environment.usesLocalBackend
                        ? 'MODO LOCAL DE DESARROLLO'
                        : 'CUENTA CONECTADA • NUBE ACTIVA',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.vt323(
                      fontSize: isMobile ? 16 : 18,
                      color: RetroColors.textMuted,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            RetroBadge(
              text: user?.isGuest == true ? 'INVITADO' : 'ONLINE',
              color: user?.isGuest == true
                  ? RetroColors.gold
                  : RetroColors.green,
            ),
          ],
        ),

        if (user?.isGuest == true) ...[
          const SizedBox(height: 14),
          RetroArcadeCard(
            borderColor: RetroColors.gold.withValues(alpha: 0.6),
            backgroundColor: const Color(0xFF141A12),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const PixelIconAsset(
                  assetName: PixelIconAsset.gamepad,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PARTIDA GUARDADA EN ESTE EQUIPO',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.pressStart2p(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: RetroColors.gold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tus desbloqueos se guardan aquí. Puedes conectar cloud cuando quieras.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.vt323(
                          fontSize: 15,
                          color: Colors.white70,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                RetroArcadeButton(
                  text: 'CONECTAR',
                  fontSize: 8,
                  primaryColor: RetroColors.gold,
                  onPressed: () => context.go('/settings'),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        // Tarjeta principal: JUGAR AHORA / CORREDOR CLÁSICO
        RetroArcadeCard(
          borderColor: RetroColors.cyan,
          accentHeaderColor: RetroColors.cyan,
          glow: true,
          padding: EdgeInsets.all(isMobile ? 18 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PixelIconAsset(
                        assetName: PixelIconAsset.gamepad,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CORREDOR CLÁSICO',
                        style: GoogleFonts.pressStart2p(
                          fontSize: isMobile ? 11 : 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const RetroBadge(
                    text: '10 NIVELES',
                    color: RetroColors.gold,
                    fontSize: 8,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Corre con reglas normalizadas o enfréntate a los jefes de la campaña completa.',
                style: GoogleFonts.vt323(
                  fontSize: isMobile ? 18 : 20,
                  color: RetroColors.textBright,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              RetroArcadeButton(
                text: 'INSERT COIN / JUGAR AHORA',
                pixelIcon: const PixelIconAsset(
                  assetName: PixelIconAsset.coin,
                  size: 20,
                ),
                primaryColor: RetroColors.cyan,
                fontSize: isMobile ? 9 : 11,
                isFullWidth: true,
                onPressed: () => context.go('/game?experience=standard'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Acciones secundarias en cuadrícula arcade responsiva
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _HomeAction(
              pixelAsset: PixelIconAsset.trophy,
              title: 'Campaña Mundial',
              subtitle: '10 mundos y jefes arcade.',
              badgeText: 'CAMPAÑA',
              badgeColor: RetroColors.gold,
              isFullWidth: isMobile,
              onTap: () => context.go('/campaign'),
            ),
            _HomeAction(
              pixelAsset: PixelIconAsset.coin,
              title: 'Leaderboard',
              subtitle: 'Récords y puntuaciones globales.',
              badgeText: 'RANKING',
              badgeColor: RetroColors.cyan,
              isFullWidth: isMobile,
              onTap: () => context.go('/leaderboard'),
            ),
            _HomeAction(
              pixelAsset: PixelIconAsset.gamepad,
              title: 'Personajes',
              subtitle: 'Habilidades exclusivas y catálogo.',
              badgeText: 'ROSTER',
              badgeColor: RetroColors.magenta,
              isFullWidth: isMobile,
              onTap: () => context.go('/characters'),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.pixelAsset,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.onTap,
    this.isFullWidth = false,
  });

  final String pixelAsset;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final VoidCallback onTap;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : 270,
      child: RetroArcadeCard(
        borderColor: const Color(0xFF1E354F),
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PixelIconAsset(assetName: pixelAsset, size: 32),
                RetroBadge(text: badgeText, color: badgeColor, fontSize: 7),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.pressStart2p(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.vt323(
                fontSize: 15,
                color: RetroColors.textMuted,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
