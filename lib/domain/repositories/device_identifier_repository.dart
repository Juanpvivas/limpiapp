import 'package:fpdart/fpdart.dart';

import '../models/failure.dart';

/// Identificador anónimo del dispositivo (FR-002). Persistencia puramente
/// local: nunca requiere red ni Firebase. Separada de
/// `ReportRepository`/`ReportListRepository` para poder reutilizarse desde
/// cualquier feature futura que necesite el mismo identificador.
abstract class DeviceIdentifierRepository {
  /// Genera el identificador la primera vez y lo reutiliza después
  /// (persistido localmente entre sesiones). Un fallo de lectura/escritura
  /// del almacenamiento local se mapea a `CacheFailure`.
  Future<Either<Failure, String>> getDeviceId();
}
