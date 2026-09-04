import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: const Text('JANOSOS V6'),
        actions: [
          IconButton(
            tooltip: 'Configuración y cuenta',
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (index) {
                    context.go(_destinations[index].path);
                  },
                  destinations: [
                    for (final destination in _destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            )
          : child,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                context.go(_destinations[index].path);
              },
              destinations: [
                for (final destination in _destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
              ],
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
