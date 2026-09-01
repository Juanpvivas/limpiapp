import '../../domain/models/connectivity_status.dart';
import '../../domain/models/failure.dart';
import '../reports/providers/reports_failure.dart';
import 'offline_copy.dart';

/// Elige el texto del estado de error de una pantalla de lectura (FR-007):
/// específico de "sin conexión" si el `Failure` es de red o el estado global
/// es `offline`; genérico de servidor en cualquier otro caso. Único para
/// "Mis reportes" y "Mapa de reportes" (FR-019).
String readErrorMessage(Object? error, ConnectivityStatus? connectivity) {
  final failure = error is ReportsFailureException ? error.failure : null;
  final isOffline = connectivity == ConnectivityStatus.offline;
  if (failure is NetworkFailure || isOffline) return kOfflineReadErrorText;
  return kGenericServerErrorText;
}
