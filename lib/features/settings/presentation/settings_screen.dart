import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/app_providers.dart';
import '../../../app/widgets/pwa_install_dialog.dart';
import '../../../app/widgets/retro_pixel_widgets.dart';
import '../../../core/platform/pwa_install_service.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_models.dart';
import '../application/game_settings_controller.dart';
import 'hud_customizer_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final environment = ref.watch(appEnvironmentProvider);
    final gameSettings = ref.watch(gameSettingsControllerProvider);
    final user = auth.session.user;
    final media = MediaQuery.sizeOf(context);
    final isCompactHeight = media.height < 520;
    final isWide = media.width >= 700;

    final accountCard = RetroArcadeCard(
      borderColor: user?.isGuest == true ? RetroColors.gold : RetroColors.cyan,
      accentHeaderColor:
          user?.isGuest == true ? RetroColors.gold : RetroColors.cyan,
      padding: EdgeInsets.all(isCompactHeight ? 12 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CUENTA & PERFIL',
                style: GoogleFonts.pressStart2p(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: user?.isGuest == true
                      ? RetroColors.gold
                      : RetroColors.cyan,
                  letterSpacing: 1.2,
                ),
              ),
              RetroBadge(
                text: user?.isGuest == true
                    ? 'INVITADO'
                    : environment.usesLocalBackend
                    ? 'LOCAL'
                    : 'CLOUD ONLINE',
                color: user?.isGuest == true
                    ? RetroColors.gold
                    : environment.usesLocalBackend
                    ? RetroColors.cyan
                    : RetroColors.green,
                fontSize: 8,
              ),
            ],
          ),
          SizedBox(height: isCompactHeight ? 10 : 16),
          Row(
            children: [
              Container(
                width: isCompactHeight ? 38 : 44,
                height: isCompactHeight ? 38 : 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF142236),
                  border: Border.all(
                    color: user?.isGuest == true
                        ? RetroColors.gold
                        : RetroColors.cyan,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  user?.isGuest == true
                      ? Icons.person_outline
                      : Icons.verified_user_outlined,
                  color: user?.isGuest == true
                      ? RetroColors.gold
                      : RetroColors.cyan,
                  size: isCompactHeight ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (user?.displayName ?? 'JUGADOR INVITADO').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.pressStart2p(
                        fontSize: isCompactHeight ? 9 : 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.isGuest == true
                          ? 'Partida local guardada en este dispositivo'
                          : user?.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.vt323(
                        fontSize: isCompactHeight ? 15 : 17,
                        color: RetroColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (auth.error != null)
            _RetroMessageBox(message: auth.error!, isError: true),
          if (auth.notice != null) _RetroMessageBox(message: auth.notice!),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFF1E354F)),
          const SizedBox(height: 14),
          if (user?.isGuest == true) ...[
            Text(
              'Tu partida se guarda localmente. Conecta una cuenta para sincronizar con la nube y acceder al ranking:',
              style: GoogleFonts.vt323(
                fontSize: 16,
                color: RetroColors.textBright,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            RetroArcadeButton(
              text: 'CONECTAR O CREAR CUENTA',
              icon: Icons.cloud_upload_outlined,
              primaryColor: RetroColors.gold,
              fontSize: 8,
              isFullWidth: true,
              onPressed: auth.isBusy
                  ? null
                  : () => ref.read(authControllerProvider.notifier).signOut(),
            ),
          ] else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (!environment.usesLocalBackend) ...[
                  RetroArcadeButton(
                    text: 'VINCULAR GOOGLE',
                    icon: Icons.account_circle_outlined,
                    primaryColor: RetroColors.cyan,
                    fontSize: 7.5,
                    onPressed: auth.isBusy
                        ? null
                        : () => _link(ref, AuthProviderId.google),
                  ),
                ],
                RetroArcadeButton(
                  text: 'CAMBIAR PASSWORD',
                  icon: Icons.password_outlined,
                  primaryColor: const Color(0xFF1E354F),
                  textColor: Colors.white,
                  fontSize: 7.5,
                  onPressed: auth.isBusy
                      ? null
                      : () => _changePassword(context, ref),
                ),
              ],
            ),
        ],
      ),
    );

    final gameSettingsCard = RetroArcadeCard(
      borderColor: const Color(0xFF1E354F),
      accentHeaderColor: RetroColors.magenta,
      padding: EdgeInsets.all(isCompactHeight ? 12 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AJUSTES DE JUEGO',
            style: GoogleFonts.pressStart2p(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: RetroColors.magenta,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: isCompactHeight ? 10 : 16),
          _RetroSwitchTile(
            icon: Icons.motion_photos_off_outlined,
            title: 'REDUCIR MOVIMIENTO',
            subtitle: 'Detiene fondos y animaciones adicionales.',
            value: gameSettings.reduceMotion,
            isCompact: isCompactHeight,
            onChanged: auth.isBusy
                ? null
                : (enabled) => ref
                      .read(gameSettingsControllerProvider.notifier)
                      .setReduceMotion(enabled),
          ),
          const Divider(height: 16, color: Color(0xFF1E354F)),
          _RetroSwitchTile(
            icon: Icons.music_note_outlined,
            title: 'MÚSICA DE FONDO',
            subtitle: 'Banda sonora 8-bit en bucle durante la partida.',
            value: gameSettings.musicEnabled,
            isCompact: isCompactHeight,
            onChanged: auth.isBusy
                ? null
                : (enabled) => ref
                      .read(gameSettingsControllerProvider.notifier)
                      .setMusicEnabled(enabled),
          ),
          const Divider(height: 16, color: Color(0xFF1E354F)),
          _RetroSwitchTile(
            icon: Icons.volume_up_outlined,
            title: 'EFECTOS DE SONIDO',
            subtitle: 'Sonidos de saltos, disparos, impactos y acciones.',
            value: gameSettings.sfxEnabled,
            isCompact: isCompactHeight,
            onChanged: auth.isBusy
                ? null
                : (enabled) => ref
                      .read(gameSettingsControllerProvider.notifier)
                      .setSfxEnabled(enabled),
          ),
        ],
      ),
    );

    final hudControlsCard = RetroArcadeCard(
      borderColor: RetroColors.green,
      accentHeaderColor: RetroColors.green,
      padding: EdgeInsets.all(isCompactHeight ? 12 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTROLES HUD / BOTONES',
            style: GoogleFonts.pressStart2p(
              fontSize: isCompactHeight ? 9 : 10,
              fontWeight: FontWeight.bold,
              color: RetroColors.green,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: isCompactHeight ? 8 : 12),
          Text(
            'Personaliza tamaño, opacidad y posición de los botones en partida (D-Pad, Habilidad y Golpe Jefe). Guardado local.',
            style: GoogleFonts.vt323(
              fontSize: isCompactHeight ? 15 : 17,
              color: RetroColors.textBright,
              height: 1.2,
            ),
          ),
          SizedBox(height: isCompactHeight ? 10 : 14),
          RetroArcadeButton(
            text: 'PERSONALIZAR BOTONES HUD',
            icon: Icons.tune,
            primaryColor: RetroColors.green,
            textColor: Colors.black,
            fontSize: 8,
            isFullWidth: true,
            onPressed: () => HudCustomizerDialog.show(context),
          ),
        ],
      ),
    );

    final pwaCard = !PwaInstallService.isWeb
        ? null
        : RetroArcadeCard(
            borderColor: RetroColors.cyan,
            accentHeaderColor: RetroColors.cyan,
            padding: EdgeInsets.all(isCompactHeight ? 12 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INSTALACIÓN & PANTALLA COMPLETA',
                  style: GoogleFonts.pressStart2p(
                    fontSize: isCompactHeight ? 9 : 10,
                    fontWeight: FontWeight.bold,
                    color: RetroColors.cyan,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: isCompactHeight ? 8 : 12),
                Text(
                  PwaInstallService.isStandalone
                      ? 'La aplicación ya está ejecutándose en modo app / pantalla completa.'
                      : 'Instala Janosos Game como app en tu navegador Android o iPhone para jugar en pantalla completa horizontal sin marcos.',
                  style: GoogleFonts.vt323(
                    fontSize: isCompactHeight ? 15 : 17,
                    color: RetroColors.textBright,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: isCompactHeight ? 10 : 14),
                Row(
                  children: [
                    if (!PwaInstallService.isStandalone) ...[
                      Expanded(
                        child: RetroArcadeButton(
                          text: 'INSTALAR APP',
                          icon: Icons.install_mobile,
                          primaryColor: RetroColors.cyan,
                          textColor: Colors.black,
                          fontSize: 8,
                          onPressed: () => PwaInstallDialog.show(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: RetroArcadeButton(
                        text: 'PANTALLA COMPLETA',
                        icon: Icons.fullscreen,
                        primaryColor: RetroColors.gold,
                        textColor: Colors.black,
                        fontSize: 8,
                        onPressed: () => PwaInstallService.enterFullscreen(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

    final sessionCard = RetroArcadeCard(
      borderColor: const Color(0xFF1E354F),
      backgroundColor: const Color(0xFF0F141E),
      padding: EdgeInsets.all(isCompactHeight ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RetroArcadeButton(
            text: user?.isGuest == true
                ? 'SALIR AL MENÚ PRINCIPAL'
                : 'CERRAR SESIÓN',
            icon: user?.isGuest == true ? Icons.exit_to_app : Icons.logout,
            primaryColor: const Color(0xFF1E354F),
            textColor: Colors.white70,
            fontSize: 8,
            onPressed: auth.isBusy
                ? null
                : () => ref.read(authControllerProvider.notifier).signOut(),
          ),
          if (user?.isGuest != true) ...[
            const SizedBox(height: 10),
            RetroArcadeButton(
              text: 'ELIMINAR MI CUENTA',
              icon: Icons.delete_forever_outlined,
              primaryColor: RetroColors.magenta.withValues(alpha: 0.25),
              textColor: RetroColors.magenta,
              fontSize: 8,
              onPressed: auth.isBusy
                  ? null
                  : () => _confirmDeletion(context, ref),
            ),
          ],
        ],
      ),
    );

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isCompactHeight ? 16 : 24,
        vertical: isCompactHeight ? 12 : 20,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'CONFIGURACIÓN',
                    style: GoogleFonts.pressStart2p(
                      fontSize: isCompactHeight ? 12 : 15,
                      fontWeight: FontWeight.bold,
                      color: RetroColors.cyan,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ajustes de partida, audio y gestión de cuenta.',
                  style: GoogleFonts.vt323(
                    fontSize: isCompactHeight ? 15 : 17,
                    color: RetroColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: isCompactHeight ? 12 : 18),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    accountCard,
                    const SizedBox(height: 14),
                    sessionCard,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    gameSettingsCard,
                    const SizedBox(height: 14),
                    hudControlsCard,
                    if (pwaCard != null) ...[
                      const SizedBox(height: 14),
                      pwaCard,
                    ],
                  ],
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              accountCard,
              const SizedBox(height: 14),
              gameSettingsCard,
              const SizedBox(height: 14),
              hudControlsCard,
              if (pwaCard != null) ...[
                const SizedBox(height: 14),
                pwaCard,
              ],
              const SizedBox(height: 14),
              sessionCard,
            ],
          ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Version 6.2 made by Jano and Chema',
                textAlign: TextAlign.center,
                style: GoogleFonts.pressStart2p(
                  fontSize: isCompactHeight ? 8 : 9.5,
                  color: RetroColors.cyan,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '★ ANOTHER RETRO RUNNER GAME ★',
                textAlign: TextAlign.center,
                style: GoogleFonts.vt323(
                  fontSize: isCompactHeight ? 13 : 15,
                  color: RetroColors.gold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isCompactHeight ? 12 : 24),
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

class _RetroSwitchTile extends StatelessWidget {
  const _RetroSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isCompact,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: isCompact ? 20 : 24,
          color: value ? RetroColors.cyan : RetroColors.textMuted,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.pressStart2p(
                  fontSize: isCompact ? 8 : 9,
                  fontWeight: FontWeight.bold,
                  color: value ? Colors.white : Colors.white70,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.vt323(
                  fontSize: isCompact ? 14 : 16,
                  color: RetroColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: RetroColors.cyanDim,
          activeThumbColor: RetroColors.cyan,
          inactiveThumbColor: Colors.grey.shade600,
          inactiveTrackColor: const Color(0xFF132032),
        ),
      ],
    );
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
      backgroundColor: const Color(0xFF0C1420),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: RetroColors.cyan, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      title: Text(
        'CAMBIAR CONTRASEÑA',
        style: GoogleFonts.pressStart2p(
          fontSize: 11,
          color: RetroColors.cyan,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        style: GoogleFonts.vt323(fontSize: 18, color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Nueva contraseña',
          helperText: 'Mínimo 8 caracteres',
          helperStyle: GoogleFonts.vt323(fontSize: 14, color: RetroColors.textMuted),
          labelStyle: GoogleFonts.vt323(fontSize: 16, color: RetroColors.cyan),
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'CANCELAR',
            style: GoogleFonts.pressStart2p(fontSize: 8, color: RetroColors.textMuted),
          ),
        ),
        RetroArcadeButton(
          text: 'ACTUALIZAR',
          primaryColor: RetroColors.cyan,
          fontSize: 8,
          onPressed: () => Navigator.pop(context, _controller.text),
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
      backgroundColor: const Color(0xFF160A10),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: RetroColors.magenta, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      title: Text(
        'ELIMINAR CUENTA',
        style: GoogleFonts.pressStart2p(
          fontSize: 11,
          color: RetroColors.magenta,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se eliminarán la cuenta y los datos sincronizados permanentemente. '
              'Por seguridad, debes haber iniciado sesión recientemente. '
              'Escribe ELIMINAR para confirmar.',
              style: GoogleFonts.vt323(
                fontSize: 16,
                color: RetroColors.textBright,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Escribe ELIMINAR',
                labelStyle: GoogleFonts.vt323(fontSize: 16, color: RetroColors.magenta),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'CANCELAR',
            style: GoogleFonts.pressStart2p(fontSize: 8, color: RetroColors.textMuted),
          ),
        ),
        RetroArcadeButton(
          text: 'ELIMINAR DEFINITIVAMENTE',
          primaryColor: RetroColors.magenta,
          fontSize: 8,
          onPressed: _controller.text == 'ELIMINAR'
              ? () => Navigator.pop(context, true)
              : null,
        ),
      ],
    );
  }
}

class _RetroMessageBox extends StatelessWidget {
  const _RetroMessageBox({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? RetroColors.magenta : RetroColors.cyan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFF1D0C13) : const Color(0xFF0C1929),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.vt323(
                fontSize: 15,
                color: RetroColors.textBright,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

