import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/retro_pixel_widgets.dart';

class JanososAppShell extends StatelessWidget {
  const JanososAppShell({
    required this.child,
    required this.location,
    super.key,
  });

  final Widget child;
  final String location;

  static const _destinations = <_AppDestination>[
    _AppDestination('/home', 'Inicio', Icons.home_outlined),
    _AppDestination('/characters', 'Personajes', Icons.groups_outlined),
    _AppDestination('/leaderboard', 'Ranking', Icons.leaderboard_outlined),
    _AppDestination('/campaign', 'Campaña', Icons.map_outlined),
    _AppDestination('/store', 'Tienda', Icons.storefront_outlined),
  ];

  int get _selectedIndex {
    final index = _destinations.indexWhere(
      (destination) => location.startsWith(destination.path),
    );
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final isCompactHeight = media.height < 500;
    final isLandscape = media.width > media.height;
    final wide = media.width >= 900 || (isLandscape && media.width >= 580 && isCompactHeight);
    const cyan = Color(0xFF29FFE4);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isCompactHeight ? 36 : 54,
        backgroundColor: const Color(0xFF070D16),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixelIconAsset(
              assetName: PixelIconAsset.gamepad,
              size: isCompactHeight ? 18 : 24,
            ),
            SizedBox(width: isCompactHeight ? 6 : 10),
            Text(
              'JANOSOS V6',
              style: GoogleFonts.pressStart2p(
                fontSize: isCompactHeight ? 10 : 13,
                fontWeight: FontWeight.bold,
                color: cyan,
                letterSpacing: isCompactHeight ? 1.2 : 2,
                shadows: [
                  Shadow(color: cyan.withValues(alpha: 0.8), blurRadius: 10),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: const Color(0xFF1E354F)),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1E354F), width: 1.5),
            ),
            child: IconButton(
              tooltip: 'Configuración y cuenta',
              onPressed: () => context.go('/settings'),
              padding: EdgeInsets.zero,
              constraints: isCompactHeight
                  ? const BoxConstraints(minWidth: 30, minHeight: 30)
                  : null,
              icon: Icon(
                Icons.settings_outlined,
                color: cyan,
                size: isCompactHeight ? 16 : 20,
              ),
            ),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  minWidth: isCompactHeight ? 56 : 72,
                  backgroundColor: const Color(0xFF070D16),
                  selectedIndex: _selectedIndex,
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: cyan),
                  unselectedIconTheme: const IconThemeData(
                    color: Color(0xFF7A9BB8),
                  ),
                  selectedLabelTextStyle: GoogleFonts.pressStart2p(
                    fontSize: isCompactHeight ? 6 : 8,
                    fontWeight: FontWeight.bold,
                    color: cyan,
                  ),
                  unselectedLabelTextStyle: GoogleFonts.pressStart2p(
                    fontSize: isCompactHeight ? 6 : 8,
                    color: const Color(0xFF7A9BB8),
                  ),
                  indicatorColor: cyan.withValues(alpha: 0.15),
                  indicatorShape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: cyan, width: 1.5),
                  ),
                  onDestinationSelected: (index) {
                    context.go(_destinations[index].path);
                  },
                  destinations: [
                    for (final destination in _destinations)
                      NavigationRailDestination(
                        icon: Icon(
                          destination.icon,
                          size: isCompactHeight ? 16 : 22,
                        ),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1, color: Color(0xFF1E354F)),
                Expanded(child: child),
              ],
            )
          : child,
      bottomNavigationBar: wide
          ? null
          : Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF1E354F), width: 2),
                ),
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  height: isCompactHeight ? 56 : 68,
                  labelTextStyle: WidgetStateProperty.resolveWith(
                    (states) => GoogleFonts.pressStart2p(
                      fontSize: isCompactHeight ? 7 : 8,
                      fontWeight: states.contains(WidgetState.selected)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: states.contains(WidgetState.selected)
                          ? cyan
                          : const Color(0xFF7A9BB8),
                    ),
                  ),
                ),
                child: NavigationBar(
                  height: isCompactHeight ? 56 : 68,
                  backgroundColor: const Color(0xFF070D16),
                  indicatorColor: cyan.withValues(alpha: 0.15),
                  indicatorShape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: cyan, width: 1.5),
                  ),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    context.go(_destinations[index].path);
                  },
                  destinations: [
                    for (final destination in _destinations)
                      NavigationDestination(
                        icon: Icon(
                          destination.icon,
                          size: isCompactHeight ? 18 : 22,
                        ),
                        label: destination.label,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _AppDestination {
  const _AppDestination(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;
}
