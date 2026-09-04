import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../auth/application/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final environment = ref.watch(appEnvironmentProvider);
    final user = auth.session.user;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Semantics(
          header: true,
          child: Text(
            'Hola, ${user?.displayName ?? 'jugador'}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          environment.usesLocalBackend
              ? 'Modo local de desarrollo: tus pruebas se guardan en este dispositivo.'
              : 'Tu cuenta está conectada y lista para sincronizar.',
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CORREDOR CLÁSICO',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Corre con reglas normalizadas o entra a la campaña completa de diez niveles.',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.go('/game?experience=standard'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('JUGAR AHORA'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _HomeAction(
              icon: Icons.map_outlined,
              title: 'Progresión mundial',
              subtitle: '10 niveles y sus jefes.',
              onTap: () => context.go('/campaign'),
            ),
            _HomeAction(
              icon: Icons.leaderboard_outlined,
              title: 'Leaderboard',
              subtitle: 'Clasificación por personaje.',
              onTap: () => context.go('/leaderboard'),
            ),
            _HomeAction(
              icon: Icons.groups_outlined,
              title: 'Personajes',
              subtitle: 'Habilidades exclusivas y progreso.',
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
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 36),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(subtitle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
