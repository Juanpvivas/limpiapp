import '../../domain/models/connectivity_status.dart';
import '../../domain/repositories/connectivity_repository.dart';
import '../services/connectivity_service.dart';

/// Implementación de [ConnectivityRepository]: expone el `statusStream` ya
/// combinado y debounced del [ConnectivityService]. El Service degrada
/// cualquier error de la fuente a `offline`, así que aquí no hay nada que
/// mapear a `Failure` (carve-out del Principio V, constitución v2.6.0).
class ConnectivityRepositoryImpl implements ConnectivityRepository {
  ConnectivityRepositoryImpl(this._service);

  final ConnectivityService _service;

  @override
  Stream<ConnectivityStatus> watch() => _service.statusStream;
}
