enum AppFailureCode {
  invalidInput,
  unauthorized,
  conflict,
  configuration,
  network,
  unavailable,
  unknown,
}

class AppFailure implements Exception {
  const AppFailure(this.code, this.message, {this.cause});

  final AppFailureCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
