import 'package:dino_run_flame/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local mode permits empty Supabase values', () {
    final environment = AppEnvironment(
      backendMode: BackendMode.local,
      supabaseUrl: '',
      supabasePublishableKey: '',
      authRedirectUri: Uri(
        scheme: 'io.janosos.game',
        host: 'auth',
        path: '/callback',
      ),
      contentVersion: 'v6-preview-1',
    );

    expect(environment.validate, returnsNormally);
  });

  test('Supabase mode requires a valid URL and publishable key', () {
    final environment = AppEnvironment(
      backendMode: BackendMode.supabase,
      supabaseUrl: '',
      supabasePublishableKey: '',
      authRedirectUri: Uri(
        scheme: 'io.janosos.game',
        host: 'auth',
        path: '/callback',
      ),
      contentVersion: 'v6-preview-1',
    );

    expect(environment.validate, throwsStateError);
  });
}
