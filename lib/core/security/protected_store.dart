class ProtectedStoreAvailability {
  const ProtectedStoreAvailability.available()
    : isAvailable = true,
      reason = null;

  const ProtectedStoreAvailability.unavailable(this.reason)
    : isAvailable = false;

  final bool isAvailable;
  final String? reason;
}

abstract interface class ProtectedStore {
  ProtectedStoreAvailability get availability;

  Future<ProtectedStoreAvailability> initialize();

  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  Future<void> deleteNamespace(String namespace);
}
