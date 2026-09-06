import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/app_providers.dart';
import '../../../app/widgets/retro_pixel_widgets.dart';
import '../../../core/config/app_environment.dart';
import '../application/auth_controller.dart';
import '../domain/auth_models.dart';

enum _AuthFormMode { signIn, register }

enum _AuthView { welcome, form }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  _AuthView _view = _AuthView.welcome;
  _AuthFormMode _mode = _AuthFormMode.signIn;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final environment = ref.watch(appEnvironmentProvider);
    if (state.session.status == AuthSessionStatus.verificationRequired) {
      return _VerificationRequiredView(email: state.session.user!.email);
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _view == _AuthView.welcome ? 960 : 480,
              ),
              child: _view == _AuthView.welcome
                  ? _buildWelcomeView(context, state, environment)
                  : _buildFormView(context, state, environment),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeView(
    BuildContext context,
    AuthViewState state,
    AppEnvironment environment,
  ) {
    const cyan = RetroColors.cyan;
    const gold = RetroColors.gold;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Image.asset(
            'assets/images/title_retro.png',
            height: 68,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: RetroBadge(
            text: 'JANOSOS V6 • RETRO RUNNER',
            color: RetroColors.cyan,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 14),
        Semantics(
          header: true,
          child: Text(
            '¡SELECCIONA TU MODO!',
            textAlign: TextAlign.center,
            style: GoogleFonts.pressStart2p(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Partida rápida local o cuenta con sincronización en la nube:',
          textAlign: TextAlign.center,
          style: GoogleFonts.vt323(
            fontSize: 18,
            color: RetroColors.textMuted,
            letterSpacing: 1.1,
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 20),
          _StatusBanner(
            icon: Icons.error_outline,
            text: state.error!,
            isError: true,
          ),
        ],
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final localCard = _buildLocalOptionCard(context, state, cyan);
            final cloudCard = _buildCloudOptionCard(
              context,
              gold,
              environment,
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: localCard),
                  const SizedBox(width: 20),
                  Expanded(child: cloudCard),
                ],
              );
            }
            return Column(
              children: [localCard, const SizedBox(height: 20), cloudCard],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocalOptionCard(
    BuildContext context,
    AuthViewState state,
    Color accentColor,
  ) {
    final isContinuing =
        state.isBusy && state.operation == AuthOperation.continuingAsGuest;

    return RetroArcadeCard(
      borderColor: accentColor,
      accentHeaderColor: accentColor,
      glow: true,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  border: Border.all(color: accentColor, width: 1.5),
                ),
                child: const PixelIconAsset(
                  assetName: PixelIconAsset.gamepad,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RetroBadge(
                      text: 'SIN REGISTRO • AL INSTANTE',
                      color: accentColor,
                      fontSize: 8,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'MODO LOCAL',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Juega de inmediato sin contraseñas ni correos. Tu progreso se guarda directamente en este dispositivo.',
            style: GoogleFonts.vt323(
              fontSize: 17,
              color: RetroColors.textBright,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFF1E354F)),
          const SizedBox(height: 14),
          _FeatureRow(
            icon: Icons.bolt,
            color: accentColor,
            title: 'Campaña y Clásico',
            subtitle: '10 niveles con jefes disponibles de inmediato.',
          ),
          const SizedBox(height: 10),
          _FeatureRow(
            icon: Icons.save_outlined,
            color: accentColor,
            title: 'Guardado Local',
            subtitle: 'Monedas, mejoras y récords en este equipo.',
          ),
          const SizedBox(height: 10),
          _FeatureRow(
            icon: Icons.wifi_off_outlined,
            color: accentColor,
            title: '100% Offline',
            subtitle: 'No requiere conexión a internet para jugar.',
          ),
          const SizedBox(height: 22),
          RetroArcadeButton(
            text: isContinuing ? 'INICIANDO…' : 'JUGAR EN MODO LOCAL',
            fontSize: 10,
            primaryColor: accentColor,
            pixelIcon: const PixelIconAsset(
              assetName: PixelIconAsset.gamepad,
              size: 20,
            ),
            isFullWidth: true,
            onPressed: state.isBusy ? null : _continueAsGuest,
          ),
        ],
      ),
    );
  }

  Widget _buildCloudOptionCard(
    BuildContext context,
    Color accentColor,
    AppEnvironment environment,
  ) {
    final isLocal = environment.usesLocalBackend;

    return RetroArcadeCard(
      borderColor: accentColor,
      accentHeaderColor: accentColor,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  border: Border.all(color: accentColor, width: 1.5),
                ),
                child: const PixelIconAsset(
                  assetName: PixelIconAsset.trophy,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RetroBadge(
                      text: isLocal
                          ? 'PERFIL EN DISPOSITIVO'
                          : 'CLOUD SYNC • MULTIPLAYER',
                      color: accentColor,
                      fontSize: 8,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isLocal ? 'CUENTA LOCAL' : 'CUENTA JANOSOS',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isLocal
                ? 'Crea o inicia sesión con tu perfil local para registrar tu nombre, compras y récords en este dispositivo.'
                : 'Conéctate para desbloquear todas las funciones comunitarias, ranking y respaldo de partidas en la nube.',
            style: GoogleFonts.vt323(
              fontSize: 17,
              color: RetroColors.textBright,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFF1E354F)),
          const SizedBox(height: 14),
          _FeatureRow(
            icon: isLocal ? Icons.badge_outlined : Icons.cloud_done_outlined,
            color: accentColor,
            title: isLocal ? 'Perfil Dedicado' : 'Nube Activa',
            subtitle: isLocal
                ? 'Nombre de jugador y compras asignadas a tu cuenta.'
                : 'Tu avance y compras respaldados en la nube.',
          ),
          const SizedBox(height: 10),
          _FeatureRow(
            icon: isLocal
                ? Icons.lock_outline
                : Icons.leaderboard_outlined,
            color: accentColor,
            title: isLocal ? 'Seguridad Local' : 'Rankings Globales',
            subtitle: isLocal
                ? 'Contraseña protegida en este equipo (Argon2id).'
                : 'Compite en el Leaderboard mundial por personaje.',
          ),
          const SizedBox(height: 10),
          _FeatureRow(
            icon: isLocal
                ? Icons.offline_pin_outlined
                : Icons.devices_outlined,
            color: accentColor,
            title: isLocal ? 'Sin Conexión' : 'Multiplataforma',
            subtitle: isLocal
                ? 'Funciona completamente sin requerir internet.'
                : 'Misma cuenta en Windows, Web y Android.',
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: RetroArcadeButton(
                  text: 'INICIAR',
                  fontSize: 9,
                  primaryColor: accentColor,
                  pixelIcon: const PixelIconAsset(
                    assetName: PixelIconAsset.coin,
                    size: 16,
                  ),
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).clearMessages();
                    setState(() {
                      _view = _AuthView.form;
                      _mode = _AuthFormMode.signIn;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RetroArcadeButton(
                  text: 'REGISTRO',
                  fontSize: 9,
                  primaryColor: const Color(0xFF1E354F),
                  textColor: accentColor,
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).clearMessages();
                    setState(() {
                      _view = _AuthView.form;
                      _mode = _AuthFormMode.register;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormView(
    BuildContext context,
    AuthViewState state,
    AppEnvironment environment,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              ref.read(authControllerProvider.notifier).clearMessages();
              setState(() => _view = _AuthView.welcome);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a selección de modo'),
          ),
        ),
        const SizedBox(height: 8),
        RetroArcadeCard(
          borderColor: RetroColors.cyan,
          accentHeaderColor: RetroColors.cyan,
          glow: true,
          padding: const EdgeInsets.all(28),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'JANOSOS ARCADE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.pressStart2p(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: RetroColors.cyan,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _mode == _AuthFormMode.signIn
                        ? 'Continúa tu progreso'
                        : 'Crea tu cuenta de jugador',
                    textAlign: TextAlign.center,
                  ),
                  if (environment.usesLocalBackend) ...[
                    const SizedBox(height: 16),
                    const _StatusBanner(
                      icon: Icons.developer_mode,
                      text:
                          'Modo local: cuentas y sesión se guardan solo en este dispositivo.',
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_mode == _AuthFormMode.register) ...[
                    TextFormField(
                      controller: _displayNameController,
                      enabled: !state.isBusy,
                      textInputAction: TextInputAction.next,
                      maxLength: 24,
                      decoration: const InputDecoration(
                        labelText: 'Nombre visible',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        final length = value?.trim().length ?? 0;
                        return length >= 2
                            ? null
                            : 'Ingresa al menos 2 caracteres.';
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _emailController,
                    enabled: !state.isBusy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      return email.contains('@')
                          ? null
                          : 'Ingresa un correo válido.';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !state.isBusy,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: [
                      _mode == _AuthFormMode.signIn
                          ? AutofillHints.password
                          : AutofillHints.newPassword,
                    ],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      helperText: _mode == _AuthFormMode.register
                          ? 'Mínimo 8 caracteres'
                          : null,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => (value?.length ?? 0) >= 8
                        ? null
                        : 'Usa al menos 8 caracteres.',
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    _StatusBanner(
                      icon: Icons.error_outline,
                      text: state.error!,
                      isError: true,
                    ),
                  ],
                  if (state.notice != null) ...[
                    const SizedBox(height: 16),
                    _StatusBanner(
                      icon: Icons.check_circle_outline,
                      text: state.notice!,
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: state.isBusy ? null : _submit,
                    child: state.isBusy
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _mode == _AuthFormMode.signIn
                                ? 'INICIAR SESIÓN'
                                : 'CREAR CUENTA',
                          ),
                  ),
                  if (_mode == _AuthFormMode.signIn)
                    TextButton(
                      onPressed: state.isBusy ? null : _requestPasswordReset,
                      child: const Text('Olvidé mi contraseña'),
                    ),
                  if (!environment.usesLocalBackend) ...[
                    const Divider(height: 32),
                    OutlinedButton.icon(
                      onPressed: state.isBusy
                          ? null
                          : () => _openProvider(AuthProviderId.google),
                      icon: const Icon(Icons.account_circle_outlined),
                      label: const Text('Continuar con Google'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: state.isBusy
                          ? null
                          : () => _openProvider(AuthProviderId.apple),
                      icon: const Icon(Icons.apple),
                      label: const Text('Continuar con Apple'),
                    ),
                  ] else ...[
                    const Divider(height: 32),
                    OutlinedButton.icon(
                      onPressed: state.isBusy ? null : _continueAsGuest,
                      icon: const Icon(Icons.sports_esports_outlined),
                      label: const Text('Jugar como Invitado (Sin Registro)'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: RetroColors.cyan,
                        side: const BorderSide(
                          color: Color(0xFF1E354F),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: state.isBusy ? null : _toggleMode,
                    child: Text(
                      _mode == _AuthFormMode.signIn
                          ? '¿No tienes cuenta? Regístrate'
                          : 'Ya tengo una cuenta',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _continueAsGuest() async {
    final controller = ref.read(authControllerProvider.notifier);
    await controller.continueAsGuest();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    final controller = ref.read(authControllerProvider.notifier);
    if (_mode == _AuthFormMode.signIn) {
      await controller.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      await controller.register(
        RegistrationRequest(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _displayNameController.text,
        ),
      );
    }
  }

  Future<void> _requestPasswordReset() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      _formKey.currentState?.validate();
      return;
    }
    await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
  }

  Future<void> _openProvider(AuthProviderId provider) async {
    await ref
        .read(authControllerProvider.notifier)
        .signInWithProvider(provider);
  }

  void _toggleMode() {
    ref.read(authControllerProvider.notifier).clearMessages();
    setState(() {
      _mode = _mode == _AuthFormMode.signIn
          ? _AuthFormMode.register
          : _AuthFormMode.signIn;
    });
  }
}

class AuthCallbackScreen extends ConsumerWidget {
  const AuthCallbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.session.isAuthenticated)
                const Icon(Icons.check_circle_outline, size: 64)
              else
                const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                state.session.isAuthenticated
                    ? 'Autenticación completada'
                    : 'Completando autenticación…',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationRequiredView extends ConsumerWidget {
  const _VerificationRequiredView({required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 64),
                  const SizedBox(height: 20),
                  Text(
                    'Confirma tu correo',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enviamos un enlace a $email. Ábrelo en este dispositivo para continuar.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                    child: const Text('Usar otra cuenta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.text,
    this.isError = false,
  });

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.pressStart2p(
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.vt323(
                  color: RetroColors.textMuted,
                  fontSize: 16,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
