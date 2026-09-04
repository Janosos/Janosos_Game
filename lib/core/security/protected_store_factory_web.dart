import 'protected_store.dart';

ProtectedStore createProtectedStore() => WebProtectedStore();

class WebProtectedStore implements ProtectedStore {
  static const _reason =
      'El almacén Web Crypto no está disponible en este origen. Las sesiones '
      'persistentes y el progreso offline elegible permanecen desactivados.';

  @override
  ProtectedStoreAvailability get availability =>
      const ProtectedStoreAvailability.unavailable(_reason);

  @override
  Future<ProtectedStoreAvailability> initialize() async => availability;

  @override
  Future<String?> read(String key) => Future.value();

  @override
  Future<void> write(String key, String value) =>
      Future<void>.error(StateError(_reason));

  @override
  Future<void> delete(String key) async {}

  @override
  Future<void> deleteNamespace(String namespace) async {}
}
