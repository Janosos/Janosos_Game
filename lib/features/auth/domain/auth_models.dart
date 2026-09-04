enum AuthProviderId { google, apple }

class AuthUserProfile {
  const AuthUserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.isEmailVerified,
  });

  final String id;
  final String email;
  final String displayName;
  final bool isEmailVerified;
}

enum AuthSessionStatus { signedOut, verificationRequired, authenticated }

class AuthSessionSnapshot {
  const AuthSessionSnapshot._({required this.status, required this.user});

  const AuthSessionSnapshot.signedOut()
    : this._(status: AuthSessionStatus.signedOut, user: null);

  const AuthSessionSnapshot.verificationRequired(AuthUserProfile user)
    : this._(status: AuthSessionStatus.verificationRequired, user: user);

  const AuthSessionSnapshot.authenticated(AuthUserProfile user)
    : this._(status: AuthSessionStatus.authenticated, user: user);

  final AuthSessionStatus status;
  final AuthUserProfile? user;

  bool get isAuthenticated => status == AuthSessionStatus.authenticated;
}

class RegistrationRequest {
  const RegistrationRequest({
    required this.email,
    required this.password,
    required this.displayName,
  });

  final String email;
  final String password;
  final String displayName;
}
