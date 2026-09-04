import 'package:dino_run_flame/core/errors/app_failure.dart';
import 'package:dino_run_flame/features/auth/data/local_auth_repository.dart';
import 'package:dino_run_flame/features/auth/domain/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'registers, persists, signs in, changes password, and deletes',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final repository = await LocalAuthRepository.create(preferences);

      await repository.register(
        const RegistrationRequest(
          email: ' PLAYER@Example.com ',
          password: 'first-password',
          displayName: 'Player One',
        ),
      );

      expect(repository.currentSession.isAuthenticated, isTrue);
      expect(repository.currentSession.user?.email, 'player@example.com');
      final persisted = preferences.getString('v6.local_auth.accounts')!;
      expect(persisted, isNot(contains('first-password')));

      await repository.signOut();
      await repository.signIn(
        email: 'player@example.com',
        password: 'first-password',
      );
      await repository.updatePassword('second-password');
      await repository.signOut();

      await expectLater(
        repository.signIn(
          email: 'player@example.com',
          password: 'first-password',
        ),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.code,
            'code',
            AppFailureCode.unauthorized,
          ),
        ),
      );
      await repository.signIn(
        email: 'player@example.com',
        password: 'second-password',
      );
      final userId = repository.currentSession.user!.id;
      final gameStateKey = 'janosos.v6.local_game_state.$userId';
      await preferences.setString(gameStateKey, '{"version":1}');
      await repository.deleteAccount();
      expect(repository.currentSession.user, isNull);
      expect(preferences.containsKey(gameStateKey), isFalse);

      await expectLater(
        repository.signIn(
          email: 'player@example.com',
          password: 'second-password',
        ),
        throwsA(isA<AppFailure>()),
      );
      await repository.dispose();
    },
  );

  test('restores only the active local account session', () async {
    final preferences = await SharedPreferences.getInstance();
    final first = await LocalAuthRepository.create(preferences);
    await first.register(
      const RegistrationRequest(
        email: 'player@example.com',
        password: 'safe-password',
        displayName: 'Player',
      ),
    );
    final userId = first.currentSession.user!.id;
    await first.dispose();

    final restored = await LocalAuthRepository.create(preferences);
    expect(restored.currentSession.user?.id, userId);
    await restored.signOut();
    await restored.dispose();

    final signedOut = await LocalAuthRepository.create(preferences);
    expect(signedOut.currentSession.isAuthenticated, isFalse);
    await signedOut.dispose();
  });

  test('fails closed when local account data is corrupted', () async {
    SharedPreferences.setMockInitialValues({
      'v6.local_auth.accounts': '{not-json',
    });
    final preferences = await SharedPreferences.getInstance();

    await expectLater(
      LocalAuthRepository.create(preferences),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          AppFailureCode.configuration,
        ),
      ),
    );
    expect(preferences.getString('v6.local_auth.accounts'), '{not-json');
  });

  test(
    'provider login returns actionable configuration failure locally',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final repository = await LocalAuthRepository.create(preferences);

      await expectLater(
        repository.signInWithProvider(AuthProviderId.google),
        throwsA(
          isA<AppFailure>()
              .having(
                (failure) => failure.code,
                'code',
                AppFailureCode.configuration,
              )
              .having(
                (failure) => failure.message,
                'message',
                contains('APP_BACKEND=supabase'),
              ),
        ),
      );
      await repository.dispose();
    },
  );
}
