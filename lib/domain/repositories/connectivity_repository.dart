import '../models/connectivity_status.dart';

/// Flujo de estado de conectividad (feature "Manejo de estado sin conexión").
///
/// Devuelve un `Stream<ConnectivityStatus>` **crudo**, sin `Either<Failure,…>`,
/// al amparo del carve-out del Principio V para *flujos de estado observables*
/// (constitución v2.6.0): un error de la fuente subyacente se degrada a
/// `offline` dentro de la capa Data y nunca cruza como excepción — "no se
/// puede determinar" ya es un estado válido, así que no hay un `Failure` con
/// significado que envolver.
abstract class ConnectivityRepository {
  /// Emite el estado actual al suscribirse y luego en cada cambio, ya
  /// **debounced** (aparecer offline es casi inmediato; volver a online exige
  /// un intervalo de estabilidad) para no parpadear ante fluctuaciones breves.
  Stream<ConnectivityStatus> watch();
}
