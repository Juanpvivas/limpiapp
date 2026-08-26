import 'package:fpdart/fpdart.dart';

import '../models/failure.dart';
import '../models/report_location.dart';

/// Un `Left` (`PermissionFailure`/`LocationFailure`) es la señal de
/// "ubicación automática no disponible" que activa FR-013 en Presentation.
abstract class LocationRepository {
  Future<Either<Failure, ReportLocation>> getCurrentLocation();
}
