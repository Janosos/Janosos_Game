import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_models.dart';
import '../application/game_settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final environment = ref.watch(appEnvironmentProvider);
    final gameSettings = ref.watch(gameSettingsControllerProvider);
    final user = auth.session.user;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Configuración',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CUENTA', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(user?.displayName ?? 'Jugador'),
                  subtitle: Text(user?.email ?? ''),
                  trailing: environment.usesLocalBackend
                      ? const Chip(label: Text('LOCAL'))
                      : const Chip(label: Text('CLOUD')),
                ),
                if (auth.error != null)
                  _MessageBox(message: auth.error!, isError: true),
                if (auth.notice != null) _MessageBox(message: auth.notice!),
                const Divider(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: auth.isBusy
                          ? null
                          : () => _link(ref, AuthProviderId.google),
                      icon: const Icon(Icons.account_circle_outlined),
                      label: const Text('Vincular Google'),
                    ),
                    OutlinedButton.icon(
                      onPressed: auth.isBusy
                          ? null
                          : () => _link(ref, AuthProviderId.apple),
                      icon: const Icon(Icons.apple),
                      label: const Text('Vincular Apple'),
                    ),
                    OutlinedButton.icon(
                      onPressed: auth.isBusy
                          ? null
                          : () => _changePassword(context, ref),
                      icon: const Icon(Icons.password_outlined),
                      label: const Text('Cambiar contraseña'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: gameSettings.reduceMotion,
                onChanged: auth.isBusy
                    ? null
                    : (enabled) => ref
                          .read(gameSettingsControllerProvider.notifier)
                          .setReduceMotion(enabled),
                secondary: const Icon(Icons.motion_photos_off_outlined),
                title: const Text('Reducir movimiento'),
                subtitle: const Text(
                  'Detiene fondos decorativos y oscilaciones no esenciales.',
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: gameSettings.audioEnabled,
                onChanged: auth.isBusy
                    ? null
                    : (enabled) => ref
                          .read(gameSettingsControllerProvider.notifier)
                          .setAudioEnabled(enabled),
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('Audio'),
                subtitle: const Text('Música y efectos durante la partida.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: auth.isBusy
                      ? null
                      : () =>
                            ref.read(authControllerProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: auth.isBusy
                      ? null
                      : () => _confirmDeletion(context, ref),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Eliminar mi cuenta'),
                  style: FilledButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _link(WidgetRef ref, AuthProviderId provider) async {
    await ref.read(authControllerProvider.notifier).linkProvider(provider);
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
    if (password == null || password.length < 8) {
      return;
    }
    await ref.read(authControllerProvider.notifier).updatePassword(password);
  }

  Future<void> _confirmDeletion(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).deleteAccount();
    }
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar contraseña'),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nueva contraseña',
          helperText: 'Mínimo 8 caracteres',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Actualizar'),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar cuenta permanentemente'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Se eliminarán la cuenta y los datos sincronizados. Por seguridad, '
              'debes haber iniciado sesión en los últimos 10 minutos. Escribe '
              'ELIMINAR para confirmar.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Confirmación'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _controller.text == 'ELIMINAR'
              ? () => Navigator.pop(context, true)
              : null,
          child: const Text('Eliminar definitivamente'),
        ),
      ],
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message),
    );
  }
}
