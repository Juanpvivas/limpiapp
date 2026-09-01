import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../config/service_locator.dart';
import '../../../domain/models/connectivity_status.dart';
import '../../../domain/repositories/connectivity_repository.dart';

part 'connectivity_provider.g.dart';

/// Estado de conectividad para toda la app (feature "Manejo de estado sin
/// conexión"). Lo consumen el `OfflineBanner` (aviso global), las pantallas
/// de lectura (mensaje de error específico) y `NewReportNotifier` (chequeo
/// pre-envío y mensaje).
///
/// `keepAlive`: el estado de red interesa mientras la app viva; evita
/// re-suscribirse a `connectivity_plus`.
///
/// Los consumidores tratan `AsyncLoading`/sin dato como `online` — no mostrar
/// el aviso hasta tener certeza (evita un parpadeo en el arranque).
@Riverpod(keepAlive: true)
Stream<ConnectivityStatus> connectivityStatus(Ref ref) {
  return getIt<ConnectivityRepository>().watch();
}
