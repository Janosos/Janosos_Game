import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_providers.dart';
import 'app/janosos_app.dart';
import 'core/config/app_environment.dart';
import 'core/persistence/app_database.dart';
import 'core/persistence/legacy_score_migrator.dart';
import 'core/security/protected_session_storage.dart';
import 'core/security/protected_store.dart';
import 'core/security/protected_store_factory.dart';
import 'core/session/user_session_coordinator.dart';
import 'features/auth/data/local_auth_repository.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/auth/domain/auth_repository.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final environment = AppEnvironment.fromDefines();
    final preferences = await SharedPreferences.getInstance();
    final protectedStore = createProtectedStore();
    final protectedAvailability = await protectedStore.initialize();
    final authRepository = await _createAuthRepository(
      environment: environment,
      preferences: preferences,
      protectedStore: protectedStore,
      protectedAvailability: protectedAvailability,
    );
    final database = AppDatabase();
    await LegacyScoreMigrator(
      database: database,
      preferences: preferences,
    ).run();
    final sessionCoordinator = UserSessionCoordinator(
      authRepository: authRepository,
      database: database,
      protectedStore: protectedStore,
    );
    await sessionCoordinator.start();

    runApp(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(environment),
          sharedPreferencesProvider.overrideWithValue(preferences),
          protectedStoreProvider.overrideWithValue(protectedStore),
          appDatabaseProvider.overrideWithValue(database),
          userSessionCoordinatorProvider.overrideWithValue(sessionCoordinator),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const JanososApp(),
      ),
    );
  } on Object catch (error, stackTrace) {
    developer.log(
      'Application bootstrap failed',
      name: 'bootstrap',
      error: error,
      stackTrace: stackTrace,
    );
    runApp(_BootstrapFailureApp(message: _safeBootstrapMessage(error)));
  }
}

Future<AuthRepository> _createAuthRepository({
  required AppEnvironment environment,
  required SharedPreferences preferences,
  required ProtectedStore protectedStore,
  required ProtectedStoreAvailability protectedAvailability,
}) async {
  if (environment.usesLocalBackend) {
    return LocalAuthRepository.create(preferences);
  }

  final sessionStorage = protectedAvailability.isAvailable
      ? ProtectedSessionStorage(protectedStore)
      : const EmptyLocalStorage();
  await Supabase.initialize(
    url: environment.supabaseUrl,
    publishableKey: environment.supabasePublishableKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      localStorage: sessionStorage,
      persistSession: protectedAvailability.isAvailable,
      detectSessionInUriPredicate: (uri) {
        final redirect = environment.authRedirectUri;
        return uri.scheme == redirect.scheme &&
            uri.host == redirect.host &&
            uri.path == redirect.path;
      },
    ),
  );
  return SupabaseAuthRepository(
    client: Supabase.instance.client,
    redirectUri: environment.authRedirectUri,
    googleWebClientId: environment.googleWebClientId,
    googleAppleClientId: environment.googleAppleClientId,
  );
}

String _safeBootstrapMessage(Object error) {
  if (error is StateError) {
    return error.message.toString();
  }
  return 'No se pudo iniciar Janosos V6. Revisa la configuración y vuelve a intentarlo.';
}

class _BootstrapFailureApp extends StatelessWidget {
  const _BootstrapFailureApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_outlined, size: 64),
                  const SizedBox(height: 20),
                  const Text(
                    'Configuración incompleta',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
