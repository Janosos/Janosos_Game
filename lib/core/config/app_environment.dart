import 'package:flutter/foundation.dart';

enum BackendMode { local, supabase }

class AppEnvironment {
  const AppEnvironment({
    required this.backendMode,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.authRedirectUri,
    required this.contentVersion,
    this.googleWebClientId = '',
    this.googleAppleClientId = '',
  });

  factory AppEnvironment.fromDefines() {
    const backendValue = String.fromEnvironment(
      'APP_BACKEND',
      defaultValue: 'local',
    );
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabasePublishableKey = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    );
    const authRedirectUri = String.fromEnvironment(
      'AUTH_REDIRECT_URI',
      defaultValue: 'io.janosos.game://auth/callback',
    );
    const contentVersion = String.fromEnvironment(
      'CONTENT_VERSION',
      defaultValue: 'v6-preview-1',
    );
    const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    const googleAppleClientId = String.fromEnvironment(
      'GOOGLE_APPLE_CLIENT_ID',
    );

    final backendMode = switch (backendValue.toLowerCase()) {
      'local' => BackendMode.local,
      'supabase' => BackendMode.supabase,
      _ => throw StateError(
        'APP_BACKEND must be either "local" or "supabase".',
      ),
    };

    final environment = AppEnvironment(
      backendMode: backendMode,
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: supabasePublishableKey,
      authRedirectUri: Uri.parse(authRedirectUri),
      contentVersion: contentVersion,
      googleWebClientId: googleWebClientId,
      googleAppleClientId: googleAppleClientId,
    );
    environment.validate();
    return environment;
  }

  final BackendMode backendMode;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final Uri authRedirectUri;
  final String contentVersion;
  final String googleWebClientId;
  final String googleAppleClientId;

  bool get usesLocalBackend => backendMode == BackendMode.local;
  bool get usesSupabase => backendMode == BackendMode.supabase;
  bool get isDebugBuild => kDebugMode;

  void validate() {
    if (contentVersion.trim().isEmpty) {
      throw StateError('CONTENT_VERSION cannot be empty.');
    }
    if (!authRedirectUri.hasScheme) {
      throw StateError('AUTH_REDIRECT_URI must be an absolute URI.');
    }
    if (!usesSupabase) {
      return;
    }
    if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY are required when '
        'APP_BACKEND=supabase.',
      );
    }
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw StateError('SUPABASE_URL must be an absolute URL.');
    }
  }
}
