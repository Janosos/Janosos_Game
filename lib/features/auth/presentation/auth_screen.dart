import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../application/auth_controller.dart';
import '../domain/auth_models.dart';

enum _AuthFormMode { signIn, register }

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
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
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
                              'JANOSOS V6',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _mode == _AuthFormMode.signIn
                                        ? 'INICIAR SESIÓN'
                                        : 'CREAR CUENTA',
                                  ),
                          ),
                          if (_mode == _AuthFormMode.signIn)
                            TextButton(
                              onPressed: state.isBusy
                                  ? null
                                  : _requestPasswordReset,
                              child: const Text('Olvidé mi contraseña'),
                            ),
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
              ),
            ),
          ),
        ),
      ),
    );
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
